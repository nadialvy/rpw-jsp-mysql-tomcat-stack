<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * CustomerBooksManager Class
     * Handles book browsing and borrowing operations for customers
     */
    public class CustomerBooksManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        private Integer userId;
        
        // Constructor
        public CustomerBooksManager(HttpServletRequest request, HttpServletResponse response, 
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
         * Process borrow action
         */
        public boolean processBorrow() throws Exception {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                return false;
            }
            
            String action = request.getParameter("action");
            String bookIdParam = request.getParameter("bookId");
            
            if (!"borrow".equals(action) || bookIdParam == null) {
                return false;
            }
            
            int bookId = Integer.parseInt(bookIdParam);
            Connection conn = null;
            PreparedStatement checkPs = null;
            PreparedStatement insertPs = null;
            PreparedStatement updatePs = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                
                // Check if book is available
                String checkSql = "SELECT available FROM books WHERE id = ?";
                checkPs = conn.prepareStatement(checkSql);
                checkPs.setInt(1, bookId);
                rs = checkPs.executeQuery();
                
                if (rs.next() && rs.getInt("available") > 0) {
                    // Create borrowing request
                    String insertSql = "INSERT INTO borrowings (user_id, book_id, borrow_date, due_date, status) " +
                                      "VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'pending')";
                    insertPs = conn.prepareStatement(insertSql);
                    insertPs.setInt(1, userId);
                    insertPs.setInt(2, bookId);
                    insertPs.executeUpdate();
                    
                    // Decrease available count
                    String updateSql = "UPDATE books SET available = available - 1 WHERE id = ?";
                    updatePs = conn.prepareStatement(updateSql);
                    updatePs.setInt(1, bookId);
                    updatePs.executeUpdate();
                }
            } finally {
                if (rs != null) rs.close();
                if (checkPs != null) checkPs.close();
                if (insertPs != null) insertPs.close();
                if (updatePs != null) updatePs.close();
                if (conn != null) conn.close();
            }
            
            response.sendRedirect("customer_books.jsp?message=Borrowing request submitted!");
            return true;
        }
        
        /**
         * Get search parameter
         */
        public String getSearchParam() {
            String search = request.getParameter("search");
            return search != null ? search : "";
        }
        
        /**
         * Get category parameter
         */
        public String getCategoryParam() {
            return request.getParameter("category");
        }
        
        /**
         * Get message parameter
         */
        public String getMessageParam() {
            return request.getParameter("message");
        }
        
        /**
         * Build SQL query
         */
        public String buildQuery(String search, String category) {
            String sql = "SELECT * FROM books WHERE 1=1";
            if (search != null && !search.trim().isEmpty()) {
                sql += " AND (title LIKE ? OR author LIKE ?)";
            }
            if (category != null && !category.trim().isEmpty()) {
                sql += " AND category = ?";
            }
            sql += " ORDER BY title";
            return sql;
        }
        
        /**
         * Set query parameters
         */
        public void setQueryParameters(PreparedStatement ps, String search, String category) throws SQLException {
            int paramIndex = 1;
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search + "%";
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
            }
            if (category != null && !category.trim().isEmpty()) {
                ps.setString(paramIndex++, category);
            }
        }
        
        /**
         * Render book cards
         */
        public void renderBookCards(Connection conn, String search, String category) throws Exception {
            String sql = buildQuery(search, category);
            PreparedStatement ps = conn.prepareStatement(sql);
            setQueryParameters(ps, search, category);
            
            ResultSet rs = ps.executeQuery();
            boolean hasData = false;
            
            while (rs.next()) {
                hasData = true;
                renderBookCard(rs);
            }
            
            if (!hasData) {
                out.println("<div class='col-12'><div class='alert alert-info'>No books found</div></div>");
            }
            
            rs.close();
            ps.close();
        }
        
        /**
         * Render single book card
         */
        private void renderBookCard(ResultSet rs) throws Exception {
            int id = rs.getInt("id");
            String title = rs.getString("title");
            String author = rs.getString("author");
            String isbn = rs.getString("isbn");
            String category = rs.getString("category");
            String description = rs.getString("description");
            int available = rs.getInt("available");
            
            out.println("<div class='col-md-4 mb-4'>");
            out.println("    <div class='card h-100'>");
            out.println("        <div class='card-body'>");
            out.println("            <h5 class='card-title'>" + title + "</h5>");
            out.println("            <h6 class='card-subtitle mb-2 text-muted'>" + author + "</h6>");
            out.println("            <p class='card-text'>");
            out.println("                <span class='badge bg-info'>" + category + "</span>");
            if (isbn != null) {
                out.println("                <br><small class='text-muted'>ISBN: " + isbn + "</small>");
            }
            out.println("            </p>");
            if (description != null) {
                out.println("            <p class='card-text'><small>" + description + "</small></p>");
            }
            out.println("            <div class='d-flex justify-content-between align-items-center'>");
            out.println("                <span class='" + (available > 0 ? "text-success" : "text-danger") + "'>");
            out.println("                    <strong>" + available + " available</strong>");
            out.println("                </span>");
            if (available > 0) {
                out.println("                <form method='post' class='d-inline'>");
                out.println("                    <input type='hidden' name='action' value='borrow'>");
                out.println("                    <input type='hidden' name='bookId' value='" + id + "'>");
                out.println("                    <button type='submit' class='btn btn-sm btn-primary' onclick='return confirm(\"Borrow this book?\")'>Borrow</button>");
                out.println("                </form>");
            } else {
                out.println("                <button class='btn btn-sm btn-secondary' disabled>Not Available</button>");
            }
            out.println("            </div>");
            out.println("        </div>");
            out.println("    </div>");
            out.println("</div>");
        }
    }
%>

<%
    // Initialize CustomerBooksManager
    CustomerBooksManager customerBooksManager = new CustomerBooksManager(request, response, session, out);
    
    // Validate access
    if (!customerBooksManager.validateAccess()) {
        return;
    }
    
    // Process borrow action
    if (customerBooksManager.processBorrow()) {
        return;
    }
    
    String search = customerBooksManager.getSearchParam();
    String category = customerBooksManager.getCategoryParam();
    String message = customerBooksManager.getMessageParam();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Browse Books</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link active" href="customer_books.jsp">Browse Books</a></li>
            <li class="nav-item"><a class="nav-link" href="my_borrowings.jsp">My Borrowings</a></li>
          </ul>
          <div class="d-flex align-items-center text-white">
            <span class="me-3"><%= session.getAttribute("fullName") %></span>
            <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
          </div>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <h3 class="mb-4">📚 Browse Available Books</h3>
        
        <%
        if (message != null) {
        %>
        <div class="alert alert-success alert-dismissible fade show">
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <%
        }
        %>
        
        <div class="card mb-4">
            <div class="card-body">
                <form method="get" class="row g-3">
                    <div class="col-md-6">
                        <input type="text" class="form-control" name="search" 
                               placeholder="Search by title or author..." 
                               value="<%= search != null ? search : "" %>">
                    </div>
                    <div class="col-md-4">
                        <select class="form-select" name="category">
                            <option value="">All Categories</option>
                            <option value="Programming" <%= "Programming".equals(category) ? "selected" : "" %>>Programming</option>
                            <option value="Computer Science" <%= "Computer Science".equals(category) ? "selected" : "" %>>Computer Science</option>
                            <option value="Fiction" <%= "Fiction".equals(category) ? "selected" : "" %>>Fiction</option>
                            <option value="Non-Fiction" <%= "Non-Fiction".equals(category) ? "selected" : "" %>>Non-Fiction</option>
                            <option value="Science" <%= "Science".equals(category) ? "selected" : "" %>>Science</option>
                            <option value="History" <%= "History".equals(category) ? "selected" : "" %>>History</option>
                            <option value="Biography" <%= "Biography".equals(category) ? "selected" : "" %>>Biography</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-primary w-100">Search</button>
                    </div>
                </form>
            </div>
        </div>
        
        <div class="row">
        <%
        try {
            Connection conn = getConnection();
            customerBooksManager.renderBookCards(conn, search, category);
            conn.close();
        } catch (Exception e) {
            out.println("<div class='col-12'><div class='alert alert-danger'>Error: " + e.getMessage() + "</div></div>");
            e.printStackTrace();
        }
        %>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
