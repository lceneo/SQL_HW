-- =========================
-- SEQUENCES
-- =========================

CREATE SEQUENCE seq_books START 1;
CREATE SEQUENCE seq_users START 1;
CREATE SEQUENCE seq_reservations START 1;

-- =========================
-- TABLE: Users
-- =========================

CREATE TABLE Users (
    user_id INT PRIMARY KEY DEFAULT nextval('seq_users'),
    is_librarian BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================
-- TABLE: Books
-- =========================

CREATE TABLE Books (
    book_id INT PRIMARY KEY DEFAULT nextval('seq_books'),
    name TEXT NOT NULL,
    author TEXT NOT NULL,
    publish_year INT,
    page_count INT NOT NULL CHECK (page_count > 0),
    is_reserved BOOLEAN NOT NULL DEFAULT FALSE
);

-- =========================
-- TABLE: Books_reservation
-- =========================

CREATE TABLE Books_reservation (
    reservation_id INT PRIMARY KEY DEFAULT nextval('seq_reservations'),
    book_id INT NOT NULL REFERENCES Books(book_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES Users(user_id),
    reservation_date DATE NOT NULL,
    page_count INT NOT NULL CHECK (page_count > 0)
);

-- =========================
-- INITIAL DATA
-- =========================

-- Users
INSERT INTO Users (is_librarian) VALUES
(FALSE),  -- обычный читатель
(TRUE);   -- библиотекарь

-- Books
INSERT INTO Books (name, author, publish_year, page_count, is_reserved) VALUES
('1984', 'George Orwell', 1949, 328, FALSE),
('Brave New World', 'Aldous Huxley', 1932, 311, FALSE),
('Fahrenheit 451', 'Ray Bradbury', 1953, 256, FALSE);
