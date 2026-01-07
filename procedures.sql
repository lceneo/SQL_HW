-- =========================
-- SERVICE PROCEDURES
-- =========================

-- Добавление книги (используется и для подарка)
CREATE OR REPLACE PROCEDURE add_book(
    p_name TEXT,
    p_author TEXT,
    p_publish_year INT,
    p_page_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Books (name, author, publish_year, page_count, is_reserved)
    VALUES (p_name, p_author, p_publish_year, p_page_count, FALSE);
END;
$$;

-- Установка статуса книги
CREATE OR REPLACE PROCEDURE set_book_reserved_status(
    p_book_id INT,
    p_is_reserved BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Books
    SET is_reserved = p_is_reserved
    WHERE book_id = p_book_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Книга с id % не найдена', p_book_id;
    END IF;
END;
$$;

-- Добавление бронирования
CREATE OR REPLACE PROCEDURE add_reservation(
    p_book_id INT,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_page_count INT;
BEGIN
    SELECT page_count
    INTO v_page_count
    FROM Books
    WHERE book_id = p_book_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Книга не найдена';
    END IF;

    INSERT INTO Books_reservation (
        book_id,
        user_id,
        reservation_date,
        page_count
    )
    VALUES (
        p_book_id,
        p_user_id,
        CURRENT_DATE,
        v_page_count
    );
END;
$$;

-- Удаление бронирования
CREATE OR REPLACE PROCEDURE delete_reservation(
    p_book_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM Books_reservation
    WHERE book_id = p_book_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Бронирование для книги % не найдено', p_book_id;
    END IF;
END;
$$;

-- =========================
-- BUSINESS PROCESSES
-- =========================

-- 1.1 Бронирование книги
CREATE OR REPLACE PROCEDURE reserve_book(
    p_book_id INT,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_reserved BOOLEAN;
BEGIN
    SELECT is_reserved
    INTO v_is_reserved
    FROM Books
    WHERE book_id = p_book_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Книга не найдена';
    END IF;

    IF v_is_reserved THEN
        RAISE EXCEPTION 'Книга уже забронирована';
    END IF;

    CALL add_reservation(p_book_id, p_user_id);
    CALL set_book_reserved_status(p_book_id, TRUE);
END;
$$;

-- 1.2 Возврат книги (создание заявки)
CREATE OR REPLACE PROCEDURE return_book(
    p_book_id INT,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Books_reservation
        WHERE book_id = p_book_id
          AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Нет активного бронирования для возврата';
    END IF;

    -- Заявка уже существует, дополнительных действий не требуется
END;
$$;

-- 1.4 Проверка возвращённой книги
CREATE OR REPLACE PROCEDURE check_returned_book(
    p_book_id INT,
    p_librarian_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_librarian BOOLEAN;
    v_book_pages INT;
    v_reserved_pages INT;
BEGIN
    -- Проверка библиотекаря
    SELECT is_librarian
    INTO v_is_librarian
    FROM Users
    WHERE user_id = p_librarian_id;

    IF NOT v_is_librarian THEN
        RAISE EXCEPTION 'Пользователь не является библиотекарем';
    END IF;

    -- Получаем количество страниц из Books
    SELECT page_count
    INTO v_book_pages
    FROM Books
    WHERE book_id = p_book_id;

    -- Получаем количество страниц из Books_reservation
    SELECT page_count
    INTO v_reserved_pages
    FROM Books_reservation
    WHERE book_id = p_book_id;

    IF v_book_pages = v_reserved_pages THEN
        -- Возврат принят
        CALL delete_reservation(p_book_id);
        CALL set_book_reserved_status(p_book_id, FALSE);
    ELSE
        RAISE EXCEPTION 'Возврат отклонён: количество страниц не совпадает';
    END IF;
END;
$$;

-- 1.3 Подарок книги
CREATE OR REPLACE PROCEDURE gift_book(
    p_name TEXT,
    p_author TEXT,
    p_publish_year INT,
    p_page_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL add_book(
        p_name,
        p_author,
        p_publish_year,
        p_page_count
    );
END;
$$;

-- =========================
-- TRIGGERS
-- =========================

-- Запрет прямого INSERT в Books_reservation
CREATE OR REPLACE FUNCTION trg_no_direct_insert_reservation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Прямой INSERT запрещён. Используйте процедуры';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER no_direct_insert_reservation
BEFORE INSERT ON Books_reservation
FOR EACH ROW
EXECUTE FUNCTION trg_no_direct_insert_reservation();
