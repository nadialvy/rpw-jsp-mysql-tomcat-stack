<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>
<%!

public String verifyLoginAndGetUsername(String username, String password) {
    String username2 = null;
    String sql = "SELECT username FROM users WHERE username = ? AND password = ? LIMIT 1";
    try (Connection c = getConnection();
            PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, username);
                ps.setString(2, password);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) username2 = rs.getString("username");
                }
    } catch (Exception e) {
        System.err.println("verifyLogin error: " + e.getMessage());
    }
    return username2;
}
%>