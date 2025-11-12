<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * MyBorrowingsManager Class
     * Handles customer's borrowing history display and statistics
     */
    public class MyBorrowingsManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        private Integer userId;
        
        // Constructor
        public MyBorrowingsManager(HttpServletRequest request, HttpServletResponse response, 
                                  HttpSession session, JspWriter out) {
            this.request = request;
            this.response = response;
            this.session = session;
            this.out = out;
            this.userId = (Integer) session.getAttribute("userId");
        }
        
        /**
         * Validate user authentication
         */
        public boolean validateAccess() throws Exception {
            if (userId == null) {
                response.sendRedirect("login.jsp");
                return false;
            }
            return true;
        }
        
        /**
         * Get count by status
         */
        public int getCountByStatus(String status) throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE user_id = ? AND status = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, userId);
                ps.setString(2, status);
                rs = ps.executeQuery();
                rs.next();
                return rs.getInt("cnt");
            } finally {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Render status card
         */
        public void renderStatusCard(String status, String bgColor) throws Exception {
            int count = getCountByStatus(status);
            out.println("<div class='col-md-3'>");
            out.println("    <div class='card text-white " + bgColor + "'>");
            out.println("        <div class='card-body text-center'>");
            out.println("            <h5>" + capitalize(status) + "</h5>");
            out.println("            <h2>" + count + "</h2>");
            out.println("        </div>");
            out.println("    </div>");
            out.println("</div>");
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
         * Check if borrowing is overdue
         */
        public boolean isOverdue(java.sql.Date dueDate, java.sql.Date returnDate, String status) {
            if (!"approved".equals(status)) return false;
            if (returnDate != null) return false;
            java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
            return dueDate.before(today);
        }
        
        /**
         * Render borrowing table rows
         */
        public void renderBorrowingRows(Connection conn) throws Exception {
            String sql = "SELECT b.*, bk.title, bk.author FROM borrowings b " +
                        "JOIN books bk ON b.book_id = bk.id " +
                        "WHERE b.user_id = ? ORDER BY b.id DESC";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            
            boolean hasData = false;
            while (rs.next()) {
                hasData = true;
                renderBorrowingRow(rs);
            }
            
            if (!hasData) {
                out.println("<tr><td colspan='6' class='text-center'>No borrowing history</td></tr>");
            }
            
            rs.close();
            ps.close();
        }
        
        /**
         * Render single borrowing row
         */
        private void renderBorrowingRow(ResultSet rs) throws Exception {
            String title = rs.getString("title");
            String author = rs.getString("author");
            java.sql.Date borrowDate = rs.getDate("borrow_date");
            java.sql.Date dueDate = rs.getDate("due_date");
            java.sql.Date returnDate = rs.getDate("return_date");
            String status = rs.getString("status");
            
            boolean overdue = isOverdue(dueDate, returnDate, status);
            String badgeClass = getBadgeClass(status);
            String rowClass = overdue ? "table-danger" : "";
            
            out.println("<tr class='" + rowClass + "'>");
            out.println("    <td><strong>" + title + "</strong></td>");
            out.println("    <td>" + author + "</td>");
            out.println("    <td>" + borrowDate + "</td>");
            out.println("    <td>");
            out.println("        " + dueDate);
            if (overdue) {
                out.println("        <span class='badge bg-danger'>OVERDUE</span>");
            }
            out.println("    </td>");
            out.println("    <td>" + (returnDate != null ? returnDate.toString() : "-") + "</td>");
            out.println("    <td><span class='badge " + badgeClass + "'>" + status.toUpperCase() + "</span></td>");
            out.println("</tr>");
        }
        
        /**
         * Capitalize first letter
         */
        private String capitalize(String str) {
            if (str == null || str.isEmpty()) return str;
            return str.substring(0, 1).toUpperCase() + str.substring(1);
        }
    }
%>

<%
    // Initialize MyBorrowingsManager
    MyBorrowingsManager myBorrowingsManager = new MyBorrowingsManager(request, response, session, out);
    
    // Validate access
    if (!myBorrowingsManager.validateAccess()) {
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>My Borrowings</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="customer_books.jsp">Browse Books</a></li>
            <li class="nav-item"><a class="nav-link active" href="my_borrowings.jsp">My Borrowings</a></li>
          </ul>
          <div class="d-flex align-items-center text-white">
            <span class="me-3"><%= session.getAttribute("fullName") %></span>
            <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
          </div>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <h3 class="mb-4">📋 My Borrowing History</h3>
        
        <div class="row mb-4">
            <%
            try {
                myBorrowingsManager.renderStatusCard("pending", "bg-warning");
                myBorrowingsManager.renderStatusCard("approved", "bg-success");
                myBorrowingsManager.renderStatusCard("returned", "bg-info");
                myBorrowingsManager.renderStatusCard("rejected", "bg-danger");
            } catch (Exception e) {
                e.printStackTrace();
            }
            %>
        </div>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>Book Title</th>
                        <th>Author</th>
                        <th>Borrow Date</th>
                        <th>Due Date</th>
                        <th>Return Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try {
                    Connection conn = getConnection();
                    myBorrowingsManager.renderBorrowingRows(conn);
                    conn.close();
                } catch (Exception e) {
                    out.println("<tr><td colspan='6' class='text-danger'>Error: " + e.getMessage() + "</td></tr>");
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
