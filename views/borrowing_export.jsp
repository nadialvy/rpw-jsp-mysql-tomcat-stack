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

// Set response headers for CSV download
response.setContentType("text/csv");
response.setHeader("Content-Disposition", "attachment; filename=\"borrowings_export_" + 
                   new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(new java.util.Date()) + ".csv\"");

try (Connection conn = getConnection()) {
    // Write CSV header
    out.print("Borrowing ID,User ID,Username,Full Name,Book ID,Book Title,Author,Borrow Date,Due Date,Return Date,Status,Notes\r\n");
    
    // Query all borrowings
    String sql = "SELECT b.*, u.username, u.full_name, bk.title, bk.author " +
                 "FROM borrowings b " +
                 "JOIN users u ON b.user_id = u.id " +
                 "JOIN books bk ON b.book_id = bk.id " +
                 "ORDER BY b.id DESC";
    
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();
    
    while (rs.next()) {
        // Escape CSV fields
        String notes = rs.getString("notes");
        if (notes != null) {
            notes = "\"" + notes.replace("\"", "\"\"") + "\"";
        } else {
            notes = "";
        }
        
        String returnDate = rs.getDate("return_date") != null ? rs.getDate("return_date").toString() : "";
        
        out.print(rs.getInt("id") + ",");
        out.print(rs.getInt("user_id") + ",");
        out.print("\"" + rs.getString("username") + "\",");
        out.print("\"" + rs.getString("full_name") + "\",");
        out.print(rs.getInt("book_id") + ",");
        out.print("\"" + rs.getString("title").replace("\"", "\"\"") + "\",");
        out.print("\"" + rs.getString("author").replace("\"", "\"\"") + "\",");
        out.print(rs.getDate("borrow_date") + ",");
        out.print(rs.getDate("due_date") + ",");
        out.print(returnDate + ",");
        out.print(rs.getString("status") + ",");
        out.print(notes);
        out.print("\r\n");
    }
    
    rs.close();
    ps.close();
} catch (Exception e) {
    out.println("Error: " + e.getMessage());
    e.printStackTrace();
}

out.flush();
%>
