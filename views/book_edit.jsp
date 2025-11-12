<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * BookEditManager Class
     * Handles book editing operations including data loading, validation, and updates
     */
    public class BookEditManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        private String errorMessage;
        private int bookId;
        
        // Book data fields
        private String title = "";
        private String author = "";
        private String isbn = "";
        private String category = "";
        private String description = "";
        private int quantity = 1;
        private int available = 1;
        
        // Constructor
        public BookEditManager(HttpServletRequest request, HttpServletResponse response, 
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
         * Load book data from database
         */
        public boolean loadBookData() throws Exception {
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            
            try {
                conn = getConnection();
                String sql = "SELECT * FROM books WHERE id = ?";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, bookId);
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    this.title = rs.getString("title");
                    this.author = rs.getString("author");
                    this.isbn = rs.getString("isbn");
                    this.category = rs.getString("category");
                    this.quantity = rs.getInt("quantity");
                    this.available = rs.getInt("available");
                    this.description = rs.getString("description");
                    return true;
                } else {
                    response.sendRedirect("books.jsp");
                    return false;
                }
            } catch (Exception e) {
                errorMessage = "Error loading book: " + e.getMessage();
                e.printStackTrace();
                return false;
            } finally {
                if (rs != null) rs.close();
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Validate form input
         */
        public boolean validateInput(String title, String author, String quantityStr) {
            if (title == null || title.trim().isEmpty()) {
                errorMessage = "Title is required!";
                return false;
            }
            
            if (author == null || author.trim().isEmpty()) {
                errorMessage = "Author is required!";
                return false;
            }
            
            if (quantityStr == null || quantityStr.trim().isEmpty()) {
                errorMessage = "Quantity is required!";
                return false;
            }
            
            return true;
        }
        
        /**
         * Update book in database
         */
        public boolean updateBook(String newTitle, String newAuthor, String newIsbn, 
                                  String newCategory, int newQuantity, String newDescription) throws Exception {
            // Calculate new available count
            int borrowed = quantity - available;
            int newAvailable = newQuantity - borrowed;
            
            if (newAvailable < 0) {
                errorMessage = "Quantity cannot be less than borrowed books (" + borrowed + ")";
                return false;
            }
            
            Connection conn = null;
            PreparedStatement ps = null;
            
            try {
                conn = getConnection();
                String sql = "UPDATE books SET title=?, author=?, isbn=?, category=?, " +
                           "quantity=?, available=?, description=? WHERE id=?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, newTitle);
                ps.setString(2, newAuthor);
                ps.setString(3, newIsbn);
                ps.setString(4, newCategory);
                ps.setInt(5, newQuantity);
                ps.setInt(6, newAvailable);
                ps.setString(7, newDescription);
                ps.setInt(8, bookId);
                ps.executeUpdate();
                return true;
            } catch (Exception e) {
                errorMessage = "Database error: " + e.getMessage();
                e.printStackTrace();
                return false;
            } finally {
                if (ps != null) ps.close();
                if (conn != null) conn.close();
            }
        }
        
        /**
         * Process form submission
         */
        public boolean processForm() throws Exception {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                return false;
            }
            
            String newTitle = request.getParameter("title");
            String newAuthor = request.getParameter("author");
            String newIsbn = request.getParameter("isbn");
            String newCategory = request.getParameter("category");
            String quantityStr = request.getParameter("quantity");
            String newDescription = request.getParameter("description");
            
            if (!validateInput(newTitle, newAuthor, quantityStr)) {
                return false;
            }
            
            try {
                int newQuantity = Integer.parseInt(quantityStr);
                
                if (newQuantity < 1) {
                    errorMessage = "Quantity must be at least 1";
                    return false;
                }
                
                if (updateBook(newTitle, newAuthor, newIsbn, newCategory, newQuantity, newDescription)) {
                    response.sendRedirect("books.jsp?message=Book updated successfully!");
                    return true;
                }
            } catch (NumberFormatException e) {
                errorMessage = "Invalid quantity number";
            }
            
            return false;
        }
        
        // Getters
        public String getErrorMessage() { return errorMessage; }
        public int getBookId() { return bookId; }
        public String getTitle() { return title; }
        public String getAuthor() { return author; }
        public String getIsbn() { return isbn; }
        public String getCategory() { return category; }
        public String getDescription() { return description; }
        public int getQuantity() { return quantity; }
        public int getAvailable() { return available; }
        public int getBorrowed() { return quantity - available; }
    }
%>

<%
    // Initialize BookEditManager
    BookEditManager bookEditManager = new BookEditManager(request, response, session, out);
    
    // Validate access
    if (!bookEditManager.validateAccess()) {
        return;
    }
    
    // Validate book ID
    if (!bookEditManager.validateBookId()) {
        return;
    }
    
    // Load book data
    if (!bookEditManager.loadBookData()) {
        return;
    }
    
    // Process form if submitted
    if (bookEditManager.processForm()) {
        return;
    }
    
    String error = bookEditManager.getErrorMessage();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Edit Book</title>
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
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header bg-warning">
                        <h4 class="mb-0">✏️ Edit Book</h4>
                    </div>
                    <div class="card-body">
                        <%
                        if (error != null) {
                        %>
                        <div class="alert alert-danger"><%= error %></div>
                        <%
                        }
                        %>
                        
                        <form method="post">
                            <div class="mb-3">
                                <label class="form-label">Title *</label>
                                <input type="text" class="form-control" name="title" value="<%= bookEditManager.getTitle() %>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Author *</label>
                                <input type="text" class="form-control" name="author" value="<%= bookEditManager.getAuthor() %>" required>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">ISBN</label>
                                    <input type="text" class="form-control" name="isbn" value="<%= bookEditManager.getIsbn() != null ? bookEditManager.getIsbn() : "" %>">
                                </div>
                                
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">Category</label>
                                    <select class="form-select" name="category">
                                        <option value="Programming" <%= "Programming".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Programming</option>
                                        <option value="Computer Science" <%= "Computer Science".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Computer Science</option>
                                        <option value="Fiction" <%= "Fiction".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Fiction</option>
                                        <option value="Non-Fiction" <%= "Non-Fiction".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Non-Fiction</option>
                                        <option value="Science" <%= "Science".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Science</option>
                                        <option value="History" <%= "History".equals(bookEditManager.getCategory()) ? "selected" : "" %>>History</option>
                                        <option value="Biography" <%= "Biography".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Biography</option>
                                        <option value="Other" <%= "Other".equals(bookEditManager.getCategory()) ? "selected" : "" %>>Other</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Quantity *</label>
                                <input type="number" class="form-control" name="quantity" min="<%= bookEditManager.getBorrowed() %>" value="<%= bookEditManager.getQuantity() %>" required>
                                <small class="text-muted">Currently borrowed: <%= bookEditManager.getBorrowed() %>, Available: <%= bookEditManager.getAvailable() %></small>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Description</label>
                                <textarea class="form-control" name="description" rows="3"><%= bookEditManager.getDescription() != null ? bookEditManager.getDescription() : "" %></textarea>
                            </div>
                            
                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-warning">Update Book</button>
                                <a href="books.jsp" class="btn btn-secondary">Cancel</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
