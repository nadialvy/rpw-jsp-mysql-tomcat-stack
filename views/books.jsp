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

String search = request.getParameter("search");
String message = request.getParameter("message");
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
        
        <% if (message != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>
        
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
                try (Connection conn = getConnection()) {
                    String sql = "SELECT * FROM books";
                    if (search != null && !search.trim().isEmpty()) {
                        sql += " WHERE title LIKE ? OR author LIKE ? OR isbn LIKE ? OR category LIKE ?";
                    }
                    sql += " ORDER BY id DESC";
                    
                    PreparedStatement ps = conn.prepareStatement(sql);
                    if (search != null && !search.trim().isEmpty()) {
                        String searchPattern = "%" + search + "%";
                        ps.setString(1, searchPattern);
                        ps.setString(2, searchPattern);
                        ps.setString(3, searchPattern);
                        ps.setString(4, searchPattern);
                    }
                    
                    ResultSet rs = ps.executeQuery();
                    boolean hasData = false;
                    while (rs.next()) {
                        hasData = true;
                %>
                    <tr>
                        <td><%= rs.getInt("id") %></td>
                        <td><strong><%= rs.getString("title") %></strong></td>
                        <td><%= rs.getString("author") %></td>
                        <td><%= rs.getString("isbn") != null ? rs.getString("isbn") : "-" %></td>
                        <td><span class="badge bg-info"><%= rs.getString("category") %></span></td>
                        <td><%= rs.getInt("quantity") %></td>
                        <td>
                            <span class="badge <%= rs.getInt("available") > 0 ? "bg-success" : "bg-danger" %>">
                                <%= rs.getInt("available") %>
                            </span>
                        </td>
                        <td>
                            <a href="book_edit.jsp?id=<%= rs.getInt("id") %>" class="btn btn-sm btn-warning">Edit</a>
                            <a href="book_delete.jsp?id=<%= rs.getInt("id") %>" class="btn btn-sm btn-danger" 
                               onclick="return confirm('Delete this book?')">Delete</a>
                        </td>
                    </tr>
                <%
                    }
                    if (!hasData) {
                %>
                    <tr><td colspan="8" class="text-center">No books found</td></tr>
                <%
                    }
                    rs.close();
                    ps.close();
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
