<%@ include file="../classes/auth.jsp" %>
<% 
Integer userId = (Integer) session.getAttribute("userId");
String role = (String) session.getAttribute("role");

if (userId == null) { 
  response.sendRedirect("login.jsp"); 
  return; 
}

String action = request.getParameter("action");
String bookIdParam = request.getParameter("bookId");

// Handle borrow request
if ("POST".equalsIgnoreCase(request.getMethod()) && "borrow".equals(action) && bookIdParam != null) {
    int bookId = Integer.parseInt(bookIdParam);
    try (Connection conn = getConnection()) {
        // Check if book is available
        String checkSql = "SELECT available FROM books WHERE id = ?";
        PreparedStatement checkPs = conn.prepareStatement(checkSql);
        checkPs.setInt(1, bookId);
        ResultSet rs = checkPs.executeQuery();
        
        if (rs.next() && rs.getInt("available") > 0) {
            // Create borrowing request
            String insertSql = "INSERT INTO borrowings (user_id, book_id, borrow_date, due_date, status) " +
                              "VALUES (?, ?, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'pending')";
            PreparedStatement insertPs = conn.prepareStatement(insertSql);
            insertPs.setInt(1, userId);
            insertPs.setInt(2, bookId);
            insertPs.executeUpdate();
            insertPs.close();
            
            // Decrease available count
            String updateSql = "UPDATE books SET available = available - 1 WHERE id = ?";
            PreparedStatement updatePs = conn.prepareStatement(updateSql);
            updatePs.setInt(1, bookId);
            updatePs.executeUpdate();
            updatePs.close();
        }
        rs.close();
        checkPs.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    response.sendRedirect("customer_books.jsp?message=Borrowing request submitted!");
    return;
}

String search = request.getParameter("search");
String category = request.getParameter("category");
String message = request.getParameter("message");
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
        
        <% if (message != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <%= message %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>
        
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
        try (Connection conn = getConnection()) {
            String sql = "SELECT * FROM books WHERE 1=1";
            if (search != null && !search.trim().isEmpty()) {
                sql += " AND (title LIKE ? OR author LIKE ?)";
            }
            if (category != null && !category.trim().isEmpty()) {
                sql += " AND category = ?";
            }
            sql += " ORDER BY title";
            
            PreparedStatement ps = conn.prepareStatement(sql);
            int paramIndex = 1;
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search + "%";
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
            }
            if (category != null && !category.trim().isEmpty()) {
                ps.setString(paramIndex++, category);
            }
            
            ResultSet rs = ps.executeQuery();
            boolean hasData = false;
            while (rs.next()) {
                hasData = true;
                int available = rs.getInt("available");
        %>
            <div class="col-md-4 mb-4">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title"><%= rs.getString("title") %></h5>
                        <h6 class="card-subtitle mb-2 text-muted"><%= rs.getString("author") %></h6>
                        <p class="card-text">
                            <span class="badge bg-info"><%= rs.getString("category") %></span>
                            <% if (rs.getString("isbn") != null) { %>
                            <br><small class="text-muted">ISBN: <%= rs.getString("isbn") %></small>
                            <% } %>
                        </p>
                        <% if (rs.getString("description") != null) { %>
                        <p class="card-text"><small><%= rs.getString("description") %></small></p>
                        <% } %>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="<%= available > 0 ? "text-success" : "text-danger" %>">
                                <strong><%= available %> available</strong>
                            </span>
                            <% if (available > 0) { %>
                            <form method="post" class="d-inline">
                                <input type="hidden" name="action" value="borrow">
                                <input type="hidden" name="bookId" value="<%= rs.getInt("id") %>">
                                <button type="submit" class="btn btn-sm btn-primary" 
                                        onclick="return confirm('Borrow this book?')">Borrow</button>
                            </form>
                            <% } else { %>
                            <button class="btn btn-sm btn-secondary" disabled>Not Available</button>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        <%
            }
            if (!hasData) {
        %>
            <div class="col-12"><div class="alert alert-info">No books found</div></div>
        <%
            }
            rs.close();
            ps.close();
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
