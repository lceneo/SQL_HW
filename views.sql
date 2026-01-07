-- Список доступных к брони книг
CREATE OR REPLACE VIEW v_available_books AS
SELECT
    book_id,
    name,
    author,
    publish_year,
    page_count
FROM Books
WHERE is_reserved = FALSE;

-- Список забронированных книг
CREATE OR REPLACE VIEW v_reserved_books AS
SELECT
    book_id,
    name,
    author,
    publish_year,
    page_count
FROM Books
WHERE is_reserved = TRUE;

-- Список заявок на возврат
CREATE OR REPLACE VIEW v_return_requests AS
SELECT
    r.reservation_id,
    r.book_id,
    b.name AS book_name,
    r.user_id,
    r.reservation_date,
    r.page_count AS returned_page_count,
    b.page_count AS original_page_count
FROM Books_reservation r
JOIN Books b ON b.book_id = r.book_id;

-- Список статуса заявок на возврат
CREATE OR REPLACE VIEW v_return_check AS
SELECT
    r.book_id,
    b.page_count = r.page_count AS is_return_valid
FROM Books b
JOIN Books_reservation r ON b.book_id = r.book_id;
