# RUCH — Database Schema Design

## 1. Overview

RUCH (Read. Understand. Code. Hone.) is a chapter-based technical learning and revision platform built using:

- Java 21
- Spring Boot
- Spring Security
- Spring Data JPA
- MySQL
- Flyway
- Angular and TypeScript

This document defines the initial relational database schema, table relationships, primary keys, foreign keys, unique constraints, indexes, and data integrity rules.

The design supports approximately 100 initial users and the MVP requirements established in earlier tickets.

The database must support:

1. Administrator-managed chapters and questions.
2. Shared educational content.
3. Private learner-specific progress.
4. Explicit learned and not-learned states.
5. Multiple revision attempts per learner/question.
6. Efficient retrieval of latest revision metadata.
7. Preservation of revision history.
8. Content publication and archival.
9. Authentication and refresh-token persistence.
10. Idempotent revision submissions.
11. Reliable analytics calculations.

## 2. Database Design Principles

### 2.1 Shared Content, Private Progress

Chapters and questions are shared across learners.

Learning progress, revision state, and revision history belong to individual learners.

For example, two learners may study the same question but have different learning statuses and revision scores.

Therefore, learner-specific attributes must not be stored in the shared `questions` table.

### 2.2 Data Integrity

Database constraints enforce essential integrity rules.

These include:

- Primary keys for row identity.
- Foreign keys for referential integrity.
- Unique constraints for duplicate prevention.
- Check constraints for valid enumerated states and score ranges.
- Transactions for multi-table updates.

Business validation in Spring Boot complements these constraints.

### 2.3 Historical Preservation

Revision history is append-only during normal application operation.

Archiving or unpublishing a chapter or question does not delete previous learning or revision records.

### 2.4 Schema Evolution

Flyway manages all schema changes.

Production schema changes must be implemented through versioned migrations rather than manual database modifications.

## 3. Table Inventory

### 3.1 Core Tables

| Table | Purpose |
|---|---|
| `users` | Registered accounts and roles |
| `chapters` | Shared chapter catalog |
| `questions` | Shared questions and reference answers |
| `user_question_progress` | Current learner/question learning state |
| `revision_state` | Latest revision score and aggregate count |
| `revision_history` | Individual historical revision attempts |

### 3.2 Supporting Tables

| Table | Purpose |
|---|---|
| `auth_refresh_tokens` | Refresh-token rotation, expiry, and revocation |
| `revision_idempotency` | Prevents duplicate revision submissions |

These supporting tables are necessary to fulfill the authentication and idempotency behavior defined in earlier architecture tickets.

The MVP therefore has **eight initial tables**, including the six required core tables.

## 4. Relationship Model

The primary relationships are:

| Parent | Child | Cardinality |
|---|---|---|
| `chapters` | `questions` | One-to-many |
| `users` | `user_question_progress` | One-to-many |
| `questions` | `user_question_progress` | One-to-many |
| `user_question_progress` | `revision_state` | One-to-zero-or-one |
| `user_question_progress` | `revision_history` | One-to-many |
| `users` | `auth_refresh_tokens` | One-to-many |
| `users` | `revision_idempotency` | One-to-many |
| `revision_history` | `revision_idempotency` | One-to-zero-or-many at the database level, with one successful submission key per attempt enforced by the application |

A learner/question pair is uniquely identified by the combination of `user_id` and `question_id`.

The same question may be associated with many learners.

A learner may have progress records for many questions.

## 5. Users Table

### 5.1 Purpose

Stores account information required for authentication and authorization.

### 5.2 Schema

```sql
CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_users_email
        UNIQUE (email),

    CONSTRAINT chk_users_role
        CHECK (role IN ('ADMIN', 'LEARNER'))
) ENGINE=InnoDB;
```

### 5.3 Column Definitions

| Column | Type | Description |
|---|---|---|
| `id` | BIGINT | Unique account identifier |
| `name` | VARCHAR(100) | Display name |
| `email` | VARCHAR(254) | Normalized login email |
| `password_hash` | VARCHAR(255) | Password hash |
| `role` | VARCHAR(20) | ADMIN or LEARNER |
| `created_at` | DATETIME(6) | Account creation |
| `updated_at` | DATETIME(6) | Last account update |

### 5.4 Rules

- Email addresses must be unique.
- Emails are normalized consistently before storage and lookup.
- Public registration always creates a `LEARNER`.
- Administrator accounts are provisioned through a controlled process.
- Passwords are hashed using the configured Spring Security password encoder.
- Password hashes are never returned through the API.
- Accounts with dependent learning history must not be casually hard-deleted.

The database collation and application normalization policy must agree on email equality behavior.

## 6. Chapters Table

### 6.1 Purpose

Stores the administrator-managed chapter catalog.

### 6.2 Schema

```sql
CREATE TABLE chapters (
    id BIGINT NOT NULL AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    description VARCHAR(2000) NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT chk_chapters_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),

    CONSTRAINT chk_chapters_title
        CHECK (CHAR_LENGTH(TRIM(title)) > 0)
) ENGINE=InnoDB;
```

### 6.3 Lifecycle

A chapter may be:

- `DRAFT`: Not visible to learners.
- `PUBLISHED`: Eligible for learner visibility.
- `ARCHIVED`: Excluded from active learner content.

Restoring an archived chapter returns it to `DRAFT`.

Unpublishing a published chapter also returns it to `DRAFT`.

### 6.4 Rules

- Chapter titles must not be blank.
- Chapter titles are not required to be globally unique in the MVP.
- The administrator manages chapter creation and lifecycle.
- Archiving preserves the chapter row and related questions.
- Historical learner records remain intact.
- Active learner queries include only published chapters.

## 7. Questions Table

### 7.1 Purpose

Stores questions and reference answers associated with chapters.

### 7.2 Schema

```sql
CREATE TABLE questions (
    id BIGINT NOT NULL AUTO_INCREMENT,
    chapter_id BIGINT NOT NULL,
    question_number INT NOT NULL,
    question_text VARCHAR(2000) NOT NULL,
    reference_answer TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT fk_questions_chapter
        FOREIGN KEY (chapter_id)
        REFERENCES chapters(id)
        ON DELETE RESTRICT,

    CONSTRAINT uk_questions_chapter_number
        UNIQUE (chapter_id, question_number),

    CONSTRAINT chk_questions_number
        CHECK (question_number > 0),

    CONSTRAINT chk_questions_status
        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),

    CONSTRAINT chk_questions_text
        CHECK (CHAR_LENGTH(TRIM(question_text)) > 0),

    CONSTRAINT chk_questions_answer
        CHECK (CHAR_LENGTH(TRIM(reference_answer)) > 0)
) ENGINE=InnoDB;
```

### 7.3 Important Constraints

**Foreign key**

```sql
FOREIGN KEY (chapter_id)
REFERENCES chapters(id)
```

Prevents questions from referencing nonexistent chapters.

**Composite unique constraint**

```sql
UNIQUE (chapter_id, question_number)
```

Ensures that question numbers are unique within a chapter.

Example:

| chapter_id | question_number | Allowed? |
|---|---|---|
| 1 | 1 | Yes |
| 1 | 2 | Yes |
| 2 | 1 | Yes |
| 1 | 1 again | No |

### 7.4 Question Ordering

Questions are ordered by `question_number`.

The administrator assigns the number when creating a question.

The backend validates positive numbering and uniqueness.

Archiving does not release the number.

Renumbering is permitted through a controlled administrative operation that respects the unique constraint.

### 7.5 Publication Rules

A question is learner-visible only when:

```text
questions.status = PUBLISHED
AND
chapters.status = PUBLISHED
```

The database foreign key guarantees chapter existence but does not enforce this cross-table publication rule.

The Spring Boot service layer must enforce publication eligibility.

### 7.6 API Contract Alignment

Because question numbering is now explicitly defined in the database, the question creation and update DTOs from Ticket 10 must include a positive `questionNumber` field.

This is a small contract refinement that should be reflected in the Ticket 10 document before implementation.

## 8. User Question Progress Table

### 8.1 Purpose

Stores each learner's current learned/not-learned state for a question.

### 8.2 Schema

```sql
CREATE TABLE user_question_progress (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    is_learned BOOLEAN NOT NULL DEFAULT FALSE,
    learned_at DATETIME(6) NULL,
    updated_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_progress_user_question
        UNIQUE (user_id, question_id),

    CONSTRAINT fk_progress_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_progress_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_progress_learned_at
        CHECK (
            (is_learned = TRUE AND learned_at IS NOT NULL)
            OR
            (is_learned = FALSE AND learned_at IS NULL)
        )
) ENGINE=InnoDB;
```

### 8.3 Uniqueness

The combination:

```sql
UNIQUE (user_id, question_id)
```

ensures that one learner cannot have conflicting current progress rows for the same question.

### 8.4 Learning Rules

When a learner marks a question as learned:

```text
is_learned = TRUE
learned_at = current UTC timestamp
```

When a learner marks a question as not learned:

```text
is_learned = FALSE
learned_at = NULL
```

When a learner marks an already learned question as learned again, the existing timestamp remains unchanged.

Relearning after an unlearn transition starts a new learned period.

The previous revision history is retained.

### 8.5 Initial State

An absent progress row means that the learner has never explicitly established progress for that question.

The API represents this as:

```json
{
  "isLearned": false,
  "learnedAt": null
}
```

The application creates a progress row when needed.

This avoids creating unnecessary progress rows for every learner/question combination.

## 9. Revision State Table

### 9.1 Purpose

Stores the latest revision score and aggregate revision metadata for each learner/question pair.

### 9.2 Schema

```sql
CREATE TABLE revision_state (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    latest_score TINYINT NOT NULL,
    revision_count BIGINT NOT NULL,
    last_revised_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_revision_state_user_question
        UNIQUE (user_id, question_id),

    CONSTRAINT fk_revision_state_progress
        FOREIGN KEY (user_id, question_id)
        REFERENCES user_question_progress(user_id, question_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_revision_state_score
        CHECK (latest_score BETWEEN 1 AND 5),

    CONSTRAINT chk_revision_state_count
        CHECK (revision_count > 0)
) ENGINE=InnoDB;
```

### 9.3 Example

| user_id | question_id | latest_score | revision_count |
|---|---|---|---|
| 101 | 10 | 5 | 3 |
| 102 | 10 | 2 | 1 |
| 101 | 11 | 4 | 2 |

### 9.4 Rules

- A revision-state row is created after the first successful revision.
- Only one revision-state row exists per learner/question pair.
- The latest score is between 1 and 5.
- Revision count must be positive.
- The latest score and count are updated after successful revision submissions.
- Marking a question as not learned does not delete its revision state.

The state is a derived summary of revision history.

The database does not automatically guarantee that its count and latest score match the history table; the application must maintain that invariant transactionally.

## 10. Revision History Table

### 10.1 Purpose

Stores the immutable history of revision attempts.

### 10.2 Schema

```sql
CREATE TABLE revision_history (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    question_id BIGINT NOT NULL,
    score TINYINT NOT NULL,
    submitted_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT fk_revision_history_progress
        FOREIGN KEY (user_id, question_id)
        REFERENCES user_question_progress(user_id, question_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_revision_history_score
        CHECK (score BETWEEN 1 AND 5),

    INDEX idx_revision_history_lookup
        (user_id, question_id, submitted_at DESC, id DESC)
) ENGINE=InnoDB;
```

### 10.3 Example

| id | user_id | question_id | score |
|---|---|---|---|
| 501 | 101 | 10 | 2 |
| 502 | 101 | 10 | 3 |
| 503 | 101 | 10 | 5 |

### 10.4 Rules

- Every successful new revision creates one history row.
- History is not overwritten by later attempts.
- The same learner may revise the same question repeatedly.
- No unique constraint is placed on `(user_id, question_id)` in history.
- History is preserved when questions or chapters are archived.
- The application must prevent ordinary modification or deletion of historical attempts.
- Revision history is ordered by submission time and ID for deterministic retrieval.

Database permissions and service design should restrict unintended updates to historical records.

## 11. Revision Transaction and Concurrency

A revision submission affects multiple tables.

The operation must be atomic.

### 11.1 Transaction Flow

1. Resolve the authenticated learner ID.
2. Validate the request and idempotency key.
3. Lock or safely establish the learner/question progress row.
4. Verify that the question is currently eligible for revision.
5. Check whether the idempotency key has already been processed.
6. Insert a new revision-history record.
7. Create or update the corresponding revision-state record.
8. Associate the idempotency record with the result.
9. Commit the transaction.

If any operation fails, the transaction rolls back.

### 11.2 Concurrent Requests

Two different revision requests may arrive simultaneously for the same learner/question pair.

The backend must serialize conflicting state updates or use an equivalent safe concurrency strategy.

A practical MVP strategy is to use a transaction and row-level locking on the progress record.

All learning-state transitions and revision submissions must follow compatible locking rules.

This prevents a revision from being committed against an invalid learning state during a concurrent unlearn operation.

### 11.3 Latest Revision Semantics

The latest revision is the most recently committed valid attempt according to the application's serialized update order.

The implementation must ensure the latest-score summary and revision count remain consistent with successful history insertions.

### 11.4 Recovery

If a consistency issue is discovered, `revision_state` can be rebuilt from `revision_history` using an administrative reconciliation process.

History remains the authoritative record of attempts.

## 12. Authentication Refresh Tokens

### 12.1 Purpose

Stores hashed refresh tokens and supports secure token rotation and revocation.

### 12.2 Schema

```sql
CREATE TABLE auth_refresh_tokens (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    token_hash CHAR(64)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    family_id CHAR(36)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    expires_at DATETIME(6) NOT NULL,
    revoked_at DATETIME(6) NULL,
    created_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_refresh_token_hash
        UNIQUE (token_hash),

    CONSTRAINT fk_refresh_token_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    INDEX idx_refresh_token_user (user_id),
    INDEX idx_refresh_token_family (family_id),
    INDEX idx_refresh_token_expiry (expires_at)
) ENGINE=InnoDB;
```

### 12.3 Rules

- Raw refresh tokens are never stored in the database.
- A cryptographic hash of each refresh token is stored.
- Tokens expire after the configured lifetime.
- Refresh rotates the credential and revokes the previous token.
- A token family identifies related rotated credentials.
- Reuse of a revoked token triggers token-family invalidation according to the authentication security policy.
- Expired and revoked token records are periodically cleaned up after an appropriate retention period.

The exact token hash algorithm, family invalidation procedure, and cleanup retention will be finalized during authentication implementation.

## 13. Revision Idempotency Table

### 13.1 Purpose

Prevents duplicate revision attempts caused by retries, repeated button clicks, or network failures.

### 13.2 Schema

```sql
CREATE TABLE revision_idempotency (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    idempotency_key CHAR(36)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    request_hash CHAR(64)
        CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    revision_history_id BIGINT NULL,
    created_at DATETIME(6) NOT NULL,

    PRIMARY KEY (id),

    CONSTRAINT uk_revision_idempotency_user_key
        UNIQUE (user_id, idempotency_key),

    CONSTRAINT uk_revision_idempotency_history
        UNIQUE (revision_history_id),

    CONSTRAINT fk_revision_idempotency_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_revision_idempotency_history
        FOREIGN KEY (revision_history_id)
        REFERENCES revision_history(id)
        ON DELETE RESTRICT,

    INDEX idx_revision_idempotency_created
        (created_at)
) ENGINE=InnoDB;
```

### 13.3 Rules

- Every revision submission requires an idempotency key.
- The key is scoped to the authenticated learner and revision-submission operation.
- Reusing the same key with the same payload returns the original successful result.
- Reusing the same key with a different payload returns `409 Conflict`.
- A different key represents a separate logical revision attempt.
- A completed idempotency record references the resulting history row.
- Incomplete records are not treated as successful submissions.
- Idempotency-key reservation and revision persistence must use one atomic transaction.

### 13.4 Retention Policy

The MVP must define a minimum idempotency retention window before implementation.

Within that window, replay behavior is guaranteed.

After a key is purged, the system may treat it as new.

Cleanup must not delete revision history.

A candidate default is 30 days, subject to final operational review.

## 14. Indexing Strategy

Indexes are chosen according to expected query patterns.

| Table | Index | Query |
|---|---|---|
| `users` | Unique email | Login and registration |
| `chapters` | Primary key | Chapter lookup |
| `questions` | Unique chapter + number | Chapter question ordering |
| `user_question_progress` | Unique user + question | Learner progress lookup |
| `revision_state` | Unique user + question | Previous revision metadata |
| `revision_history` | User + question + timestamp + ID | Revision history |
| `auth_refresh_tokens` | Token hash | Refresh-token lookup |
| `auth_refresh_tokens` | User ID | Account token management |
| `auth_refresh_tokens` | Family ID | Token-family revocation |
| `revision_idempotency` | Unique user + key | Retry deduplication |

Additional indexes should be introduced based on measured query plans rather than added speculatively.

The question chapter/number unique index also supports chapter-scoped ordering.

The MySQL query optimizer should be evaluated using `EXPLAIN` when performance testing begins.

## 15. Deletion and Archival Strategy

### 15.1 Chapters

Administrators archive chapters rather than physically deleting them.

Archived chapters are excluded from active learner content and analytics.

Their questions and associated learner history remain stored.

### 15.2 Questions

Administrators archive questions rather than physically deleting them.

Archived questions are excluded from active learning and revision workflows.

Existing progress and revision history remain intact.

### 15.3 Foreign-Key Behavior

Foreign keys use restrictive deletion behavior.

No cascading deletion is permitted from shared content into learner history.

This protects historical data from accidental administrative deletion.

### 15.4 Restore Behavior

Restoring an archived chapter or question returns it to `DRAFT`.

An administrator must explicitly republish the content.

Previous learning progress and revision history remain associated with the restored records.

## 16. Analytics Data Sources

Analytics are derived from the core relational tables.

| Metric | Main tables |
|---|---|
| Total published questions | `chapters`, `questions` |
| Learned questions | `user_question_progress`, `questions`, `chapters` |
| Revision coverage | `user_question_progress`, `revision_state`, published content |
| Knowledge strength | `user_question_progress`, `revision_state`, published content |
| Weak questions | `revision_state`, `questions`, `chapters`, `user_question_progress` |

The MVP does not require a separate analytics aggregation table.

### 16.1 Learning Completion

```text
Currently learned published questions
------------------------------------- × 100
Total published questions
```

### 16.2 Revision Coverage

```text
Currently learned questions with revision history
------------------------------------------------- × 100
Currently learned questions
```

### 16.3 Knowledge Strength

```text
Sum of latest scores for currently learned questions
---------------------------------------------------- × 100
Currently learned questions × 5
```

Unrevised learned questions contribute zero to knowledge strength.

Only questions currently eligible under the published-content rules contribute to active analytics.

If a denominator is zero, the API returns `null` for that percentage.

## 17. Database Configuration

### 17.1 Database Engine

MySQL 8.0.16 or later, using InnoDB.

This supports transactional operations, foreign keys, and enforced CHECK constraints.

### 17.2 Character Set

Use:

```sql
CREATE DATABASE ruch
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
```

Migration scripts should explicitly preserve the intended character set and collation.

### 17.3 Timestamps

Store timestamps in UTC using `DATETIME(6)`.

The application is responsible for consistently converting Java `Instant` values to UTC database timestamps.

The database and JDBC session timezone configuration must be tested.

### 17.4 Identifier Strategy

Use:

```sql
BIGINT AUTO_INCREMENT
```

for primary keys.

Identifiers are generated by MySQL and are not accepted from creation request bodies.

### 17.5 Schema Migrations

Flyway will manage database migrations.

The initial migration will be stored under:

```text
src/main/resources/db/migration/
```

A candidate migration filename is:

```text
V1__create_initial_schema.sql
```

The final migration must create tables in foreign-key dependency order and include the selected indexes and constraints.

## 18. Schema Verification Tests

Database integration tests must verify the following.

### Users

- Duplicate normalized emails are rejected.
- Invalid roles are rejected.
- Password hashes are stored instead of plaintext passwords.

### Chapters

- Blank chapter titles are rejected.
- Invalid lifecycle states are rejected.
- Archival preserves chapter records.

### Questions

- Questions cannot reference nonexistent chapters.
- Question numbers are unique within a chapter.
- Question numbers must be positive.
- Invalid publication states are rejected.

### Learning Progress

- A learner/question pair cannot have duplicate progress rows.
- Different learners can have progress for the same question.
- One learner can track multiple questions.
- Learned timestamps match current learned state.

### Revision State

- One state record per learner/question pair.
- Scores are between 1 and 5.
- Revision count is positive.
- Revision state cannot reference a nonexistent progress pair.

### Revision History

- Multiple attempts per learner/question are allowed.
- Invalid scores are rejected.
- History is preserved after unlearning.
- History is preserved after archival.
- History cannot reference a nonexistent progress pair.

### Concurrency

- Simultaneous revisions do not lose count updates.
- Duplicate idempotency keys do not create duplicate attempts.
- Concurrent unlearning and revision submission respect the locking policy.
- Failed transactions do not leave partially updated state.

### Authentication

- Refresh-token hashes are unique.
- Token rotation and revocation are persisted.
- Token-family invalidation is supported.

## 19. Important Implementation Considerations

### 19.1 Database Constraints Are Not Sufficient Alone

A unique constraint prevents duplicate learner/question state rows, but it does not guarantee correct business behavior under every concurrent request.

Spring Boot transactions, locking, and service-level validation remain necessary.

### 19.2 Historical Records Must Remain Accessible

Archiving content must not destroy historical revision attempts.

Learner-facing active content queries and historical record queries have different eligibility rules.

### 19.3 Derived Revision State Must Remain Consistent

The application must never insert a successful revision-history row without updating its corresponding revision state in the same transaction.

### 19.4 PATCH Contracts Remain Separate from Persistence

The database schema does not determine which fields an API client may update.

Administrative PATCH operations must continue to enforce the request contracts established in Ticket 10.

### 19.5 Authentication Identity Is Server-Controlled

All learner-owned records must use the authenticated user ID resolved through Spring Security.

A client-supplied user ID must never determine ownership of progress or revision data.

## 20. Final Design Decisions

The RUCH MVP database uses:

1. MySQL with InnoDB.
2. Six core relational tables.
3. Two supporting tables for refresh tokens and idempotency.
4. BIGINT auto-generated primary keys.
5. Foreign keys for relational integrity.
6. Composite unique constraints for learner/question state.
7. Unique question numbering within chapters.
8. Separate immutable revision history and latest revision state.
9. Atomic revision transactions.
10. Row-level concurrency control for learner/question operations.
11. Content archival instead of hard deletion.
12. Restrictive foreign-key deletion behavior.
13. Preserved historical learning and revision data.
14. Indexes aligned with common query patterns.
15. UTC timestamp storage.
16. Flyway-managed schema migrations.
17. Backend-controlled learner identity.
18. Analytics derived from relational data without a separate analytics table.

This schema provides the initial persistence foundation for RUCH's authentication, chapter management, question management, learning progress, revision history, and learner analytics modules.