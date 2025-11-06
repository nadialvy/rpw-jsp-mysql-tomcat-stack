<% 
String username = (String) session.getAttribute("username"); 
if (username == null) { 
  response.sendRedirect("login.jsp"); 
  return; 
} 
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <link
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
      rel="stylesheet"
    />
    <title>Home</title>
  </head>
  <body>
    <nav class="navbar navbar-light bg-light px-3">
      <span class="navbar-brand">RPW</span>
      <div class="ms-auto">
        Hi, <b><%= username != null ? username : "default" %></b> ·
        <a href="logout.jsp" class="btn btn-outline-secondary btn-sm">Logout</a>
      </div>
    </nav>
    <div class="container py-4">
      <h3 class="mb-3">Dashboard</h3>
      <p>Welcome to your home page.</p>
    </div>
  </body>
</html>
