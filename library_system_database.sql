-- =====================================================
-- Library Management System - Complete Database Setup
-- =====================================================
-- Run this file if you need to manually recreate database
-- =====================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS rpwdb;
CREATE DATABASE rpwdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rpwdb;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS borrowings;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS users;

-- =====================================================
-- Table: users
-- =====================================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role ENUM('admin', 'customer') NOT NULL DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: books
-- =====================================================
CREATE TABLE books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    isbn VARCHAR(50),
    category VARCHAR(100),
    quantity INT NOT NULL DEFAULT 1,
    available INT NOT NULL DEFAULT 1,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_title (title),
    INDEX idx_author (author),
    INDEX idx_category (category),
    INDEX idx_isbn (isbn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Table: borrowings
-- =====================================================
CREATE TABLE borrowings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('pending', 'approved', 'returned', 'rejected') NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_book_id (book_id),
    INDEX idx_status (status),
    INDEX idx_borrow_date (borrow_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Sample Data: Users
-- =====================================================
INSERT INTO users (username, password, full_name, role) VALUES
('admin', 'admin123', 'Administrator', 'admin'),
('customer1', 'customer123', 'John Doe', 'customer'),
('customer2', 'customer123', 'Jane Smith', 'customer'),
('customer3', 'customer123', 'Bob Wilson', 'customer');

-- =====================================================
-- Sample Data: Books
-- =====================================================
INSERT INTO books (title, author, isbn, category, quantity, available, description) VALUES
('Clean Code', 'Robert C. Martin', '978-0132350884', 'Programming', 3, 3, 'A Handbook of Agile Software Craftsmanship'),
('The Pragmatic Programmer', 'David Thomas', '978-0201616224', 'Programming', 2, 2, 'From Journeyman to Master'),
('Design Patterns', 'Gang of Four', '978-0201633610', 'Programming', 2, 2, 'Elements of Reusable Object-Oriented Software'),
('Introduction to Algorithms', 'Thomas H. Cormen', '978-0262033848', 'Computer Science', 2, 2, 'Comprehensive algorithms textbook'),
('The Hobbit', 'J.R.R. Tolkien', '978-0547928227', 'Fiction', 5, 5, 'Classic fantasy adventure'),
('1984', 'George Orwell', '978-0451524935', 'Fiction', 4, 4, 'Dystopian social science fiction'),
('To Kill a Mockingbird', 'Harper Lee', '978-0061120084', 'Fiction', 3, 3, 'American classic novel'),
('Sapiens', 'Yuval Noah Harari', '978-0062316097', 'Non-Fiction', 5, 5, 'A Brief History of Humankind'),
('Educated', 'Tara Westover', '978-0399590504', 'Biography', 3, 3, 'A Memoir about education'),
('The Art of War', 'Sun Tzu', '978-1599869773', 'History', 4, 4, 'Ancient Chinese military treatise');

-- =====================================================
-- Sample Data: Borrowings
-- =====================================================
INSERT INTO borrowings (user_id, book_id, borrow_date, due_date, return_date, status) VALUES
(2, 1, '2025-10-01', '2025-10-15', '2025-10-14', 'returned'),
(2, 5, '2025-11-01', '2025-11-15', NULL, 'approved'),
(3, 2, '2025-11-03', '2025-11-17', NULL, 'approved'),
(3, 6, '2025-10-20', '2025-11-03', '2025-11-02', 'returned'),
(4, 3, '2025-11-05', '2025-11-19', NULL, 'pending');

-- Update available count for currently borrowed books
UPDATE books SET available = available - 1 WHERE id IN (5, 2);

-- =====================================================
-- Verify Installation
-- =====================================================
SELECT 'Users created:' AS '', COUNT(*) AS count FROM users;
SELECT 'Books created:' AS '', COUNT(*) AS count FROM books;
SELECT 'Borrowings created:' AS '', COUNT(*) AS count FROM borrowings;

-- =====================================================
-- Show sample data
-- =====================================================
SELECT '=== USERS ===' AS '';
SELECT id, username, full_name, role FROM users;

SELECT '=== BOOKS ===' AS '';
SELECT id, title, author, category, quantity, available FROM books;

SELECT '=== BORROWINGS ===' AS '';
SELECT b.id, u.full_name AS user, bk.title AS book, b.borrow_date, b.due_date, b.status 
FROM borrowings b
JOIN users u ON b.user_id = u.id
JOIN books bk ON b.book_id = bk.id;

-- =====================================================
-- End of Script
-- =====================================================
