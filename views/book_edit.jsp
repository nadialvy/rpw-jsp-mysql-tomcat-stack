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

String idParam = request.getParameter("id");
if (idParam == null) {
    response.sendRedirect("books.jsp");
    return;
}

int bookId = Integer.parseInt(idParam);
String error = null;

// Get book data
String title = "", author = "", isbn = "", category = "", description = "";
int quantity = 1, available = 1;

try (Connection conn = getConnection()) {
    String sql = "SELECT * FROM books WHERE id = ?";
    PreparedStatement ps = conn.prepareStatement(sql);
    ps.setInt(1, bookId);
    ResultSet rs = ps.executeQuery();
    
    if (rs.next()) {
        title = rs.getString("title");
        author = rs.getString("author");
        isbn = rs.getString("isbn");
        category = rs.getString("category");
        quantity = rs.getInt("quantity");
        available = rs.getInt("available");
        description = rs.getString("description");
    } else {
        response.sendRedirect("books.jsp");
        return;
    }
    rs.close();
    ps.close();
} catch (Exception e) {
    error = "Error loading book: " + e.getMessage();
    e.printStackTrace();
}

// Handle form submission
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String newTitle = request.getParameter("title");
    String newAuthor = request.getParameter("author");
    String newIsbn = request.getParameter("isbn");
    String newCategory = request.getParameter("category");
    String quantityStr = request.getParameter("quantity");
    String newDescription = request.getParameter("description");
    
    if (newTitle == null || newTitle.trim().isEmpty() || 
        newAuthor == null || newAuthor.trim().isEmpty() ||
        quantityStr == null || quantityStr.trim().isEmpty()) {
        error = "Title, Author, and Quantity are required!";
    } else {
        try {
            int newQuantity = Integer.parseInt(quantityStr);
            if (newQuantity < 1) {
                error = "Quantity must be at least 1";
            } else {
                // Calculate new available count
                int borrowed = quantity - available;
                int newAvailable = newQuantity - borrowed;
                if (newAvailable < 0) {
                    error = "Quantity cannot be less than borrowed books (" + borrowed + ")";
                } else {
                    try (Connection conn = getConnection()) {
                        String sql = "UPDATE books SET title=?, author=?, isbn=?, category=?, quantity=?, available=?, description=? WHERE id=?";
                        PreparedStatement ps = conn.prepareStatement(sql);
                        ps.setString(1, newTitle);
                        ps.setString(2, newAuthor);
                        ps.setString(3, newIsbn);
                        ps.setString(4, newCategory);
                        ps.setInt(5, newQuantity);
                        ps.setInt(6, newAvailable);
                        ps.setString(7, newDescription);
                        ps.setInt(8, bookId);
                        ps.executeUpdate();
                        ps.close();
                        response.sendRedirect("books.jsp?message=Book updated successfully!");
                        return;
                    } catch (Exception e) {
                        error = "Database error: " + e.getMessage();
                        e.printStackTrace();
                    }
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
                        <% if (error != null) { %>
                        <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        
                        <form method="post">
                            <div class="mb-3">
                                <label class="form-label">Title *</label>
                                <input type="text" class="form-control" name="title" value="<%= title %>" required>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Author *</label>
                                <input type="text" class="form-control" name="author" value="<%= author %>" required>
                            </div>
                            
                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">ISBN</label>
                                    <input type="text" class="form-control" name="isbn" value="<%= isbn != null ? isbn : "" %>">
                                </div>
                                
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">Category</label>
                                    <select class="form-select" name="category">
                                        <option value="Programming" <%= "Programming".equals(category) ? "selected" : "" %>>Programming</option>
                                        <option value="Computer Science" <%= "Computer Science".equals(category) ? "selected" : "" %>>Computer Science</option>
                                        <option value="Fiction" <%= "Fiction".equals(category) ? "selected" : "" %>>Fiction</option>
                                        <option value="Non-Fiction" <%= "Non-Fiction".equals(category) ? "selected" : "" %>>Non-Fiction</option>
                                        <option value="Science" <%= "Science".equals(category) ? "selected" : "" %>>Science</option>
                                        <option value="History" <%= "History".equals(category) ? "selected" : "" %>>History</option>
                                        <option value="Biography" <%= "Biography".equals(category) ? "selected" : "" %>>Biography</option>
                                        <option value="Other" <%= "Other".equals(category) ? "selected" : "" %>>Other</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Quantity *</label>
                                <input type="number" class="form-control" name="quantity" min="<%= quantity - available %>" value="<%= quantity %>" required>
                                <small class="text-muted">Currently borrowed: <%= quantity - available %>, Available: <%= available %></small>
                            </div>
                            
                            <div class="mb-3">
                                <label class="form-label">Description</label>
                                <textarea class="form-control" name="description" rows="3"><%= description != null ? description : "" %></textarea>
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
