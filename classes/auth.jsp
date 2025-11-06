<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ include file="db.jsp" %>
<%!

public class User {
    public int id;
    public String username;
    public String fullName;
    public String role;
    
    public User(int id, String username, String fullName, String role) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.role = role;
    }
}

public User verifyLogin(String username, String password) {
    User user = null;
    String sql = "SELECT id, username, full_name, role FROM users WHERE username = ? AND password = ? LIMIT 1";
    try (Connection c = getConnection();
            PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, username);
                ps.setString(2, password);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        user = new User(
                            rs.getInt("id"),
                            rs.getString("username"),
                            rs.getString("full_name"),
                            rs.getString("role")
                        );
                    }
                }
    } catch (Exception e) {
        System.err.println("verifyLogin error: " + e.getMessage());
        e.printStackTrace();
    }
    return user;
}

public boolean isAdmin(HttpSession session) {
    String role = (String) session.getAttribute("role");
    return "admin".equals(role);
}

public boolean isCustomer(HttpSession session) {
    String role = (String) session.getAttribute("role");
    return "customer".equals(role);
}
%>