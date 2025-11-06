<%@ include file="../classes/auth.jsp" %>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <link
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
      rel="stylesheet"
    />
    <link href="../css/app.css" rel="stylesheet" />
    <title>Login</title>
  </head>
  <body class="bg-light">
    <%
      if (session.getAttribute("userId") != null) {
        response.sendRedirect("home.jsp");
        return;
      }

      String err = null;
      if ("POST".equalsIgnoreCase(request.getMethod())) {
        String usernameField = request.getParameter("username");
        String password = request.getParameter("password");

        if (usernameField == null || usernameField.isEmpty() || password == null || password.isEmpty()) {
          err = "Semua field wajib diisi";
        } else {
          User user = verifyLogin(usernameField, password);
          if (user != null) {
            session.setAttribute("userId", user.id);
            session.setAttribute("username", user.username);
            session.setAttribute("fullName", user.fullName);
            session.setAttribute("role", user.role);
            response.sendRedirect("home.jsp");
            return;
          } else {
            err = "Username atau password salah";
          }
        }
      }
    %>
    <div class="container py-5">
      <div class="row justify-content-center">
        <div class="col-md-4">
          <div class="card shadow-sm">
            <div class="card-body">
              <h4 class="mb-3">Sign in</h4>
              <form method="post" class="vstack gap-3">
                <input
                  class="form-control"
                  name="username"
                  placeholder="Username"
                  required
                />
                <input
                  class="form-control"
                  type="password"
                  name="password"
                  placeholder="Password"
                  required
                />
                <button class="btn btn-primary w-100">Login</button>
              </form>
              <% if (err != null) { %>
              <div class="mt-3 text-danger small"><%= err %></div>
              <% } %>
            </div>
          </div>
        </div>
      </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
