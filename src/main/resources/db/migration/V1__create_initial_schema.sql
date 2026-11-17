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

CREATE TABLE learning_progress (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    is_learned BOOLEAN NOT NULL DEFAULT FALSE,
    learned_at TIMESTAMP NULL,

    CONSTRAINT pk_learning_progress PRIMARY KEY (id),

    CONSTRAINT uk_learning_progress_user_question
        UNIQUE (user_id, question_id),

    CONSTRAINT fk_learning_progress_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_learning_progress_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE RESTRICT
);

CREATE TABLE revision_history (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    typed_answer TEXT,
    score TINYINT NOT NULL,
    revised_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_revision_history PRIMARY KEY (id),

    CONSTRAINT chk_revision_history_score
        CHECK (score BETWEEN 1 AND 5),

    CONSTRAINT fk_revision_history_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_revision_history_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE RESTRICT
);