<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * BorrowingManager Class
     * Handles borrowing management operations including approval, rejection, and returns
     */
    public class BorrowingManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        // Constructor
        public BorrowingManager(HttpServletRequest request, HttpServletResponse response, 
                               HttpSession session, JspWriter out) {
            this.request = request;
            this.response = response;
            this.session = session;
            this.out = out;
        }
        
        /**
         * Validate user authentication and authorization
         */
        public boolean validateAccess() throws Exception {
            Integer userId = (Integer) session.getAttribute("userId");
            String role = (String) session.getAttribute("role");
            
            if (userId == null) {
                response.sendRedirect("login.jsp");
                return false;
            }
            
            if (!"admin".equals(role)) {
                response.sendRedirect("home.jsp");
                return false;
            }
            
            return true;
        }
        
        /**
         * Process approve action
         */
        public void processApprove(int borrowingId) throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            
            try {
                conn = getConnection();
                String sql = "UPDATE borrowings SET status = 'approved' WHERE id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, borrowingId);
                ps.executeUpdate();
            } finally {
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Process reject action
         */
        public void processReject(int borrowingId) throws Exception {
            Connection conn = null;
            PreparedStatement getPs = null;
            PreparedStatement updatePs = null;
            PreparedStatement bookPs = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                
                // Get book_id
                String getSql = "SELECT book_id FROM borrowings WHERE id = ?";
                getPs = conn.prepareStatement(getSql);
                getPs.setInt(1, borrowingId);
                rs = getPs.executeQuery();
                
                if (rs.next()) {
                    int bookId = rs.getInt("book_id");
                    
                    // Update borrowing status
                    String updateSql = "UPDATE borrowings SET status = 'rejected' WHERE id = ?";
                    updatePs = conn.prepareStatement(updateSql);
                    updatePs.setInt(1, borrowingId);
                    updatePs.executeUpdate();
                    
                    // Restore book availability
                    String bookSql = "UPDATE books SET available = available + 1 WHERE id = ?";
                    bookPs = conn.prepareStatement(bookSql);
                    bookPs.setInt(1, bookId);
                    bookPs.executeUpdate();
                }
            } finally {
                if (rs != null) rs.close();
                if (getPs != null) getPs.close();
                if (updatePs != null) updatePs.close();
                if (bookPs != null) bookPs.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Process return action
         */
        public void processReturn(int borrowingId) throws Exception {
            Connection conn = null;
            PreparedStatement getPs = null;
            PreparedStatement updatePs = null;
            PreparedStatement bookPs = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                
                // Get book_id
                String getSql = "SELECT book_id FROM borrowings WHERE id = ?";
                getPs = conn.prepareStatement(getSql);
                getPs.setInt(1, borrowingId);
                rs = getPs.executeQuery();
                
                if (rs.next()) {
                    int bookId = rs.getInt("book_id");
                    
                    // Update borrowing
                    String updateSql = "UPDATE borrowings SET status = 'returned', return_date = CURDATE() WHERE id = ?";
                    updatePs = conn.prepareStatement(updateSql);
                    updatePs.setInt(1, borrowingId);
                    updatePs.executeUpdate();
                    
                    // Restore book availability
                    String bookSql = "UPDATE books SET available = available + 1 WHERE id = ?";
                    bookPs = conn.prepareStatement(bookSql);
                    bookPs.setInt(1, bookId);
                    bookPs.executeUpdate();
                }
            } finally {
                if (rs != null) rs.close();
                if (getPs != null) getPs.close();
                if (updatePs != null) updatePs.close();
                if (bookPs != null) bookPs.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Handle action processing
         */
        public boolean processActions() throws Exception {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                return false;
            }
            
            String action = request.getParameter("action");
            String idParam = request.getParameter("id");
            
            if (action == null || idParam == null) {
                return false;
            }
            
            int borrowingId = Integer.parseInt(idParam);
            
            if ("approve".equals(action)) {
                processApprove(borrowingId);
            } else if ("reject".equals(action)) {
                processReject(borrowingId);
            } else if ("return".equals(action)) {
                processReturn(borrowingId);
            }
            
            response.sendRedirect("borrowings.jsp");
            return true;
        }
        
        /**
         * Get filter status parameter
         */
        public String getFilterStatus() {
            return request.getParameter("status");
        }
        
        /**
         * Build query based on filter
         */
        public String buildQuery(String filterStatus) {
            String sql = "SELECT b.*, u.full_name, u.username, bk.title FROM borrowings b " +
                        "JOIN users u ON b.user_id = u.id " +
                        "JOIN books bk ON b.book_id = bk.id";
            
            if (filterStatus != null && !filterStatus.trim().isEmpty()) {
                sql += " WHERE b.status = ?";
            }
            
            sql += " ORDER BY b.id DESC";
            return sql;
        }
        
        /**
         * Get badge class for status
         */
        public String getBadgeClass(String status) {
            if ("pending".equals(status)) return "bg-warning text-dark";
            if ("approved".equals(status)) return "bg-success";
            if ("returned".equals(status)) return "bg-info";
            if ("rejected".equals(status)) return "bg-danger";
            return "bg-secondary";
        }
        
        /**
         * Render borrowing rows
         */
        public void renderBorrowingRows(Connection conn, String filterStatus) throws Exception {
            String sql = buildQuery(filterStatus);
            PreparedStatement ps = conn.prepareStatement(sql);
            
            if (filterStatus != null && !filterStatus.trim().isEmpty()) {
                ps.setString(1, filterStatus);
            }
            
            ResultSet rs = ps.executeQuery();
            boolean hasData = false;
            
            while (rs.next()) {
                hasData = true;
                renderBorrowingRow(rs);
            }
            
            if (!hasData) {
                out.println("<tr><td colspan='8' class='text-center'>No borrowings found</td></tr>");
            }
            
            rs.close();
            ps.close();
        }
        
        /**
         * Render single borrowing row
         */
        private void renderBorrowingRow(ResultSet rs) throws Exception {
            int id = rs.getInt("id");
            String fullName = rs.getString("full_name");
            String username = rs.getString("username");
            String title = rs.getString("title");
            String borrowDate = rs.getDate("borrow_date").toString();
            String dueDate = rs.getDate("due_date").toString();
            java.sql.Date returnDateObj = rs.getDate("return_date");
            String returnDate = returnDateObj != null ? returnDateObj.toString() : "-";
            String status = rs.getString("status");
            String badgeClass = getBadgeClass(status);
            
            out.println("<tr>");
            out.println("    <td>" + id + "</td>");
            out.println("    <td><strong>" + fullName + "</strong><br><small class='text-muted'>" + username + "</small></td>");
            out.println("    <td>" + title + "</td>");
            out.println("    <td>" + borrowDate + "</td>");
            out.println("    <td>" + dueDate + "</td>");
            out.println("    <td>" + returnDate + "</td>");
            out.println("    <td><span class='badge " + badgeClass + "'>" + status.toUpperCase() + "</span></td>");
            out.println("    <td>");
            
            if ("pending".equals(status)) {
                out.println("        <form method='post' class='d-inline'>");
                out.println("            <input type='hidden' name='id' value='" + id + "'>");
                out.println("            <input type='hidden' name='action' value='approve'>");
                out.println("            <button type='submit' class='btn btn-sm btn-success'>Approve</button>");
                out.println("        </form>");
                out.println("        <form method='post' class='d-inline'>");
                out.println("            <input type='hidden' name='id' value='" + id + "'>");
                out.println("            <input type='hidden' name='action' value='reject'>");
                out.println("            <button type='submit' class='btn btn-sm btn-danger'>Reject</button>");
                out.println("        </form>");
            } else if ("approved".equals(status)) {
                out.println("        <form method='post' class='d-inline'>");
                out.println("            <input type='hidden' name='id' value='" + id + "'>");
                out.println("            <input type='hidden' name='action' value='return'>");
                out.println("            <button type='submit' class='btn btn-sm btn-info'>Mark Returned</button>");
                out.println("        </form>");
            } else {
                out.println("        <span class='text-muted'>-</span>");
            }
            
            out.println("    </td>");
            out.println("</tr>");
        }
    }
%>

<%
    // Initialize BorrowingManager
    BorrowingManager borrowingManager = new BorrowingManager(request, response, session, out);
    
    // Validate access
    if (!borrowingManager.validateAccess()) {
        return;
    }
    
    // Process actions
    if (borrowingManager.processActions()) {
        return;
    }
    
    String filterStatus = borrowingManager.getFilterStatus();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Manage Borrowings</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="books.jsp">Manage Books</a></li>
            <li class="nav-item"><a class="nav-link active" href="borrowings.jsp">Manage Borrowings</a></li>
          </ul>
          <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <h3 class="mb-4">📋 Borrowing Management</h3>
        
        <div class="card mb-4">
            <div class="card-body">
                <form method="get" class="row g-3">
                    <div class="col-md-10">
                        <select class="form-select" name="status">
                            <option value="">All Status</option>
                            <option value="pending" <%= "pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
                            <option value="approved" <%= "approved".equals(filterStatus) ? "selected" : "" %>>Approved</option>
                            <option value="returned" <%= "returned".equals(filterStatus) ? "selected" : "" %>>Returned</option>
                            <option value="rejected" <%= "rejected".equals(filterStatus) ? "selected" : "" %>>Rejected</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-primary w-100">Filter</button>
                    </div>
                </form>
            </div>
        </div>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>ID</th>
                        <th>User</th>
                        <th>Book</th>
                        <th>Borrow Date</th>
                        <th>Due Date</th>
                        <th>Return Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try {
                    Connection conn = getConnection();
                    borrowingManager.renderBorrowingRows(conn, filterStatus);
                    conn.close();
                } catch (Exception e) {
                    out.println("<tr><td colspan='8' class='text-danger'>Error: " + e.getMessage() + "</td></tr>");
                    e.printStackTrace();
                }
                %>
                </tbody>
            </table>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
