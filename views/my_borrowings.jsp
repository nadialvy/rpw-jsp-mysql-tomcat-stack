<%@ include file="../classes/auth.jsp" %>
<% 
Integer userId = (Integer) session.getAttribute("userId");
String role = (String) session.getAttribute("role");

if (userId == null) { 
  response.sendRedirect("login.jsp"); 
  return; 
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>My Borrowings</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="customer_books.jsp">Browse Books</a></li>
            <li class="nav-item"><a class="nav-link active" href="my_borrowings.jsp">My Borrowings</a></li>
          </ul>
          <div class="d-flex align-items-center text-white">
            <span class="me-3"><%= session.getAttribute("fullName") %></span>
            <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
          </div>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <h3 class="mb-4">📋 My Borrowing History</h3>
        
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card text-white bg-warning">
                    <div class="card-body text-center">
                        <h5>Pending</h5>
                        <%
                        try (Connection conn = getConnection()) {
                            String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE user_id = ? AND status = 'pending'";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setInt(1, userId);
                            ResultSet rs = ps.executeQuery();
                            rs.next();
                            out.print("<h2>" + rs.getInt("cnt") + "</h2>");
                            rs.close();
                            ps.close();
                        } catch (Exception e) {}
                        %>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-success">
                    <div class="card-body text-center">
                        <h5>Approved</h5>
                        <%
                        try (Connection conn = getConnection()) {
                            String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE user_id = ? AND status = 'approved'";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setInt(1, userId);
                            ResultSet rs = ps.executeQuery();
                            rs.next();
                            out.print("<h2>" + rs.getInt("cnt") + "</h2>");
                            rs.close();
                            ps.close();
                        } catch (Exception e) {}
                        %>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-info">
                    <div class="card-body text-center">
                        <h5>Returned</h5>
                        <%
                        try (Connection conn = getConnection()) {
                            String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE user_id = ? AND status = 'returned'";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setInt(1, userId);
                            ResultSet rs = ps.executeQuery();
                            rs.next();
                            out.print("<h2>" + rs.getInt("cnt") + "</h2>");
                            rs.close();
                            ps.close();
                        } catch (Exception e) {}
                        %>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card text-white bg-danger">
                    <div class="card-body text-center">
                        <h5>Rejected</h5>
                        <%
                        try (Connection conn = getConnection()) {
                            String sql = "SELECT COUNT(*) as cnt FROM borrowings WHERE user_id = ? AND status = 'rejected'";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setInt(1, userId);
                            ResultSet rs = ps.executeQuery();
                            rs.next();
                            out.print("<h2>" + rs.getInt("cnt") + "</h2>");
                            rs.close();
                            ps.close();
                        } catch (Exception e) {}
                        %>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>Book Title</th>
                        <th>Author</th>
                        <th>Borrow Date</th>
                        <th>Due Date</th>
                        <th>Return Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try (Connection conn = getConnection()) {
                    String sql = "SELECT b.*, bk.title, bk.author FROM borrowings b " +
                                 "JOIN books bk ON b.book_id = bk.id " +
                                 "WHERE b.user_id = ? ORDER BY b.id DESC";
                    
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, userId);
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
                        
                        // Check if overdue
                        java.sql.Date dueDate = rs.getDate("due_date");
                        java.sql.Date returnDate = rs.getDate("return_date");
                        java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
                        boolean isOverdue = "approved".equals(status) && dueDate.before(today);
                %>
                    <tr class="<%= isOverdue ? "table-danger" : "" %>">
                        <td><strong><%= rs.getString("title") %></strong></td>
                        <td><%= rs.getString("author") %></td>
                        <td><%= rs.getDate("borrow_date") %></td>
                        <td>
                            <%= dueDate %>
                            <% if (isOverdue) { %>
                            <span class="badge bg-danger">OVERDUE</span>
                            <% } %>
                        </td>
                        <td><%= returnDate != null ? returnDate.toString() : "-" %></td>
                        <td><span class="badge <%= badgeClass %>"><%= status.toUpperCase() %></span></td>
                    </tr>
                <%
                    }
                    if (!hasData) {
                %>
                    <tr><td colspan="6" class="text-center">No borrowing history</td></tr>
                <%
                    }
                    rs.close();
                    ps.close();
                } catch (Exception e) {
                    out.println("<tr><td colspan='6' class='text-danger'>Error: " + e.getMessage() + "</td></tr>");
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
