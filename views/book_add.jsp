<%@ include file="../classes/auth.jsp" %>
<% 
Integer userId = (Integer) session.getAttribute("userId");
String role = (String) session.getAttribute("role");

if (userId == null) { 
  response.sendRedirect("login.jsp"); 
  return; 
}

if (!"admin".equals(role)) {
  response.sendRedirect("home.jsp");
  return;
}

String error = null;
String success = null;

if ("POST".equalsIgnoreCase(request.getMethod())) {
    String title = request.getParameter("title");
    String author = request.getParameter("author");
    String isbn = request.getParameter("isbn");
    String category = request.getParameter("category");
    String quantityStr = request.getParameter("quantity");
    String description = request.getParameter("description");
    
    if (title == null || title.trim().isEmpty() || 
        author == null || author.trim().isEmpty() ||
        quantityStr == null || quantityStr.trim().isEmpty()) {
        error = "Title, Author, and Quantity are required!";
    } else {
        try {
            int quantity = Integer.parseInt(quantityStr);
            if (quantity < 1) {
                error = "Quantity must be at least 1";
            } else {
                try (Connection conn = getConnection()) {
                    String sql = "INSERT INTO books (title, author, isbn, category, quantity, available, description) VALUES (?, ?, ?, ?, ?, ?, ?)";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setString(1, title);
                    ps.setString(2, author);
                    ps.setString(3, isbn);
                    ps.setString(4, category);
                    ps.setInt(5, quantity);
                    ps.setInt(6, quantity);
                    ps.setString(7, description);
                    ps.executeUpdate();
                    ps.close();
                    response.sendRedirect("books.jsp?message=Book added successfully!");
                    return;
                } catch (Exception e) {
                    error = "Database error: " + e.getMessage();
                    e.printStackTrace();
                }
            }
        } catch (NumberFormatException e) {
            error = "Invalid quantity number";
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Add Book</title>
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
                    <div class="card-header bg-primary text-white">
                        <h4 class="mb-0">➕ Add New Book</h4>
                    </div>
                    <div class="card-body">
                        <% if (error != null) { %>
                        <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        
                        <form method="post">
                            <div class="mb-3">
                                <label class="form-label">Title *</label>
                                <input type="text" class="form-control" name="title" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Author *</label>
                                <input type="text" class="form-control" name="author" required>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">ISBN</label>
                                    <input type="text" class="form-control" name="isbn">
                                </div>
                                
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">Category</label>
                                    <select class="form-select" name="category">
                                        <option value="Programming">Programming</option>
                                        <option value="Computer Science">Computer Science</option>
                                        <option value="Fiction">Fiction</option>
                                        <option value="Non-Fiction">Non-Fiction</option>
                                        <option value="Science">Science</option>
                                        <option value="History">History</option>
                                        <option value="Biography">Biography</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Quantity *</label>
                                <input type="number" class="form-control" name="quantity" min="1" value="1" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Description</label>
                                <textarea class="form-control" name="description" rows="3"></textarea>
                            </div>
                            
                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-primary">Save Book</button>
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
