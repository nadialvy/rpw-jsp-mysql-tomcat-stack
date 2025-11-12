<%@ page import="java.sql.*" %>
<%@ include file="../classes/auth.jsp" %>

<%!
    /**
     * LoginManager Class
     * Handles user authentication and login operations
     */
    public class LoginManager {
        private HttpServletRequest request;
        private HttpServletResponse response;
        private HttpSession session;
        private JspWriter out;
        
        private String errorMessage;
        
        // Constructor
        public LoginManager(HttpServletRequest request, HttpServletResponse response, 
                           HttpSession session, JspWriter out) {
            this.request = request;
            this.response = response;
            this.session = session;
            this.out = out;
        }
        
        /**
         * Check if user is already logged in
         */
        public boolean isLoggedIn() throws Exception {
            if (session.getAttribute("userId") != null) {
                response.sendRedirect("home.jsp");
                return true;
            }
            return false;
        }
        
        /**
         * Validate login credentials
         */
        public boolean validateInput(String username, String password) {
            if (username == null || username.isEmpty()) {
                errorMessage = "Username is required";
                return false;
            }
            
            if (password == null || password.isEmpty()) {
                errorMessage = "Password is required";
                return false;
            }
            
            return true;
        }
        
        /**
         * Process login
         */
        public boolean processLogin() throws Exception {
            if (!"POST".equalsIgnoreCase(request.getMethod())) {
                return false;
            }
            
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            
            if (!validateInput(username, password)) {
                return false;
            }
            
            User user = verifyLogin(username, password);
            
            if (user != null) {
                session.setAttribute("userId", user.id);
                session.setAttribute("username", user.username);
                session.setAttribute("fullName", user.fullName);
                session.setAttribute("role", user.role);
                response.sendRedirect("home.jsp");
                return true;
            } else {
                errorMessage = "Username atau password salah";
                return false;
            }
        }
        
        /**
         * Get error message
         */
        public String getErrorMessage() {
            return errorMessage;
        }
    }
%>

<%
    // Initialize LoginManager
    LoginManager loginManager = new LoginManager(request, response, session, out);
    
    // Check if already logged in
    if (loginManager.isLoggedIn()) {
        return;
    }
    
    // Process login
    if (loginManager.processLogin()) {
        return;
    }
    
    String err = loginManager.getErrorMessage();
%>

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
              <%
              if (err != null) {
              %>
              <div class="mt-3 text-danger small"><%= err %></div>
              <%
              }
              %>
            </div>
          </div>
        </div>
      </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
