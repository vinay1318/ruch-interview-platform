# RUCH — Learning State Rules

## 1. Overview

RUCH (Read. Understand. Code. Hone.) provides a chapter-based learning experience where learners explicitly track which interview questions they have learned.

This document defines the rules governing learning-state creation, transitions, persistence, idempotency, timestamps, ownership, and interaction with content publication status.

The learning-state design must ensure:

1. Reading a question never automatically marks it learned.
2. Marking a question as learned requires an explicit learner action.
3. Learning state belongs to an individual authenticated learner.
4. Duplicate marking requests are idempotent.
5. Learning timestamps have consistent semantics.
6. Unlearning and relearning are supported.
7. Unpublished and archived content retains historical learning state.
8. Active learning, revision, and analytics use publication eligibility rules.

## 2. Final Design Decisions

RUCH uses the following rules:

- A question is learned only after the learner explicitly selects **Mark as Learned**.
- Opening, reading, scrolling, revealing an answer, or spending time on a question does not modify learning state.
- Learning state is stored per authenticated user and question.
- Marking an already learned question as learned again does not change its timestamp.
- Learners can undo their learned status.
- Unlearning sets `is_learned = false` and `learned_at = NULL`.
- Relearning creates a new learned timestamp.
- Previous revision history and revision state are preserved after unlearning.
- Unpublishing or archiving content preserves existing learning state.
- Unpublished and archived content is excluded from active learner workflows and analytics.
- Republishing makes preserved learning state applicable again.

## 3. Learning State Model

RUCH supports two current learning states:

| State | Meaning |
|---|---|
| `NOT_LEARNED` | Learner has not currently marked the question learned |
| `LEARNED` | Learner has explicitly marked the question learned |

The database stores these using:

```sql
is_learned BOOLEAN NOT NULL DEFAULT FALSE,
learned_at DATETIME(6) NULL
```

No additional learning-state enum is required for the MVP.

### 3.1 Default State

A learner who has never interacted with a question has no corresponding progress row.

The application interprets an absent row as:

```json
{
  "isLearned": false,
  "learnedAt": null
}
```

Reading a question must not create a progress row.

### 3.2 Learned State

After a successful explicit Mark as Learned action:

```text
is_learned = true
learned_at = current UTC timestamp
```

### 3.3 Not-Learned State

After an explicit undo action:

```text
is_learned = false
learned_at = null
```

The progress record remains in the database.

## 4. Explicit Mark as Learned Action

The learner must explicitly trigger the action through the RUCH interface.

Example:

```text
Java Fundamentals

Question 10: What is polymorphism?

[Reference answer]

[Mark as Learned]
```

The Angular frontend sends a request only when the learner selects the button.

The backend must not infer learning completion from:

- Opening a question.
- Reading its reference answer.
- Scrolling through content.
- Navigating to another question.
- Time spent viewing content.
- Completing a chapter view.
- Returning to the application.
- Viewing a question in revision history.

Reading and learning-state mutation are separate operations.

## 5. Learning State Transitions

| Current state | Action | Resulting state | Timestamp behavior |
|---|---|---|---|
| NOT_LEARNED | Read | NOT_LEARNED | Remains null |
| NOT_LEARNED | Mark as Learned | LEARNED | Set current UTC time |
| LEARNED | Read | LEARNED | Unchanged |
| LEARNED | Mark as Learned | LEARNED | Preserve existing timestamp |
| LEARNED | Mark Not Learned | NOT_LEARNED | Set null |
| NOT_LEARNED | Mark Not Learned | NOT_LEARNED | Remains null |
| NOT_LEARNED after undo | Mark as Learned | LEARNED | Set new UTC time |

### 5.1 Repeated Marking

If the question is already learned, repeating the Mark as Learned action is a no-op.

The backend must not overwrite `learned_at`.

### 5.2 Repeated Unlearning

If the question is already not learned, repeating the undo action is a no-op.

No new progress record is necessary if the learner has never marked the question learned.

### 5.3 Relearning

After unlearning, a subsequent Mark as Learned action starts a new learned period.

The timestamp represents the beginning of the **current learned period**, not the first time the learner ever learned the question.

Previous revision records remain available.

## 6. Learned Timestamp Rules

### 6.1 Definition

`learned_at` records when the learner most recently transitioned from NOT_LEARNED to LEARNED.

It is not a record of every learning event.

### 6.2 Storage

Use MySQL:

```sql
DATETIME(6)
```

Store timestamps consistently in UTC.

### 6.3 Example

Initial state:

```json
{
  "questionId": 10,
  "isLearned": false,
  "learnedAt": null
}
```

After marking learned:

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-11T20:30:00Z"
}
```

Repeating Mark as Learned returns the same `learnedAt`.

After undo:

```json
{
  "questionId": 10,
  "isLearned": false,
  "learnedAt": null
}
```

After relearning:

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-12T09:15:00Z"
}
```

### 6.4 Timestamp Authority

The backend generates the learned timestamp.

The client cannot submit its own `learnedAt` value.

The backend must not trust browser time as the authoritative timestamp.

## 7. User-Specific State

Learning progress is owned by an authenticated learner.

The same shared question may have different learning states for different users.

Example:

| User ID | Question ID | Learned? |
|---|---|---|
| 101 | 10 | Yes |
| 102 | 10 | No |
| 103 | 10 | Yes |

These records are independent.

### 7.1 Database Constraint

The `user_question_progress` table uses:

```sql
CONSTRAINT uk_progress_user_question
    UNIQUE (user_id, question_id)
```

This guarantees at most one current progress row for each learner/question pair.

### 7.2 Identity Resolution

The backend obtains the learner ID from Spring Security's authenticated principal.

Example:

```java
@AuthenticationPrincipal
AuthenticatedUser currentUser
```

The request body must not contain a client-controlled `userId`.

### 7.3 Ownership

A learner can read and modify only their own learning progress.

An administrator's ability to manage shared content does not automatically grant access to another learner's private progress.

## 8. Learning Status API

### 8.1 Endpoint

```http
PUT /api/v1/questions/{questionId}/learning-status
```

Requires an authenticated learner.

### 8.2 Mark as Learned Request

```json
{
  "learned": true
}
```

### 8.3 Mark Not Learned Request

```json
{
  "learned": false
}
```

### 8.4 Request DTO

```java
public record UpdateLearningStatusRequest(

    @NotNull
    Boolean learned

) {}
```

A boxed `Boolean` is required so that missing or null values can be rejected rather than silently interpreted as false.

### 8.5 Response

HTTP status: `200 OK`.

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-11T20:30:00Z"
}
```

### 8.6 Idempotency

The endpoint uses PUT because the request sets a desired state.

It does not toggle the current state.

Repeated identical requests produce the same effective learning state.

A repeated successful request must not create additional progress rows or reset the learned timestamp.

## 9. Database Persistence

Ticket 11 defines:

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

This table definition is reproduced for reference. It is not a new migration.

### 9.1 Marking Learned

For a previously absent progress row:

- Insert a row.
- Set `is_learned = true`.
- Set `learned_at` to the current UTC timestamp.
- Set `updated_at` to the current UTC timestamp.

For an existing NOT_LEARNED row:

- Set `is_learned = true`.
- Set `learned_at` to the current UTC timestamp.
- Update `updated_at`.

For an existing LEARNED row:

- Preserve `is_learned`.
- Preserve `learned_at`.
- Do not perform an unnecessary update.

### 9.2 Marking Not Learned

For an existing LEARNED row:

- Set `is_learned = false`.
- Set `learned_at = NULL`.
- Update `updated_at`.

For an existing NOT_LEARNED row:

- Return the current state without modifying it.

For an absent progress row:

- Return the default NOT_LEARNED state.
- Do not insert an unnecessary row.

### 9.3 Updated Timestamp

`updated_at` changes only when the persisted learning state actually changes.

Repeated idempotent requests do not update this timestamp.

## 10. Concurrent Learning-State Requests

### 10.1 Duplicate Marking

Two simultaneous requests may both attempt to mark the same previously untouched question as learned.

Both may initially observe that no progress row exists.

The database unique constraint prevents duplicate committed progress records.

The service must handle this race safely.

A practical approach is to use a transactional insert or upsert strategy and then retrieve the resulting state.

The backend must not return an unhandled database error for an ordinary duplicate-marking race.

### 10.2 Conflicting Requests

A learner may submit Mark as Learned and Mark Not Learned concurrently.

The database cannot infer which action the learner intended to be last.

The backend must serialize conflicting updates for the same learner/question pair.

For the MVP, the committed transaction order determines the final persisted state.

The Angular frontend should disable duplicate submission while a request is pending and avoid sending overlapping state-changing requests for the same question.

### 10.3 Coordination with Revision Submission

Revision submission requires the question to be currently learned.

Learning-state changes and revision submissions must use compatible transaction and locking rules.

A revision cannot be accepted based on a stale learned-state check when a conflicting unlearn operation has already committed.

## 11. Unpublished and Archived Question Behavior

### 11.1 Final Decision

RUCH preserves learning state when a question is unpublished or archived.

Publication status controls whether a question is currently eligible for active learner workflows.

It does not erase previous learner progress.

### 11.2 Example

Before unpublishing:

```text
Question 10:
status = PUBLISHED

User 101:
is_learned = true
```

After unpublishing:

```text
Question 10:
status = DRAFT

User 101:
is_learned = true
```

The stored learning state remains unchanged.

However, Question 10 is excluded from active Learn Mode, Revise Mode, and analytics.

### 11.3 Publication Eligibility

A question is active only when both conditions hold:

```text
question.status = PUBLISHED
AND
chapter.status = PUBLISHED
```

If either the question or its chapter is unpublished or archived, the question is unavailable for active learner operations.

### 11.4 Read Behavior

Unpublished or archived questions must not appear in ordinary learner-facing question lists.

A learner must not be able to bypass this rule by directly requesting a known question ID.

For an unavailable learner-facing question resource, the API returns `404 Not Found` rather than exposing unpublished content.

Administrators may access unpublished content through authorized administrative endpoints.

### 11.5 Mutation Behavior

While a question is unavailable:

- The learner cannot mark it learned.
- The learner cannot mark it not learned.
- The learner cannot submit a new revision attempt.
- Existing learning state remains stored.
- Existing revision history remains stored.

A learning-status mutation targeting unavailable content returns `404 Not Found` under the learner API's visibility policy.

### 11.6 Republishing

When the question and chapter become published again:

- The question returns to active learner views.
- The previous learning state becomes applicable again.
- If the learner previously marked it learned, it remains learned.
- The previous learned timestamp remains unchanged.
- Previous revision history and latest revision state remain available.
- The learner can continue revising without marking the question learned again.

## 12. Unlearning and Revision History

Unlearning changes only the current learning state.

It does not delete:

- Revision-history records.
- Revision-state records.
- Previous scores.
- Revision counts.
- Last-revised timestamps.

### 12.1 Example

Before unlearning:

```text
is_learned = true
latest_score = 4
revision_count = 3
```

After unlearning:

```text
is_learned = false
latest_score = 4
revision_count = 3
```

The revision data is preserved but the question is no longer eligible for active revision.

### 12.2 Relearning

When the learner marks the question learned again:

```text
is_learned = true
learned_at = new UTC timestamp
latest_score = 4
revision_count = 3
```

The previous revision metadata is restored to the active revision experience.

The next successful revision increments the count to 4.

## 13. Analytics Behavior

Learning-state rules directly affect RUCH analytics.

### 13.1 Learning Completion

Learning completion is calculated using currently learned, published questions.

```text
Currently learned published questions
------------------------------------- × 100
Total published questions
```

### 13.2 Revision Coverage

Revision coverage includes currently learned, published questions that have at least one revision attempt.

```text
Currently learned published questions with revision history
----------------------------------------------------------- × 100
Currently learned published questions
```

### 13.3 Knowledge Strength

```text
Sum of latest scores for currently learned published questions
-------------------------------------------------------------- × 100
Currently learned published questions × 5
```

Currently learned questions without revision history contribute zero to the numerator.

### 13.4 Publication Changes

When a question is unpublished or archived:

- It is removed from active analytics denominators.
- Its score is excluded from active knowledge-strength calculations.
- Its stored learning and revision data remain unchanged.

When republished, its preserved state contributes again according to the current eligibility rules.

### 13.5 Empty Denominators

If the relevant denominator is zero, the percentage is returned as `null`.

## 14. Angular Frontend Behavior

### 14.1 Initial Question Load

Angular retrieves the question and its current learning state.

Displaying the question does not send a learning-state mutation.

### 14.2 Mark as Learned

When the learner clicks Mark as Learned:

1. Angular sends `PUT` with `learned: true`.
2. The backend validates eligibility and ownership.
3. The backend persists the transition.
4. Angular updates the UI using the server response.

### 14.3 Undo

When the learner clicks Undo or Mark Not Learned:

1. Angular sends `PUT` with `learned: false`.
2. The backend updates the persisted state.
3. Angular displays the returned NOT_LEARNED state.

### 14.4 Loading and Error States

While a mutation is pending:

- Disable the action to reduce duplicate submissions.
- Show an appropriate loading state.
- Do not treat an optimistic UI update as confirmed persistence.
- Restore or refresh the UI if the request fails.

If content becomes unpublished between initial loading and submission, display an unavailable-content message and refresh the learner's active question list.

## 15. Testing Requirements

### 15.1 Explicit Learning Tests

- Opening a question does not mark it learned.
- Reading the answer does not mark it learned.
- Navigating between questions does not mark them learned.
- Mark as Learned explicitly changes the state.

### 15.2 Timestamp Tests

- First marking sets `learned_at`.
- Repeated marking preserves `learned_at`.
- Unlearning sets `learned_at` to null.
- Relearning generates a new timestamp.
- The client cannot supply the authoritative timestamp.

### 15.3 Idempotency Tests

- Repeating `learned: true` does not create duplicate rows.
- Repeating `learned: false` does not create duplicate rows.
- Repeated requests do not unnecessarily modify `updated_at`.
- Concurrent duplicate marking preserves the unique constraint.

### 15.4 Ownership Tests

- Different learners can have different states for the same question.
- A learner cannot modify another learner's progress.
- Client-supplied user IDs cannot override authenticated identity.

### 15.5 Publication Tests

- Unpublishing preserves stored learning state.
- Archiving preserves stored learning state.
- Unpublished questions disappear from active Learn Mode.
- Unpublished questions are excluded from active analytics.
- Unpublished questions cannot be newly marked learned or unlearned.
- Republishing restores the applicability of previous learning state.
- Chapter unpublishing applies the same visibility restrictions.

### 15.6 Revision Integration Tests

- A currently learned, published question is eligible for revision.
- An unlearned question is not eligible for revision.
- Unlearning preserves revision history.
- Relearning restores revision eligibility.
- Previous revision score and count remain available after relearning.

### 15.7 Concurrency Tests

- Simultaneous first-time marking does not create duplicate progress rows.
- Conflicting learning-state requests produce a valid final state.
- Revision submission and unlearning cannot violate eligibility rules.
- Failed transactions do not leave inconsistent progress state.

## 16. Final Design Decisions

RUCH adopts the following learning-state rules:

1. Learning requires an explicit Mark as Learned action.
2. Reading never modifies learning state.
3. Learning state belongs to an authenticated learner.
4. One current progress record exists per learner/question pair.
5. An absent progress row represents NOT_LEARNED.
6. First marking sets `is_learned = true` and a UTC timestamp.
7. Duplicate marking is idempotent.
8. Repeated marking does not reset the timestamp.
9. Unlearning is supported.
10. Unlearning clears the current learned timestamp.
11. Relearning starts a new learned period.
12. Unlearning preserves revision state and history.
13. Unpublishing preserves stored learning state.
14. Archiving preserves stored learning state.
15. Unavailable content is excluded from active learning, revision, and analytics.
16. Learners cannot mutate progress for unavailable content.
17. Republishing restores the applicability of preserved progress.
18. Learning-state updates use the authenticated user identity.
19. Concurrent updates must preserve database integrity.
20. Angular displays state returned by the backend rather than inferring completion from reading activity.

These rules establish a consistent foundation for RUCH's learning progress, revision eligibility, and analytics modules.