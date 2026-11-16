CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uk_users_email UNIQUE (email)
);

CREATE TABLE chapters (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_chapters PRIMARY KEY (id),
    CONSTRAINT uk_chapters_name UNIQUE (name)
);

CREATE TABLE questions (
    id BIGINT NOT NULL AUTO_INCREMENT,
    chapter_id BIGINT NOT NULL,
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_questions PRIMARY KEY (id),

    CONSTRAINT fk_questions_chapter
        FOREIGN KEY (chapter_id)
        REFERENCES chapters(id)
        ON DELETE RESTRICT
);