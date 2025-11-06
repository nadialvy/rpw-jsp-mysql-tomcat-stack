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

if ("POST".equalsIgnoreCase(request.getMethod())) {
    try (Connection conn = getConnection()) {
        // Check if book has active borrowings
        String checkSql = "SELECT COUNT(*) as cnt FROM borrowings WHERE book_id = ? AND status IN ('pending', 'approved')";
        PreparedStatement checkPs = conn.prepareStatement(checkSql);
        checkPs.setInt(1, bookId);
        ResultSet rs = checkPs.executeQuery();
        rs.next();
        int activeBorrowings = rs.getInt("cnt");
        rs.close();
        checkPs.close();
        
        if (activeBorrowings > 0) {
            response.sendRedirect("books.jsp?message=Cannot delete book with active borrowings!");
            return;
        }
        
        // Delete the book
        String sql = "DELETE FROM books WHERE id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, bookId);
        ps.executeUpdate();
        ps.close();
        response.sendRedirect("books.jsp?message=Book deleted successfully!");
        return;
    } catch (Exception e) {
        response.sendRedirect("books.jsp?message=Error deleting book: " + e.getMessage());
        e.printStackTrace();
        return;
    }
}

// Get book info for confirmation
String bookTitle = "";
try (Connection conn = getConnection()) {
    String sql = "SELECT title FROM books WHERE id = ?";
    PreparedStatement ps = conn.prepareStatement(sql);
    ps.setInt(1, bookId);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
        bookTitle = rs.getString("title");
    } else {
        response.sendRedirect("books.jsp");
        return;
    }
    rs.close();
    ps.close();
} catch (Exception e) {
    e.printStackTrace();
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
                        <p><strong>"<%= bookTitle %>"</strong></p>
                        
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
