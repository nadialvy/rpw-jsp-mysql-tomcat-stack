<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * BookDeleteManager Class
     * Handles book deletion operations including validation and database removal
     */
    public class BookDeleteManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        private int bookId;
        private String bookTitle = "";
        
        // Constructor
        public BookDeleteManager(HttpServletRequest request, HttpServletResponse response, 
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
         * Validate and get book ID from parameter
         */
        public boolean validateBookId() throws Exception {
            String idParam = request.getParameter("id");
            if (idParam == null || idParam.isEmpty()) {
                response.sendRedirect("books.jsp");
                return false;
            }
            
            try {
                this.bookId = Integer.parseInt(idParam);
                return true;
            } catch (NumberFormatException e) {
                response.sendRedirect("books.jsp");
                return false;
            }
        }
        
        /**
         * Check if book has active borrowings
         */
        public int checkActiveBorrowings() throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE book_id = ? AND status IN ('pending', 'approved')";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, bookId);
                rs = ps.executeQuery();
                rs.next();
                int count = rs.getInt("cnt");
                return count;
            } finally {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Delete book from database
         */
        public boolean deleteBook() throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            
            try {
                conn = getConnection();
                String sql = "DELETE FROM books WHERE id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, bookId);
                ps.executeUpdate();
                return true;
            } catch (Exception e) {
                e.printStackTrace();
                return false;
            } finally {
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Process deletion
         */
        public boolean processDeletion() throws Exception {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                return false;
            }
            
            int activeBorrowings = checkActiveBorrowings();
            
            if (activeBorrowings > 0) {
                response.sendRedirect("books.jsp?message=Cannot delete book with active borrowings!");
                return true;
            }
            
            if (deleteBook()) {
                response.sendRedirect("books.jsp?message=Book deleted successfully!");
                return true;
            } else {
                response.sendRedirect("books.jsp?message=Error deleting book");
                return true;
            }
        }
        
        /**
         * Load book title for confirmation
         */
        public boolean loadBookTitle() throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                String sql = "SELECT title FROM books WHERE id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, bookId);
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    this.bookTitle = rs.getString("title");
                    return true;
                } else {
                    response.sendRedirect("books.jsp");
                    return false;
                }
            } catch (Exception e) {
                e.printStackTrace();
                return false;
            } finally {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        // Getters
        public String getBookTitle() {
            return bookTitle;
        }
    }
%>

<%
    // Initialize BookDeleteManager
    BookDeleteManager bookDeleteManager = new BookDeleteManager(request, response, session, out);
    
    // Validate access
    if (!bookDeleteManager.validateAccess()) {
        return;
    }
    
    // Validate book ID
    if (!bookDeleteManager.validateBookId()) {
        return;
    }
    
    // Process deletion if POST request
    if (bookDeleteManager.processDeletion()) {
        return;
    }
    
    // Load book title for confirmation
    if (!bookDeleteManager.loadBookTitle()) {
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Delete Book</title>
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
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="card border-danger">
                    <div class="card-header bg-danger text-white">
                        <h4 class="mb-0">🗑️ Delete Book</h4>
                    </div>
                    <div class="card-body">
                        <div class="alert alert-warning">
                            <strong>Warning!</strong> This action cannot be undone.
                        </div>
                        
                        <p>Are you sure you want to delete this book?</p>
                        <p><strong>"<%= bookDeleteManager.getBookTitle() %>"</strong></p>
                        
                        <form method="post" class="d-flex gap-2">
                            <button type="submit" class="btn btn-danger">Yes, Delete</button>
                            <a href="books.jsp" class="btn btn-secondary">Cancel</a>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
