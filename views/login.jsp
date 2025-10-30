<%@page import="java.sql.*"%>
<%@ include file="../classes/dbconnect.jsp" %>
<!DOCTYPE html>
<html>
<head>
 <meta charset="utf-8"/>
 <meta name="viewport" content="width=device-width,initial-scale=1"/>
 <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
 <link href="../css/app.css" rel="stylesheet">
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
           <input class="form-control" name="username" placeholder="Username" required>
           <input class="form-control" type="password" name="password" placeholder="Password" required>
           <button class="btn btn-primary w-100">Login</button>
         </form>
         <div class="mt-3 text-danger small">
           <%
             String u=request.getParameter("username");
             String p=request.getParameter("password");
             if(u!=null && p!=null){
               try(PreparedStatement ps=conn.prepareStatement(
                 "SELECT id FROM users WHERE username=? AND password=?")){
                 ps.setString(1,u); ps.setString(2,p);
                 try(ResultSet rs=ps.executeQuery()){
                   if(rs.next()){ session.setAttribute("user",u); response.sendRedirect("home.jsp"); }
                   else { out.print("Login gagal. Cek username/password."); }
                 }
               }
             }
           %>
         </div>
       </div>
     </div>
   </div>
 </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
