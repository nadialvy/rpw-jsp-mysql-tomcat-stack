<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * BookManager Class
     * Handles all book management operations including search, display, and data retrieval
     */
    public class BookManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        // Constructor
        public BookManager(HttpServletRequest request, HttpServletResponse response, 
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
         * Get search parameter from request
         */
        public String getSearchParameter() {
            String search = request.getParameter("search");
            return search != null ? search.trim() : "";
        }
        
        /**
         * Get message parameter from request
         */
        public String getMessageParameter() {
            return request.getParameter("message");
        }
        
        /**
         * Build SQL query based on search parameter
         */
        public String buildQuery(String search) {
            String sql = "SELECT * FROM books";
            if (search != null && !search.isEmpty()) {
                sql += " WHERE title LIKE ? OR author LIKE ? OR isbn LIKE ? OR category LIKE ?";
            }
            sql += " ORDER BY id DESC";
            return sql;
        }
        
        /**
         * Set search parameters to PreparedStatement
         */
        public void setSearchParameters(PreparedStatement ps, String search) throws SQLException {
            if (search != null && !search.isEmpty()) {
                String searchPattern = "%" + search + "%";
                ps.setString(1, searchPattern);
                ps.setString(2, searchPattern);
                ps.setString(3, searchPattern);
                ps.setString(4, searchPattern);
            }
        }
        
        /**
         * Render book table rows
         */
        public void renderBookRows(Connection conn, String search) throws Exception {
            String sql = buildQuery(search);
            PreparedStatement ps = conn.prepareStatement(sql);
            setSearchParameters(ps, search);
            
            ResultSet rs = ps.executeQuery();
            boolean hasData = false;
            
            while (rs.next()) {
                hasData = true;
                renderBookRow(rs);
            }
            
            if (!hasData) {
                out.println("<tr><td colspan='8' class='text-center'>No books found</td></tr>");
            }
            
            rs.close();
            ps.close();
        }
        
        /**
         * Render single book row
         */
        private void renderBookRow(ResultSet rs) throws Exception {
            int id = rs.getInt("id");
            String title = rs.getString("title");
            String author = rs.getString("author");
            String isbn = rs.getString("isbn");
            String category = rs.getString("category");
            int quantity = rs.getInt("quantity");
            int available = rs.getInt("available");
            
            out.println("<tr>");
            out.println("    <td>" + id + "</td>");
            out.println("    <td><strong>" + title + "</strong></td>");
            out.println("    <td>" + author + "</td>");
            out.println("    <td>" + (isbn != null ? isbn : "-") + "</td>");
            out.println("    <td><span class='badge bg-info'>" + category + "</span></td>");
            out.println("    <td>" + quantity + "</td>");
            out.println("    <td><span class='badge " + (available > 0 ? "bg-success" : "bg-danger") + "'>" + available + "</span></td>");
            out.println("    <td>");
            out.println("        <a href='book_edit.jsp?id=" + id + "' class='btn btn-sm btn-warning'>Edit</a>");
            out.println("        <a href='book_delete.jsp?id=" + id + "' class='btn btn-sm btn-danger' onclick='return confirm(\"Delete this book?\")'>Delete</a>");
            out.println("    </td>");
            out.println("</tr>");
        }
    }
%>

<%
    // Initialize BookManager
    BookManager bookManager = new BookManager(request, response, session, out);
    
    // Validate access - if false, return immediately
    if (!bookManager.validateAccess()) {
        return;
    }
    
    // Get parameters
    String search = bookManager.getSearchParameter();
    String message = bookManager.getMessageParameter();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Manage Books</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link active" href="books.jsp">Manage Books</a></li>
            <li class="nav-item"><a class="nav-link" href="borrowings.jsp">Manage Borrowings</a></li>
          </ul>
          <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h3>📚 Book Management</h3>
            <a href="book_add.jsp" class="btn btn-primary">+ Add New Book</a>
        </div>
        
        <%
        if (message != null && !message.isEmpty()) {
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
                    <div class="col-md-10">
                        <input type="text" class="form-control" name="search" 
                               placeholder="Search by title, author, ISBN..." 
                               value="<%= search != null ? search : "" %>">
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-primary w-100">Search</button>
                    </div>
                </form>
            </div>
        </div>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>ID</th>
                        <th>Title</th>
                        <th>Author</th>
                        <th>ISBN</th>
                        <th>Category</th>
                        <th>Quantity</th>
                        <th>Available</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try {
                    Connection conn = getConnection();
                    bookManager.renderBookRows(conn, search);
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