<%@ page import="java.sql.*" %>
<%!
    public Connection getConnection() throws Exception {
        String url = "jdbc:mysql://db:3306/rpwdb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
        String user = "rpwuser";
        String pass = "rpwpass";
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(url, user, pass);
    }
%>