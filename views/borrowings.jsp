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

String action = request.getParameter("action");
String idParam = request.getParameter("id");

// Handle actions
if ("POST".equalsIgnoreCase(request.getMethod()) && action != null && idParam != null) {
    int borrowingId = Integer.parseInt(idParam);
    try (Connection conn = getConnection()) {
        if ("approve".equals(action)) {
            String sql = "UPDATE borrowings SET status = 'approved' WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, borrowingId);
            ps.executeUpdate();
            ps.close();
        } else if ("reject".equals(action)) {
            // First get book_id to restore available count
            String getSql = "SELECT book_id FROM borrowings WHERE id = ?";
            PreparedStatement getPs = conn.prepareStatement(getSql);
            getPs.setInt(1, borrowingId);
            ResultSet rs = getPs.executeQuery();
            if (rs.next()) {
                int bookId = rs.getInt("book_id");
                // Update borrowing status
                String updateSql = "UPDATE borrowings SET status = 'rejected' WHERE id = ?";
                PreparedStatement updatePs = conn.prepareStatement(updateSql);
                updatePs.setInt(1, borrowingId);
                updatePs.executeUpdate();
                updatePs.close();
                
                // Restore book availability
                String bookSql = "UPDATE books SET available = available + 1 WHERE id = ?";
                PreparedStatement bookPs = conn.prepareStatement(bookSql);
                bookPs.setInt(1, bookId);
                bookPs.executeUpdate();
                bookPs.close();
            }
            rs.close();
            getPs.close();
        } else if ("return".equals(action)) {
            // Get book_id
            String getSql = "SELECT book_id FROM borrowings WHERE id = ?";
            PreparedStatement getPs = conn.prepareStatement(getSql);
            getPs.setInt(1, borrowingId);
            ResultSet rs = getPs.executeQuery();
            if (rs.next()) {
                int bookId = rs.getInt("book_id");
                // Update borrowing
                String updateSql = "UPDATE borrowings SET status = 'returned', return_date = CURDATE() WHERE id = ?";
                PreparedStatement updatePs = conn.prepareStatement(updateSql);
                updatePs.setInt(1, borrowingId);
                updatePs.executeUpdate();
                updatePs.close();
                
                // Restore book availability
                String bookSql = "UPDATE books SET available = available + 1 WHERE id = ?";
                PreparedStatement bookPs = conn.prepareStatement(bookSql);
                bookPs.setInt(1, bookId);
                bookPs.executeUpdate();
                bookPs.close();
            }
            rs.close();
            getPs.close();
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    response.sendRedirect("borrowings.jsp");
    return;
}

String filterStatus = request.getParameter("status");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Manage Borrowings</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="books.jsp">Manage Books</a></li>
            <li class="nav-item"><a class="nav-link active" href="borrowings.jsp">Manage Borrowings</a></li>
          </ul>
          <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <h3 class="mb-4">📋 Borrowing Management</h3>
        
        <div class="card mb-4">
            <div class="card-body">
                <form method="get" class="row g-3">
                    <div class="col-md-10">
                        <select class="form-select" name="status">
                            <option value="">All Status</option>
                            <option value="pending" <%= "pending".equals(filterStatus) ? "selected" : "" %>>Pending</option>
                            <option value="approved" <%= "approved".equals(filterStatus) ? "selected" : "" %>>Approved</option>
                            <option value="returned" <%= "returned".equals(filterStatus) ? "selected" : "" %>>Returned</option>
                            <option value="rejected" <%= "rejected".equals(filterStatus) ? "selected" : "" %>>Rejected</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <button type="submit" class="btn btn-primary w-100">Filter</button>
                    </div>
                </form>
            </div>
        </div>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>ID</th>
                        <th>User</th>
                        <th>Book</th>
                        <th>Borrow Date</th>
                        <th>Due Date</th>
                        <th>Return Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try (Connection conn = getConnection()) {
                    String sql = "SELECT b.*, u.full_name, u.username, bk.title FROM borrowings b " +
                                 "JOIN users u ON b.user_id = u.id " +
                                 "JOIN books bk ON b.book_id = bk.id";
                    if (filterStatus != null && !filterStatus.trim().isEmpty()) {
                        sql += " WHERE b.status = ?";
                    }
                    sql += " ORDER BY b.id DESC";
                    
                    PreparedStatement ps = conn.prepareStatement(sql);
                    if (filterStatus != null && !filterStatus.trim().isEmpty()) {
                        ps.setString(1, filterStatus);
                    }
                    
                    ResultSet rs = ps.executeQuery();
                    boolean hasData = false;
                    while (rs.next()) {
                        hasData = true;
                        String status = rs.getString("status");
                        String badgeClass = "bg-secondary";
                        if ("pending".equals(status)) badgeClass = "bg-warning text-dark";
                        else if ("approved".equals(status)) badgeClass = "bg-success";
                        else if ("returned".equals(status)) badgeClass = "bg-info";
                        else if ("rejected".equals(status)) badgeClass = "bg-danger";
                %>
                    <tr>
                        <td><%= rs.getInt("id") %></td>
                        <td><strong><%= rs.getString("full_name") %></strong><br><small class="text-muted"><%= rs.getString("username") %></small></td>
                        <td><%= rs.getString("title") %></td>
                        <td><%= rs.getDate("borrow_date") %></td>
                        <td><%= rs.getDate("due_date") %></td>
                        <td><%= rs.getDate("return_date") != null ? rs.getDate("return_date").toString() : "-" %></td>
                        <td><span class="badge <%= badgeClass %>"><%= status.toUpperCase() %></span></td>
                        <td>
                            <% if ("pending".equals(status)) { %>
                            <form method="post" class="d-inline">
                                <input type="hidden" name="id" value="<%= rs.getInt("id") %>">
                                <input type="hidden" name="action" value="approve">
                                <button type="submit" class="btn btn-sm btn-success">Approve</button>
                            </form>
                            <form method="post" class="d-inline">
                                <input type="hidden" name="id" value="<%= rs.getInt("id") %>">
                                <input type="hidden" name="action" value="reject">
                                <button type="submit" class="btn btn-sm btn-danger">Reject</button>
                            </form>
                            <% } else if ("approved".equals(status)) { %>
                            <form method="post" class="d-inline">
                                <input type="hidden" name="id" value="<%= rs.getInt("id") %>">
                                <input type="hidden" name="action" value="return">
                                <button type="submit" class="btn btn-sm btn-info">Mark Returned</button>
                            </form>
                            <% } else { %>
                            <span class="text-muted">-</span>
                            <% } %>
                        </td>
                    </tr>
                <%
                    }
                    if (!hasData) {
                %>
                    <tr><td colspan="8" class="text-center">No borrowings found</td></tr>
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
