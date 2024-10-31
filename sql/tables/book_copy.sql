CREATE TABLE book_copy
(
    id      SERIAL
        PRIMARY KEY,
    branch  INTEGER  NOT NULL
        REFERENCES branch,
    book    CHAR(13) NOT NULL
        CONSTRAINT book_reference
            REFERENCES book,
    removed BOOLEAN DEFAULT FALSE
);