<%@ include file="../classes/auth.jsp" %>
<% 
Integer userId = (Integer) session.getAttribute("userId");
String username = (String) session.getAttribute("username");
String fullName = (String) session.getAttribute("fullName");
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
    <link
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
      rel="stylesheet"
    />
    <title>Home - Library System</title>
  </head>
  <body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
          <ul class="navbar-nav me-auto">
            <li class="nav-item">
              <a class="nav-link active" href="home.jsp">Home</a>
            </li>
            <% if ("admin".equals(role)) { %>
            <li class="nav-item">
              <a class="nav-link" href="books.jsp">Manage Books</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="borrowings.jsp">Manage Borrowings</a>
            </li>
            <li class="nav-item dropdown">
              <a class="nav-link dropdown-toggle" href="#" id="importExport" role="button" data-bs-toggle="dropdown">
                Import/Export
              </a>
              <ul class="dropdown-menu">
                <li><a class="dropdown-item" href="book_import.jsp">Import Books (CSV)</a></li>
                <li><a class="dropdown-item" href="borrowing_export.jsp">Export Borrowings</a></li>
              </ul>
            </li>
            <% } else { %>
            <li class="nav-item">
              <a class="nav-link" href="customer_books.jsp">Browse Books</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="my_borrowings.jsp">My Borrowings</a>
            </li>
            <% } %>
          </ul>
          <div class="d-flex align-items-center text-white">
            <span class="me-3">Hi, <b><%= fullName %></b> (<%= role %>)</span>
            <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
          </div>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
      <h3 class="mb-4">Welcome to Library Management System</h3>
      
      <div class="row">
        <% if ("admin".equals(role)) { %>
        <div class="col-md-4 mb-3">
          <div class="card text-white bg-primary">
            <div class="card-body">
              <h5 class="card-title">📚 Manage Books</h5>
              <p class="card-text">Add, edit, delete books in the library</p>
              <a href="books.jsp" class="btn btn-light">Go to Books</a>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card text-white bg-success">
            <div class="card-body">
              <h5 class="card-title">📋 Manage Borrowings</h5>
              <p class="card-text">View and manage all borrowing requests</p>
              <a href="borrowings.jsp" class="btn btn-light">Go to Borrowings</a>
            </div>
          </div>
        </div>
        <div class="col-md-4 mb-3">
          <div class="card text-white bg-info">
            <div class="card-body">
              <h5 class="card-title">📊 Import/Export</h5>
              <p class="card-text">Import books or export borrowing data</p>
              <a href="book_import.jsp" class="btn btn-light">Import/Export</a>
            </div>
          </div>
        </div>
        <% } else { %>
        <div class="col-md-6 mb-3">
          <div class="card text-white bg-primary">
            <div class="card-body">
              <h5 class="card-title">📚 Browse Books</h5>
              <p class="card-text">Find and borrow books from our collection</p>
              <a href="customer_books.jsp" class="btn btn-light">Browse Books</a>
            </div>
          </div>
        </div>
        <div class="col-md-6 mb-3">
          <div class="card text-white bg-success">
            <div class="card-body">
              <h5 class="card-title">📋 My Borrowings</h5>
              <p class="card-text">View your borrowing history and status</p>
              <a href="my_borrowings.jsp" class="btn btn-light">View My Borrowings</a>
            </div>
          </div>
        </div>
        <% } %>
      </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
