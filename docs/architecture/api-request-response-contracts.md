# RUCH — API Request and Response Contracts

## 1. Overview

RUCH (Read. Understand. Code. Hone.) is a chapter-based technical learning and revision platform.

This document defines the request DTOs, response DTOs, input validation rules, error response formats, pagination conventions, and user identity requirements for the RUCH REST API.

It builds upon the REST endpoint design established in `docs/architecture/rest-api-endpoints.md`.

The purpose of this document is to establish a predictable contract between:

- **Angular frontend:** Sends requests, displays responses, and handles validation errors.
- **Spring Boot backend:** Validates input, enforces business rules, and generates responses.
- **MySQL database:** Persists application data and enforces database constraints.

The API contract must remain independent of internal JPA entity structures.

## 2. General API Conventions

### 2.1 API Versioning

All endpoints use the base path:

```text
/api/v1
```

### 2.2 Data Format

Request and response bodies use JSON.

```http
Content-Type: application/json
Accept: application/json
```

Responses without bodies, such as `204 No Content`, do not require a JSON content type.

### 2.3 Naming Conventions

- JSON fields use `camelCase`.
- Java DTO classes use `PascalCase`.
- Resource identifiers use descriptive names such as `chapterId` and `questionId`.
- Timestamps use ISO 8601 UTC format.
- Boolean response fields use descriptive names such as `isLearned`.
- Enum values use uppercase strings such as `DRAFT`, `PUBLISHED`, and `ARCHIVED`.

Example:

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-08T14:30:00Z"
}
```

### 2.4 DTO Separation

Request DTOs, response DTOs, and persistence entities must remain separate.

Controllers must not expose JPA entities directly.

DTOs should contain only the fields required by their API operations.

Sensitive fields such as password hashes, refresh-token hashes, and internal security metadata must never appear in public API responses.

### 2.5 Null Values

Nullable response fields are included explicitly as `null` where the contract defines them as nullable.

Examples include:

- `previousScore`
- `lastRevisedAt`
- `learnedAt`
- Analytics percentages with unavailable denominators

An omitted request property and an explicit JSON `null` are not necessarily equivalent.

The distinction is particularly important for PATCH requests.

## 3. Authentication Contracts

Authentication uses Spring Security, signed JWT access tokens, and rotating opaque refresh tokens.

Authentication credentials are transported using secure HttpOnly cookies.

### 3.1 RegisterRequest

Endpoint:

```http
POST /api/v1/auth/register
```

Request:

```json
{
  "name": "Alex",
  "email": "alex@example.com",
  "password": "ExamplePassword123!"
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `name` | String | Yes | Not blank, maximum 100 characters |
| `email` | String | Yes | Not blank, valid email, maximum 254 characters |
| `password` | String | Yes | 12–128 characters |

The password length policy is an MVP default and must be configurable. Passwords are never logged or returned in responses.

Public registration always creates a learner account.

The client cannot specify a role or account ID.

Successful response: `201 Created`.

### 3.2 LoginRequest

Endpoint:

```http
POST /api/v1/auth/login
```

Request:

```json
{
  "email": "alex@example.com",
  "password": "ExamplePassword123!"
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `email` | String | Yes | Not blank, valid email format |
| `password` | String | Yes | Not blank |

Login validation must not reveal whether an account exists.

Successful authentication returns `200 OK`, sets authentication cookies, and returns the authenticated user's public profile.

### 3.3 UserResponse

```json
{
  "id": 101,
  "name": "Alex",
  "email": "alex@example.com",
  "role": "LEARNER"
}
```

| Field | Type | Nullable |
|---|---|---|
| `id` | Long | No |
| `name` | String | No |
| `email` | String | No |
| `role` | Enum | No |

Supported roles:

```text
ADMIN
LEARNER
```

Used by:

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`

### 3.4 Refresh and Logout

Endpoints:

```http
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
```

Neither endpoint requires a JSON request DTO.

Refresh credentials are obtained from the designated refresh-token cookie.

Successful responses use:

```http
204 No Content
```

Refresh issues replacement authentication cookies.

Logout clears authentication cookies and revokes the presented refresh credentials when valid.

The endpoints must apply appropriate CSRF protections and must not accept arbitrary user IDs in the request.

## 4. Chapter Contracts

Administrative chapter endpoints require the `ADMIN` role.

### 4.1 CreateChapterRequest

Endpoint:

```http
POST /api/v1/admin/chapters
```

Request:

```json
{
  "title": "Java Fundamentals",
  "description": "Core Java concepts for technical interviews"
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `title` | String | Yes | Not blank, maximum 150 characters |
| `description` | String | No | Maximum 2,000 characters; explicit null rejected |

If omitted during creation, `description` defaults to an empty string.

The backend assigns the chapter ID and initial `DRAFT` status.

Successful response: `201 Created`.

### 4.2 UpdateChapterRequest

Endpoint:

```http
PATCH /api/v1/admin/chapters/{chapterId}
```

Example:

```json
{
  "title": "Advanced Java Fundamentals"
}
```

Editable fields:

| Field | Type | Validation |
|---|---|---|
| `title` | String | Not blank, maximum 150 characters |
| `description` | String | Maximum 2,000 characters |

PATCH rules:

- At least one editable field must be present.
- Omitted fields remain unchanged.
- Explicit null values are rejected.
- Provided fields are validated.
- Unknown fields are rejected.
- Publication status cannot be modified through this DTO.

An empty string is permitted for `description` to clear the description.

### 4.3 ChapterResponse

```json
{
  "id": 1,
  "title": "Java Fundamentals",
  "description": "Core Java concepts",
  "status": "DRAFT",
  "createdAt": "2026-11-08T14:30:00Z"
}
```

| Field | Type | Nullable |
|---|---|---|
| `id` | Long | No |
| `title` | String | No |
| `description` | String | No |
| `status` | Enum | No |
| `createdAt` | Instant | No |

Supported chapter states:

```text
DRAFT
PUBLISHED
ARCHIVED
```

Lifecycle operations use dedicated endpoints.

### 4.4 ChapterStatusResponse

Used by chapter publication, unpublication, archival, and restoration operations.

```json
{
  "id": 1,
  "status": "PUBLISHED"
}
```

Publication actions must validate the existing state and enforce allowed transitions.

Restoring an archived chapter returns it to `DRAFT`.

### 4.5 LearnerChapterResponse

Learner-facing chapter responses exclude administrative editing fields.

```json
{
  "id": 1,
  "title": "Java Fundamentals",
  "description": "Core Java concepts",
  "totalQuestions": 25,
  "learnedQuestions": 10
}
```

Progress counts are scoped to the authenticated learner.

Only published chapters are exposed.

## 5. Question Contracts

### 5.1 CreateQuestionRequest

Endpoint:

```http
POST /api/v1/admin/chapters/{chapterId}/questions
```

Request:

```json
{
  "questionText": "What is polymorphism?",
  "referenceAnswer": "Polymorphism allows objects to take multiple forms."
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `questionText` | String | Yes | Not blank, maximum 2,000 characters |
| `referenceAnswer` | String | Yes | Not blank, maximum 20,000 characters |

Character limits are proposed MVP constraints and can be revised if rich educational content requires more space.

The `chapterId` is obtained from the URL.

The request must not include:

- `questionId`
- `userId`
- `chapterName`
- `status`

The backend validates chapter existence and business eligibility.

New questions are created in `DRAFT` status.

### 5.2 UpdateQuestionRequest

Endpoint:

```http
PATCH /api/v1/admin/questions/{questionId}
```

Example:

```json
{
  "referenceAnswer": "An updated explanation of polymorphism."
}
```

Editable fields:

| Field | Type | Validation |
|---|---|---|
| `questionText` | String | Not blank, maximum 2,000 characters |
| `referenceAnswer` | String | Not blank, maximum 20,000 characters |

Only supplied fields are updated.

Both fields reject explicit null and blank values.

Publication status cannot be changed through this DTO.

### 5.3 AdminQuestionResponse

```json
{
  "id": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism?",
  "referenceAnswer": "Polymorphism allows objects to take multiple forms.",
  "status": "DRAFT"
}
```

Supported states:

```text
DRAFT
PUBLISHED
ARCHIVED
```

### 5.4 QuestionStatusResponse

Used by question lifecycle operations.

```json
{
  "id": 10,
  "chapterId": 1,
  "status": "PUBLISHED"
}
```

A published question becomes learner-visible only when its parent chapter is also published.

### 5.5 LearnerQuestionSummaryResponse

Used in learner question lists.

```json
{
  "id": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism?",
  "isLearned": true
}
```

### 5.6 LearnerQuestionDetailResponse

Used in Learn Mode and when revealing a reference answer.

```json
{
  "id": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism?",
  "referenceAnswer": "Polymorphism allows objects to take multiple forms.",
  "isLearned": true
}
```

The reference answer is intentionally available through Learn Mode.

Revision Mode initially uses a separate response without the reference answer.

This is a user-experience convention, not a security restriction on educational content.

## 6. Learning Progress Contracts

### 6.1 UpdateLearningStatusRequest

Endpoint:

```http
PUT /api/v1/questions/{questionId}/learning-status
```

Request:

```json
{
  "learned": true
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `learned` | Boolean | Yes | Must not be null |

Java DTO:

```java
public record UpdateLearningStatusRequest(
    @NotNull Boolean learned
) {}
```

A boxed `Boolean` is used instead of primitive `boolean` so missing values can be rejected.

The request must not contain a `userId`.

### 6.2 LearningStatusResponse

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-08T14:30:00Z"
}
```

| Field | Type | Nullable |
|---|---|---|
| `questionId` | Long | No |
| `isLearned` | Boolean | No |
| `learnedAt` | Instant | Yes |

When marked as not learned:

```json
{
  "questionId": 10,
  "isLearned": false,
  "learnedAt": null
}
```

Rules:

- Only published, eligible questions can have their active learning status changed.
- Viewing a question never marks it learned automatically.
- Repeating the same PUT request does not create duplicate transitions.
- Marking a question not learned removes active revision eligibility.
- Historical revision attempts remain preserved.
- Relearning restores eligibility without deleting previous revision history.
- `learnedAt` represents the start of the current learned period.

## 7. Revision Contracts

### 7.1 RevisionQuestionResponse

Endpoint:

```http
GET /api/v1/revision/questions/{questionId}
```

Response:

```json
{
  "questionId": 10,
  "questionText": "What is polymorphism?",
  "previousScore": 3,
  "lastRevisedAt": "2026-11-06T10:00:00Z",
  "revisionCount": 2
}
```

| Field | Type | Nullable | Meaning |
|---|---|---|---|
| `questionId` | Long | No | Question identifier |
| `questionText` | String | No | Question being revised |
| `previousScore` | Integer | Yes | Latest previous score |
| `lastRevisedAt` | Instant | Yes | Latest previous revision timestamp |
| `revisionCount` | Long | No | Total successful revision attempts |

For a question that has never been revised:

```json
{
  "questionId": 10,
  "questionText": "What is polymorphism?",
  "previousScore": null,
  "lastRevisedAt": null,
  "revisionCount": 0
}
```

A null previous score means that no previous revision exists.

The revision count includes retained historical attempts, including attempts made before a question was marked not learned and subsequently relearned.

### 7.2 SubmitRevisionAttemptRequest

Endpoint:

```http
POST /api/v1/revision/attempts
```

Required header:

```http
Idempotency-Key: 8a5b3e10-4f24-4e97-91c2-a9d18d05a62f
```

Request:

```json
{
  "questionId": 10,
  "score": 4
}
```

| Field | Type | Required | Validation |
|---|---|---|---|
| `questionId` | Long | Yes | Positive identifier |
| `score` | Integer | Yes | Integer between 1 and 5 |

Java DTO:

```java
public record SubmitRevisionAttemptRequest(

    @NotNull
    @Positive
    Long questionId,

    @NotNull
    @Min(1)
    @Max(5)
    Integer score

) {}
```

The request must not include:

- `userId`
- `revisionAttemptId`
- `submittedAt`
- `previousScore`
- Temporary recall notes

The backend generates the revision attempt ID and submission timestamp.

### 7.3 RevisionAttemptResponse

Successful response: `201 Created`.

```json
{
  "revisionAttemptId": 501,
  "questionId": 10,
  "score": 4,
  "revisionCount": 3,
  "submittedAt": "2026-11-08T15:30:00Z"
}
```

| Field | Type | Nullable |
|---|---|---|
| `revisionAttemptId` | Long | No |
| `questionId` | Long | No |
| `score` | Integer | No |
| `revisionCount` | Long | No |
| `submittedAt` | Instant | No |

Revision submission must:

1. Identify the authenticated learner.
2. Validate question eligibility.
3. Validate the score.
4. Validate the idempotency key.
5. Persist the revision attempt.
6. Update the latest revision state.
7. Commit related database changes transactionally.
8. Return the resulting revision attempt response.

### 7.4 Idempotency Contract

Every revision submission requires a client-generated UUID idempotency key.

Rules:

- The same learner, operation, key, and payload represent the same logical submission.
- Replaying a completed successful submission returns the original `201` status and response body.
- Reusing the key with a different payload returns `409 Conflict`.
- Different keys represent separate attempts.
- Database uniqueness constraints protect against concurrent duplicate creation.
- Idempotency records are scoped to the authenticated learner and operation.
- Key retention and cleanup policies must be defined during persistence design.

### 7.5 RevisionHistoryItemResponse

```json
{
  "revisionAttemptId": 501,
  "score": 4,
  "submittedAt": "2026-11-08T15:30:00Z"
}
```

Used by:

```http
GET /api/v1/revision/questions/{questionId}/history
```

History is ordered newest first by default.

History access must be scoped to the authenticated learner, including when the underlying question is no longer eligible for active revision.

### 7.6 RevisionQuestionSummaryResponse

Used by:

```http
GET /api/v1/revision/questions
```

```json
{
  "questionId": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism?",
  "previousScore": 3,
  "lastRevisedAt": "2026-11-06T10:00:00Z",
  "revisionCount": 2
}
```

Only currently eligible revision questions appear in the active revision list.

## 8. Analytics Contracts

All analytics are scoped to the authenticated learner.

### 8.1 AnalyticsOverviewResponse

Endpoint:

```http
GET /api/v1/analytics/overview
```

Response:

```json
{
  "totalPublishedQuestions": 100,
  "learnedQuestions": 60,
  "revisedLearnedQuestions": 40,
  "learningCompletionPercentage": 60.0,
  "revisionCoveragePercentage": 66.67,
  "knowledgeStrengthPercentage": 53.33
}
```

| Field | Type | Nullable |
|---|---|---|
| `totalPublishedQuestions` | Long | No |
| `learnedQuestions` | Long | No |
| `revisedLearnedQuestions` | Long | No |
| `learningCompletionPercentage` | Decimal | Yes |
| `revisionCoveragePercentage` | Decimal | Yes |
| `knowledgeStrengthPercentage` | Decimal | Yes |

The example assumes that the latest scores across the currently learned questions sum to 160.

### 8.2 Metric Definitions

**Learning completion**

```text
Currently learned published questions
------------------------------------- × 100
Total published questions
```

**Revision coverage**

```text
Currently learned questions with revision history
------------------------------------------------- × 100
Currently learned questions
```

**Knowledge strength**

```text
Sum of latest scores for currently learned questions
---------------------------------------------------- × 100
Currently learned questions × 5
```

Currently learned questions without revision history contribute zero to knowledge strength.

If a denominator is zero, the corresponding percentage is `null`.

Percentages are returned as numeric values on a 0–100 scale, rounded to two decimal places for API presentation.

### 8.3 ChapterAnalyticsResponse

Endpoint:

```http
GET /api/v1/analytics/chapters/{chapterId}
```

Response:

```json
{
  "chapterId": 1,
  "totalPublishedQuestions": 25,
  "learnedQuestions": 15,
  "revisedLearnedQuestions": 10,
  "learningCompletionPercentage": 60.0,
  "revisionCoveragePercentage": 66.67,
  "knowledgeStrengthPercentage": 48.0
}
```

Chapter analytics follow the same metric definitions as overall analytics.

### 8.4 WeakQuestionResponse

```json
{
  "questionId": 15,
  "chapterId": 1,
  "questionText": "Explain Java memory management.",
  "latestScore": 2,
  "lastRevisedAt": "2026-11-06T10:00:00Z"
}
```

The MVP defines low-scoring revised questions as those with a latest score of 1 or 2.

Unrevised learned questions are not silently assigned a low score; they remain distinguishable from revised questions.

## 9. Pagination Contract

### 9.1 Request Parameters

List endpoints support:

```http
GET /api/v1/chapters?page=0&size=20
```

| Parameter | Type | Default | Validation |
|---|---|---|---|
| `page` | Integer | 0 | Must be at least 0 |
| `size` | Integer | 20 | Must be between 1 and 100 |

Invalid values return `400 Bad Request`.

### 9.2 Generic PageResponse

```json
{
  "items": [
    {
      "id": 1,
      "title": "Java Fundamentals"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

Java conceptual DTO:

```java
public record PageResponse<T>(
    List<T> items,
    int page,
    int size,
    long totalElements,
    int totalPages
) {}
```

### 9.3 Pagination Rules

- Page indexes are zero-based.
- The default page size is 20.
- The maximum page size is 100.
- Empty results return an empty `items` array.
- Every paginated query uses deterministic sorting.
- Sorting must include a unique tie-breaker, such as the resource ID.
- Only documented sorting fields are accepted.
- The backend must not allow arbitrary database property names to be injected through sorting parameters.

Offset pagination is sufficient for the RUCH MVP.

Cursor-based pagination may be considered later if data volume or query performance justifies it.

## 10. Standard Error Response

RUCH uses structured JSON error responses.

### 10.1 ApiErrorResponse

```json
{
  "timestamp": "2026-11-08T16:00:00Z",
  "status": 400,
  "error": "VALIDATION_ERROR",
  "code": "INVALID_REQUEST",
  "message": "Request validation failed",
  "path": "/api/v1/auth/register",
  "requestId": "req-12345",
  "fieldErrors": [
    {
      "field": "email",
      "message": "Invalid email format"
    },
    {
      "field": "password",
      "message": "Password does not meet requirements"
    }
  ]
}
```

| Field | Type | Required |
|---|---|---|
| `timestamp` | Instant | Yes |
| `status` | Integer | Yes |
| `error` | String | Yes |
| `code` | String | Yes |
| `message` | String | Yes |
| `path` | String | Yes |
| `requestId` | String | Yes |
| `fieldErrors` | Array | Yes |

For errors unrelated to specific fields, `fieldErrors` is an empty array.

### 10.2 FieldErrorResponse

```json
{
  "field": "questionText",
  "message": "Question text is required"
}
```

Field errors use JSON property names, not Java internal property paths.

Multiple detected validation errors are returned together.

Field errors should be ordered deterministically, such as by field name and constraint.

### 10.3 Error Codes

| HTTP status | Error code | Meaning |
|---|---|---|
| 400 | `INVALID_REQUEST` | Invalid JSON, fields, or parameters |
| 400 | `INVALID_PAGINATION` | Invalid page or size |
| 401 | `AUTHENTICATION_REQUIRED` | Missing or expired authentication |
| 401 | `INVALID_CREDENTIALS` | Login failed |
| 403 | `ACCESS_DENIED` | Insufficient role or permissions |
| 403 | `CSRF_VALIDATION_FAILED` | Missing or invalid CSRF token |
| 404 | `CHAPTER_NOT_FOUND` | Chapter unavailable |
| 404 | `QUESTION_NOT_FOUND` | Question unavailable |
| 409 | `DUPLICATE_EMAIL` | Registration email already registered |
| 409 | `INVALID_RESOURCE_STATE` | Invalid business-state transition |
| 409 | `QUESTION_NOT_LEARNED` | Revision requires learned status |
| 409 | `IDEMPOTENCY_KEY_CONFLICT` | Key reused with different payload |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests |
| 500 | `INTERNAL_SERVER_ERROR` | Unexpected server failure |

These codes are stable API identifiers intended for Angular error handling.

Error messages may evolve without requiring frontend changes.

### 10.4 Validation Error Aggregation

The backend returns all detected field-level validation errors from the current validation pass.

Example:

```json
{
  "timestamp": "2026-11-08T16:00:00Z",
  "status": 400,
  "error": "VALIDATION_ERROR",
  "code": "INVALID_REQUEST",
  "message": "Request validation failed",
  "path": "/api/v1/admin/chapters",
  "requestId": "req-67890",
  "fieldErrors": [
    {
      "field": "description",
      "message": "Description exceeds the maximum length"
    },
    {
      "field": "title",
      "message": "Title is required"
    }
  ]
}
```

This applies to validation failures detected together, not necessarily every possible downstream business-rule violation.

Authentication errors must not expose sensitive account information.

### 10.5 Centralized Exception Handling

Spring Boot will use `@RestControllerAdvice` to convert supported exceptions into standardized API responses.

Expected categories include:

- Request body validation failures
- Invalid path or query parameters
- Malformed JSON
- Unsupported or unknown request properties
- Resource-not-found exceptions
- Business-state conflicts
- Idempotency conflicts
- Unexpected server errors

Spring Security authentication, authorization, and CSRF failures must also be mapped into consistent JSON responses through the appropriate security exception handlers.

Internal stack traces, SQL details, passwords, and tokens must never be returned to clients.

## 11. Input Validation Strategy

### 11.1 Validation Layers

RUCH uses multiple validation layers.

**Layer 1 — Request DTO validation**

Validates input structure and basic field constraints.

Examples:

- Required values
- String lengths
- Valid email format
- Positive identifiers
- Revision score between 1 and 5

**Layer 2 — Service-level business validation**

Validates business rules.

Examples:

- Chapter must exist.
- Archived chapters cannot accept questions.
- Only eligible questions can be revised.
- Question publication requires valid content.
- Learning status changes require eligible published content.

**Layer 3 — Database constraints**

Protects data integrity.

Examples:

- Unique email addresses
- Foreign keys
- Required database columns
- Unique idempotency records
- Transactional consistency

DTO validation does not replace service validation or database constraints.

### 11.2 Jakarta Bean Validation

Spring Boot DTOs may use:

```java
@NotNull
@NotBlank
@Size
@Email
@Positive
@Min
@Max
```

Controllers use `@Valid` to trigger request DTO validation.

Business validation remains within the owning backend service or module.

### 11.3 Unknown JSON Fields

Unknown request properties are rejected rather than silently ignored.

Example invalid request:

```json
{
  "questionId": 10,
  "score": 4,
  "userId": 999
}
```

The revision submission DTO does not permit `userId`.

The backend must reject the unexpected field rather than attempting to use it.

Jackson configuration or request-specific deserialization rules must enforce this contract.

## 12. PATCH Request Semantics

RUCH supports partial updates for administrative chapter and question metadata.

### 12.1 Omitted Fields

Omitted fields remain unchanged.

Example:

```json
{
  "title": "Advanced Java Fundamentals"
}
```

Only the title is updated.

### 12.2 Explicit Null

Explicit null values are rejected.

Example:

```json
{
  "description": null
}
```

Response:

```http
400 Bad Request
```

### 12.3 Empty Strings

Empty strings are validated according to the field.

Examples:

- `title: ""` is invalid.
- `questionText: ""` is invalid.
- `referenceAnswer: ""` is invalid.
- `description: ""` is allowed and clears the description.

### 12.4 Empty PATCH Requests

An empty request object is invalid.

```json
{}
```

Response:

```http
400 Bad Request
```

### 12.5 Implementation Consideration

Ordinary Java records with nullable fields do not automatically distinguish an omitted JSON property from a property explicitly supplied as `null`.

Therefore, PATCH handling must preserve property presence information.

Possible implementation approaches include:

- A dedicated patch-field wrapper
- Explicit JSON property-presence tracking
- Carefully validated `JsonNode` processing

RUCH will use an implementation that distinguishes absent, null, and non-null values while keeping the service layer type-safe.

The final implementation approach will be selected during controller and DTO development.

## 13. Authenticated User Identity

### 13.1 Identity Source

The authenticated learner's identity must be obtained from Spring Security.

For protected endpoints, the backend validates the JWT and establishes the authenticated principal.

The backend must not trust a user ID supplied in the request body or query parameters.

### 13.2 Example

Valid request:

```json
{
  "questionId": 10,
  "score": 4
}
```

Invalid request:

```json
{
  "userId": 500,
  "questionId": 10,
  "score": 4
}
```

### 13.3 Controller Example

```java
@PostMapping("/revision/attempts")
public ResponseEntity<RevisionAttemptResponse> submitRevision(
        @AuthenticationPrincipal CustomUserPrincipal principal,
        @Valid @RequestBody SubmitRevisionAttemptRequest request,
        @RequestHeader("Idempotency-Key") UUID idempotencyKey) {

    Long authenticatedUserId = principal.getId();

    RevisionAttemptResponse response =
        revisionService.submit(
            authenticatedUserId,
            request,
            idempotencyKey
        );

    return ResponseEntity.status(HttpStatus.CREATED).body(response);
}
```

This is an illustrative controller contract, not an implemented class.

### 13.4 Data Isolation

All learner-owned queries must be scoped to the authenticated user.

This applies to:

- Learning progress
- Revision submissions
- Revision history
- Previous revision metadata
- Learner analytics
- Weak-question results

Authorization must be enforced by the backend regardless of frontend route guards.

## 14. Angular Integration Contract

Angular will consume the REST API using `HttpClient`.

### 14.1 TypeScript Interfaces

Angular models should correspond to backend response contracts.

Example:

```typescript
export interface LearningStatusResponse {
  questionId: number;
  isLearned: boolean;
  learnedAt: string | null;
}
```

Java `Instant` values are represented as ISO 8601 strings in JSON.

### 14.2 HTTP Services

Angular feature services will encapsulate API communication.

Examples:

- `AuthService`
- `ChapterService`
- `QuestionService`
- `LearningService`
- `RevisionService`
- `AnalyticsService`

### 14.3 HTTP Interceptors

Angular HTTP interceptors will handle common HTTP concerns, including:

- Credentialed requests when required
- CSRF header attachment
- Authentication-expiration handling
- Consistent error processing

Refresh requests must be coordinated to avoid unnecessary concurrent token rotations.

### 14.4 Validation Errors

Angular reactive forms will map `fieldErrors` to the corresponding form controls.

The frontend should display field-specific validation messages and a general message for non-field errors.

Client-side validation improves usability but does not replace backend validation.

## 15. Contract Testing Requirements

API contract tests must verify the following.

### Authentication

- Required registration fields
- Invalid email format
- Password length validation
- No client-controlled role assignment
- Public user responses never expose credentials
- Missing or expired authentication returns 401

### Chapters

- Required title validation
- Description length validation
- Partial PATCH updates
- Explicit null rejection
- Empty PATCH rejection
- Unknown field rejection

### Questions

- Required question text
- Required reference answer
- Maximum field lengths
- Chapter ID obtained from the path
- Invalid chapter references rejected
- No client-controlled publication status

### Learning

- Required Boolean learned field
- Correct learning status response
- Nullable learned timestamp
- Repeated state-setting requests
- User-specific data isolation

### Revision

- Required question ID
- Score between 1 and 5
- Previous score metadata
- Null metadata for never-revised questions
- Required idempotency key
- Duplicate request replay
- Conflicting key rejection
- Concurrent submission consistency
- No user ID accepted from the client

### Analytics

- Correct completion formula
- Correct revision coverage formula
- Correct knowledge strength formula
- Unrevised learned questions contribute zero strength
- Null percentages when denominators are zero
- Learner-specific data isolation

### Shared Contracts

- Standard error response fields
- Multiple detected validation errors
- Stable error codes
- Zero-based pagination
- Maximum page size
- Deterministic sorting
- Consistent timestamp serialization

## 16. DTO Package Organization

DTOs should follow the feature-based backend architecture established in Ticket 8.

Recommended structure:

```text
com.ruch.ruch_interview_platform
├── authentication/
│   └── dto/
├── user/
│   └── dto/
├── chapter/
│   └── dto/
├── question/
│   └── dto/
├── learning/
│   └── dto/
├── revision/
│   └── dto/
├── analytics/
│   └── dto/
└── common/
    ├── dto/
    └── exception/
```

Shared pagination and error DTOs belong in `common`.

Feature-specific DTOs remain in their owning modules.

DTOs must not introduce circular dependencies between backend modules.

## 17. Final Contract Decisions

RUCH adopts the following API contract standards:

1. Request and response DTOs remain separate from JPA entities.
2. JSON fields use camelCase naming.
3. Timestamps use ISO 8601 UTC.
4. Request DTOs enforce field constraints.
5. Service layers enforce business rules.
6. Database constraints protect persistent integrity.
7. Validation errors use structured field-level responses.
8. All detected field validation errors are returned together.
9. Stable machine-readable error codes support Angular integration.
10. Pagination uses zero-based pages, default size 20, maximum size 100.
11. PATCH updates only explicitly supplied fields.
12. Explicit null values in PATCH requests are rejected.
13. Unknown request fields are rejected.
14. Learning status responses expose the current state and timestamp.
15. Revision responses include previous score, previous timestamp, and revision count.
16. Revision attempts require an idempotency key.
17. Learner identity is always obtained from authenticated backend security context.
18. Learner-owned records are never selected using a client-controlled user ID.
19. Angular TypeScript interfaces follow the documented response contracts.
20. API contract tests verify validation, authorization, pagination, and response consistency.

This document establishes the request and response contracts for the RUCH MVP and serves as the reference for subsequent Spring Boot controller, service, DTO, validation, and Angular integration implementation.