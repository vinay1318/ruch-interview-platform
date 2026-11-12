# RUCH — Revision Consistency Design

## 1. Overview

RUCH (Read, Understand, Code, Hone) allows learners to revise previously learned questions and record a confidence score from 1 to 5.

Every successful revision submission must:

1. Create exactly one immutable revision-history record.
2. Update the latest revision state.
3. Increment the revision count exactly once.
4. Preserve consistency across all related database records.
5. Prevent duplicate submissions caused by HTTP retries.
6. Handle concurrent submissions without losing updates.
7. Respect current learning state and content publication eligibility.

This document defines the transaction boundaries, optimistic locking strategy, idempotency rules, and failure handling for the Revision module.

## 2. Final Architecture Decisions

RUCH adopts:

- **Option B: Optimistic locking** for concurrent revision-state updates.
- Spring Data JPA `@Version` for version-based conflict detection.
- MySQL InnoDB transactions.
- Immutable `revision_history` records.
- A separate `revision_state` table for the latest score and revision count.
- A `revision_idempotency` table to recognize retried submissions.
- Unique database constraints to protect first-time insert races.
- Bounded retries using new transactions.
- Transactional coordination between revision submissions and learning-state changes.
- No Kafka, Redis, or distributed locks for the MVP.

The database remains the authoritative source of truth.

## 3. Confidence Score

Each revision submission contains a confidence score between 1 and 5, inclusive.

| Score | Meaning |
|---|---|
| 1 | Very low confidence |
| 2 | Low confidence |
| 3 | Moderate confidence |
| 4 | High confidence |
| 5 | Very high confidence |

Scores represent learner self-assessment, not AI-generated correctness evaluation.

The backend rejects null, non-integer, or out-of-range scores.

Example request:

```json
{
  "questionId": 10,
  "score": 4
}
```

Java validation:

```java
public record SubmitRevisionRequest(
    @NotNull @Positive Long questionId,
    @NotNull @Min(1) @Max(5) Integer score
) {}
```

The database also enforces a score range of 1–5.

## 4. Revision Data Model

### 4.1 revision_history

Stores every successfully committed revision attempt.

Key fields:

- `id`
- `user_id`
- `question_id`
- `score`
- `attempt_number`
- `submitted_at`

Each row represents one logical revision submission.

Revision-history records are immutable through application services.

`attempt_number` is a positive, monotonically increasing sequence within each `(user_id, question_id)` pair.

The attempt number also allows the original response to be reconstructed when an idempotent request is replayed after later submissions.

Recommended constraints:

```sql
UNIQUE (user_id, question_id, attempt_number)
```

The existing history indexes from Ticket 11 remain applicable.

### 4.2 revision_state

Stores the current revision summary for a learner/question pair.

Key fields:

- `id`
- `user_id`
- `question_id`
- `latest_score`
- `revision_count`
- `last_revised_at`
- `version`

The `version` column is used for optimistic locking.

Example:

| user_id | question_id | latest_score | revision_count | version |
|---|---|---|---|---|
| 101 | 10 | 4 | 3 | 2 |

There is at most one revision-state row per learner/question pair.

### 4.3 revision_idempotency

Stores the association between a logical request and its committed revision attempt.

Key fields:

- `id`
- `user_id`
- `idempotency_key`
- `request_hash`
- `revision_history_id`
- `created_at`

The existing Ticket 11 uniqueness constraints remain:

```sql
UNIQUE (user_id, idempotency_key)
```

and:

```sql
UNIQUE (revision_history_id)
```

A successful idempotency record references exactly one committed revision-history record.

## 5. Required Database Schema Changes

Ticket 11 established the initial schema.

Ticket 14 adds two fields:

```sql
ALTER TABLE revision_state
ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
```

```sql
ALTER TABLE revision_history
ADD COLUMN attempt_number BIGINT NULL;
```

For a new database, `attempt_number` should be defined as `BIGINT NOT NULL` with a positive-value constraint and a composite unique constraint.

For an existing populated database, migrate in stages:

1. Add the nullable column.
2. Backfill attempt numbers in deterministic order by `submitted_at, id`, partitioned by `(user_id, question_id)`.
3. Validate that all rows have positive attempt numbers.
4. Add the composite unique constraint.
5. Change the column to `NOT NULL`.

The migration must preserve existing revision records.

These changes should be included in the appropriate Flyway migration rather than applied manually to production.

## 6. Revision State Invariants

For each learner/question pair, after every successfully committed transaction:

1. `revision_count` equals the number of committed revision-history rows.
2. `latest_score` equals the score of the highest committed `attempt_number`.
3. `last_revised_at` equals the submission timestamp of that latest attempt.
4. Attempt numbers are unique and sequential, starting at 1.
5. Every successful logical submission adds exactly one history row.
6. Retrying an already committed logical submission does not add another row.
7. A failed transaction leaves no partial revision-history, state, or idempotency changes.

For a question with no revision history, no `revision_state` row is required.

## 7. Revision Submission Eligibility

A revision is accepted only if:

- The request is authenticated.
- The authenticated user has the LEARNER role.
- The question exists.
- The question is PUBLISHED.
- Its parent chapter is PUBLISHED.
- The learner currently has `is_learned = true` for that question.
- The confidence score is valid.

The user ID is obtained from Spring Security, not from the request body.

The backend must revalidate eligibility within the transaction that commits the revision.

A request must not rely solely on eligibility checks performed before entering the transaction.

## 8. Optimistic Locking with JPA

The revision-state entity uses `@Version`.

```java
@Entity
@Table(name = "revision_state")
public class RevisionState {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "question_id", nullable = false)
    private Long questionId;

    @Column(name = "latest_score", nullable = false)
    private Integer latestScore;

    @Column(name = "revision_count", nullable = false)
    private Long revisionCount;

    @Column(name = "last_revised_at", nullable = false)
    private LocalDateTime lastRevisedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;
}
```

The entity mapping must also retain the existing uniqueness and foreign-key constraints defined in Ticket 11.

When an existing entity is updated, Hibernate checks the expected version.

Conceptual SQL:

```sql
UPDATE revision_state
SET latest_score = 5,
    revision_count = 4,
    version = 3
WHERE id = 100
  AND version = 2;
```

If another transaction has already changed the version, the update affects zero rows.

Hibernate reports an optimistic locking conflict.

The failed transaction must roll back.

The application must not attempt to continue using the same failed persistence context.

## 9. Transaction Boundary

Each new logical revision submission runs inside one database transaction.

The transaction includes:

1. Resolve authenticated learner identity.
2. Validate current question and chapter publication eligibility.
3. Validate the learner's current learned state.
4. Claim the idempotency key.
5. Load or create the revision-state record.
6. Calculate the next attempt number.
7. Insert the immutable revision-history record.
8. Update revision state.
9. Associate the idempotency record with the history record.
10. Flush changes and commit.

The transaction must provide all-or-nothing behavior.

Example:

```java
@Transactional
public RevisionResponse submitOnce(
        Long userId,
        SubmitRevisionRequest request,
        UUID idempotencyKey
) {
    // Validate current eligibility
    // Claim idempotency key
    // Load revision state
    // Insert history
    // Update latest state
    // Associate idempotency record
    // Flush and return
}
```

This is an architectural outline, not a complete implementation.

The transaction is successful only after the database commit succeeds.

## 10. Revision Count Behavior

The first successful revision creates:

```text
revision_count = 1
attempt_number = 1
```

Each subsequent successful new submission increments the count by one.

Example:

| Submission | Score | Attempt number | Revision count |
|---|---|---|---|
| First | 2 | 1 | 1 |
| Second | 4 | 2 | 2 |
| Third | 3 | 3 | 3 |

A duplicate request with the same idempotency key does not increment the count.

A new request with a new idempotency key creates a new attempt, even if its score matches an earlier attempt.

Unlearning, archiving, or temporarily unpublishing a question does not reset the revision count.

## 11. Duplicate Submission Strategy

### 11.1 Idempotency Key

Each intentional revision submission uses a client-generated UUID.

Example:

```http
POST /api/v1/revision/attempts
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```

The Angular frontend generates a new key for each intentional submission.

It reuses the same key when retrying that submission after a timeout or uncertain network result.

### 11.2 Request Fingerprint

The backend calculates a deterministic request hash from the canonical logical request:

```text
HTTP method
API operation
questionId
score
```

The authenticated user is separately part of the idempotency-key scope.

Canonicalization must be stable so semantically identical requests generate the same hash.

### 11.3 Duplicate Rules

| Scenario | Behavior |
|---|---|
| New key, valid request | Create revision |
| Same key, same payload, already committed | Return original result |
| Same key, different payload | 409 Conflict |
| Different key, same score | Create a new attempt |
| Same key while first transaction is pending | Wait for resolution or return retryable in-progress response |
| First transaction rolled back | Allow a safe retry |

The unique constraint on `(user_id, idempotency_key)` is the final protection against duplicate key claims.

### 11.4 Original Response Reconstruction

For a committed duplicate request, the backend retrieves the original history record.

The response uses the original:

- Revision-history ID.
- Question ID.
- Score.
- Attempt number.
- Submission timestamp.

The attempt number represents the revision count immediately after that original submission.

It must not be replaced with the current count after later submissions.

If the response contract includes additional derived fields, those fields must either be reconstructed from immutable attempt data or preserved in a response snapshot.

### 11.5 Retention

The MVP targets a 30-day idempotency-key retention period.

Cleanup must not delete revision history or revision state.

After a key expires and its record is deleted, the backend can no longer guarantee duplicate recognition for that old key.

The API contract must communicate this retention boundary.

## 12. Concurrent Submission Strategy

### 12.1 Existing Revision State

Suppose the current state is:

```text
revision_count = 3
version = 2
```

Two requests arrive with different idempotency keys.

Both read version 2.

Request A successfully updates the state to:

```text
revision_count = 4
version = 3
```

Request B attempts to update using version 2.

Its update fails with an optimistic locking conflict.

Request B's entire transaction rolls back, including its attempted history and idempotency writes.

The backend retries Request B in a new transaction.

It reloads the latest state:

```text
revision_count = 4
version = 3
```

It then commits:

```text
revision_count = 5
version = 4
```

The resulting database contains five committed history records and a revision count of five.

### 12.2 First-Time Revision Race

Optimistic locking cannot detect a version conflict on a row that does not yet exist.

Two first-time revisions might both attempt to insert the same `(user_id, question_id)` revision-state record.

The unique constraint prevents duplicate committed state rows.

The losing transaction rolls back and may retry in a new transaction.

The retry loads the state created by the winning transaction.

The resulting attempt numbers are 1 and 2.

### 12.3 Retry Limits

RUCH uses bounded retries.

Recommended MVP policy:

- Maximum three total transaction attempts.
- Short randomized backoff between attempts.
- Retry only recognized transient concurrency failures.
- Do not retry invalid scores, authorization failures, or idempotency payload conflicts.
- Do not retry indefinitely.

If the retry limit is exhausted, return a retryable conflict response with an appropriate error code and preserve the original idempotency key for the client's retry.

### 12.4 Transaction Isolation

Use MySQL InnoDB with an explicitly documented transaction isolation strategy.

For optimistic retries, each retry must obtain a fresh transactional view of the relevant records.

The implementation must account for MySQL's default REPEATABLE READ isolation and ensure retries begin in new transactions.

READ COMMITTED is an acceptable choice for the revision submission transaction if verified against the chosen persistence and locking strategy.

Isolation level does not replace version checks, unique constraints, or transactional eligibility validation.

## 13. Coordination with Learning-State Changes

Ticket 13 allows learners to mark questions learned and unlearned.

A revision must not commit against an invalid learning state.

Optimistic locking on `revision_state` alone cannot detect an unlearn operation because the unlearn operation updates a different table.

RUCH therefore extends optimistic concurrency control to `user_question_progress`.

Add:

```sql
ALTER TABLE user_question_progress
ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
```

Map the new column with JPA `@Version`.

A revision transaction must participate in a version-checked update of the progress row, even though it does not change the learned flag.

For example, the service can use JPA's optimistic force-increment lock mode:

```java
entityManager.lock(
    progress,
    LockModeType.OPTIMISTIC_FORCE_INCREMENT
);
```

The service must verify the progress row is currently learned and that the content is eligible.

The forced version increment must be flushed and validated before the transaction is considered successful.

A competing unlearn operation must update the same versioned progress entity.

If the operations conflict, one transaction rolls back.

On retry, revision eligibility is checked again.

If the learner is now unlearned, the revision is rejected.

This prevents a revision from silently committing based on a stale learned-state snapshot.

## 14. Coordination with Publication Changes

Publication eligibility also depends on the question and its chapter.

A simple read of their status is insufficient if an administrator can concurrently unpublish either record.

For a strict guarantee that revisions cannot commit after a conflicting unpublish has committed, publication changes and revision submissions need a shared concurrency protocol.

RUCH should version the relevant content entities or use an equivalent database-enforced coordination mechanism.

The chosen implementation must ensure:

- Revision submission validates the question and chapter status.
- Concurrent unpublishing is detected.
- A revision cannot commit based on stale publication eligibility.
- A failed revision rolls back its history, state, and idempotency changes.
- A retry rechecks publication eligibility.

If JPA optimistic force-increment is used for content eligibility, administrative publication updates must participate in the same version-checking protocol.

This coordination must be tested with real MySQL transactions rather than assumed from ordinary unit tests.

## 15. Retry Transaction Architecture

Retries must happen outside the transaction being retried.

A recommended structure is:

```text
RevisionController
       |
       v
RevisionSubmissionCoordinator
       |
       | bounded retry loop
       v
RevisionTransactionalService
       |
       | @Transactional
       v
Repositories / EntityManager
```

The coordinator calls a separate Spring-managed transactional service.

Example:

```java
public RevisionResponse submitWithRetry(
        Long userId,
        SubmitRevisionRequest request,
        UUID idempotencyKey
) {
    for (int attempt = 1; attempt <= 3; attempt++) {
        try {
            return transactionalService.submitOnce(
                userId,
                request,
                idempotencyKey
            );
        } catch (OptimisticLockingFailureException ex) {
            if (attempt == 3) {
                throw ex;
            }
            backoff(attempt);
        }
    }

    throw new IllegalStateException("Unreachable");
}
```

This example demonstrates the retry boundary only.

Production code must also handle recognized unique-constraint races and transient database failures, distinguish them from permanent conflicts, and ensure transaction commit exceptions are observed by the coordinator.

Do not implement retries through self-invocation of another `@Transactional` method on the same Spring bean.

## 16. API Response

A successful new revision returns HTTP `201 Created`.

Example:

```json
{
  "revisionId": 501,
  "questionId": 10,
  "score": 4,
  "revisionCount": 3,
  "submittedAt": "2026-11-11T20:30:00Z"
}
```

A successful idempotent replay returns the original logical result.

For the MVP, use HTTP `200 OK` for replay while preserving the original response body.

The `revisionCount` field represents the attempt number for that submission, not necessarily the current revision count.

### Error Cases

| Situation | HTTP status | Error code |
|---|---|---|
| Score outside 1–5 | 400 | `VALIDATION_ERROR` |
| User not authenticated | 401 | `UNAUTHORIZED` |
| User lacks learner permission | 403 | `FORBIDDEN` |
| Question unavailable | 404 | `QUESTION_NOT_FOUND` |
| Question not learned | 409 | `QUESTION_NOT_LEARNED` |
| Same idempotency key, different payload | 409 | `IDEMPOTENCY_KEY_CONFLICT` |
| Request still processing | 409 | `REVISION_REQUEST_IN_PROGRESS` |
| Retry limit exhausted | 409 | `REVISION_CONCURRENCY_CONFLICT` |

The existing structured error contract from Ticket 10 applies.

## 17. Failure Handling

### History Insert Fails

The entire transaction rolls back.

No revision-state update is committed.

### State Update Fails

The entire transaction rolls back.

The attempted history insert is not committed.

### Idempotency Write Fails

The entire transaction rolls back.

No partial revision is committed.

### Optimistic Lock Conflict

The transaction rolls back.

The coordinator may retry the complete logical submission in a new transaction.

### Client Timeout After Commit

The client retries with the same idempotency key.

The backend returns the original successful result without inserting another revision.

### Unlearning During Submission

The version-checking protocol determines which transaction can commit.

A conflicting revision is retried and eligibility is revalidated.

### Question Unpublished During Submission

The publication concurrency protocol detects conflicting changes.

A retry must recheck content eligibility.

## 18. Angular Frontend Responsibilities

The frontend must:

1. Require an explicit confidence score selection.
2. Generate a UUID for each new logical revision.
3. Send the UUID using the `Idempotency-Key` header.
4. Reuse that UUID for network retries of the same submission.
5. Disable duplicate submission while a request is pending.
6. Display the server-confirmed score and revision count.
7. Handle retryable concurrency errors appropriately.
8. Avoid generating a new key merely because a response timed out.
9. Generate a new key for the next intentional revision attempt.
10. Never send or persist optional typed recall notes as part of the revision payload.

The backend remains responsible for correctness even if frontend protections fail.

## 19. Testing Strategy

### Score Validation

- Accept scores 1–5.
- Reject 0, 6, null, and non-integer values.

### History and State

- First submission creates history and state.
- Subsequent submission increments count.
- Latest score matches latest committed attempt.
- History remains immutable.
- Failed writes roll back together.

### Idempotency

- Same key and payload creates one attempt.
- Same key with different payload returns conflict.
- New key creates a new attempt.
- Replay after later submissions returns original attempt metadata.
- Concurrent requests with the same key do not create duplicate attempts.

### Optimistic Locking

- Concurrent updates detect stale versions.
- Failed transactions roll back.
- Retries use fresh transactions.
- Successful retries preserve correct revision counts.
- First-time insert races are handled through uniqueness constraints.

### Learning-State Coordination

- Unlearned questions cannot be revised.
- Concurrent unlearn and revision cannot bypass eligibility rules.
- Relearning preserves previous revision history.

### Publication Coordination

- Draft questions cannot be revised.
- Archived questions cannot be revised.
- Unpublished chapters prevent revision.
- Concurrent unpublish and revision respect the shared concurrency protocol.
- Republishing restores revision eligibility for previously learned questions.

### Database Integration Tests

Use integration tests against MySQL with actual concurrent transactions.

In-memory databases alone are insufficient to validate the intended MySQL locking and isolation behavior.

## 20. Acceptance Criteria Verification

| Acceptance criterion | Design decision |
|---|---|
| Confidence score range 1–5 defined | Validated by Java and database constraints |
| Latest score stored separately from history | `revision_state` and `revision_history` |
| Revision count behavior defined | One increment per committed logical submission |
| Transaction boundary documented | One transaction for eligibility, idempotency, history, and state |
| Duplicate submission strategy defined | UUID idempotency keys and database uniqueness |
| Concurrent submission strategy documented | JPA optimistic locking, bounded retries, and first-insert conflict handling |

## 21. Final Decision Summary

RUCH uses optimistic concurrency control for revision submissions.

The core guarantees are:

1. Each successful logical revision produces one history record.
2. Latest revision state remains consistent with history.
3. Revision counts never lose committed attempts.
4. Duplicate HTTP retries do not create duplicate revisions.
5. Optimistic version checks detect conflicting state updates.
6. Unique constraints handle first-time insert races.
7. Retries occur in fresh transactions.
8. Learning-state and publication changes participate in eligibility concurrency control.
9. Failed transactions leave no partial writes.
10. Historical revision records remain intact after unlearning, archival, or unpublishing.

This design provides a production-oriented foundation for RUCH while allowing practical learning of Spring Data JPA optimistic locking, transaction management, idempotency, and concurrency testing.
