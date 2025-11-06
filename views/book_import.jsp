<%@ page import="java.io.*" %>
<%@ page import="jakarta.servlet.http.Part" %>
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

String message = null;
String error = null;

// Handle file upload
if ("POST".equalsIgnoreCase(request.getMethod())) {
    try {
        Part filePart = request.getPart("csvFile");
        if (filePart != null && filePart.getSize() > 0) {
            InputStream is = filePart.getInputStream();
            BufferedReader reader = new BufferedReader(new InputStreamReader(is, "UTF-8"));
            
            String line;
            int lineNum = 0;
            int imported = 0;
            int skipped = 0;
            
            Connection conn = getConnection();
            conn.setAutoCommit(false);
            
            try {
                while ((line = reader.readLine()) != null) {
                    lineNum++;
                    if (lineNum == 1) continue; // Skip header
                    
                    String[] fields = line.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", -1);
                    if (fields.length < 2) {
                        skipped++;
                        continue;
                    }
                    
                    String title = fields[0].trim().replaceAll("^\"|\"$", "");
                    String author = fields[1].trim().replaceAll("^\"|\"$", "");
                    String isbn = fields.length > 2 ? fields[2].trim().replaceAll("^\"|\"$", "") : "";
                    String category = fields.length > 3 ? fields[3].trim().replaceAll("^\"|\"$", "") : "Other";
                    int quantity = 1;
                    try {
                        quantity = fields.length > 4 ? Integer.parseInt(fields[4].trim()) : 1;
                    } catch (Exception e) {}
                    String description = fields.length > 5 ? fields[5].trim().replaceAll("^\"|\"$", "") : "";
                    
                    if (title.isEmpty() || author.isEmpty()) {
                        skipped++;
                        continue;
                    }
                    
                    String sql = "INSERT INTO books (title, author, isbn, category, quantity, available, description) VALUES (?, ?, ?, ?, ?, ?, ?)";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setString(1, title);
                    ps.setString(2, author);
                    ps.setString(3, isbn);
                    ps.setString(4, category);
                    ps.setInt(5, quantity);
                    ps.setInt(6, quantity);
                    ps.setString(7, description);
                    ps.executeUpdate();
                    ps.close();
                    imported++;
                }
                
                conn.commit();
                message = "Successfully imported " + imported + " books" + (skipped > 0 ? " (skipped " + skipped + " invalid rows)" : "");
            } catch (Exception e) {
                conn.rollback();
                error = "Import failed: " + e.getMessage();
                e.printStackTrace();
            } finally {
                conn.setAutoCommit(true);
                conn.close();
            }
            
            reader.close();
            is.close();
        } else {
            error = "No file uploaded";
        }
    } catch (Exception e) {
        error = "Upload failed: " + e.getMessage();
        e.printStackTrace();
    }
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <title>Import Books</title>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
      <div class="container-fluid">
        <a class="navbar-brand" href="home.jsp">📚 Library System</a>
        <div class="collapse navbar-collapse">
          <ul class="navbar-nav me-auto">
            <li class="nav-item"><a class="nav-link" href="home.jsp">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="books.jsp">Manage Books</a></li>
            <li class="nav-item"><a class="nav-link active" href="book_import.jsp">Import Books</a></li>
          </ul>
          <a href="logout.jsp" class="btn btn-outline-light btn-sm">Logout</a>
        </div>
      </div>
    </nav>
    
    <div class="container py-4">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header bg-info text-white">
                        <h4 class="mb-0">📥 Import Books from CSV</h4>
                    </div>
                    <div class="card-body">
                        <% if (message != null) { %>
                        <div class="alert alert-success"><%= message %></div>
                        <% } %>
                        <% if (error != null) { %>
                        <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        
                        <div class="alert alert-info">
                            <h6>CSV Format:</h6>
                            <p class="mb-1"><strong>Required columns:</strong> Title, Author</p>
                            <p class="mb-1"><strong>Optional columns:</strong> ISBN, Category, Quantity, Description</p>
                            <p class="mb-0"><strong>Example:</strong></p>
                            <code>Title,Author,ISBN,Category,Quantity,Description<br>
                            "Clean Code","Robert Martin","978-0132350884","Programming",3,"Great book"</code>
                        </div>
                        
                        <form method="post" enctype="multipart/form-data">
                            <div class="mb-3">
                                <label class="form-label">Choose CSV File</label>
                                <input type="file" class="form-control" name="csvFile" accept=".csv" required>
                            </div>
                            
                            <div class="d-flex gap-2">
                                <button type="submit" class="btn btn-info">Upload & Import</button>
                                <a href="books.jsp" class="btn btn-secondary">Back to Books</a>
                                <a href="../sample_books.csv" class="btn btn-outline-secondary" download>Download Sample CSV</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
