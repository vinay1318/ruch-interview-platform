# RUCH — REST API Design

## 1. Overview

RUCH (Read. Understand. Code. Hone.) is a chapter-based technical learning and revision platform.

This document defines the REST API contract between the React frontend and the Java 21 / Spring Boot backend.

The API supports:

- Learner registration and authentication
- Administrative chapter management
- Administrative question management
- Learner access to published educational content
- Individual learning progress
- Revision attempts and revision history
- Learner analytics and dashboard metrics

RUCH follows a **modular monolith architecture**, with one Spring Boot application and one logical MySQL database.

The API is designed before implementation to establish consistent resource naming, HTTP methods, authorization, request validation, response formats, and error handling.

## 2. API Design Principles

### 2.1 Base URL

All REST endpoints use the following versioned prefix:

```http
/api/v1
```

Example:

```http
GET /api/v1/chapters
```

### 2.2 Resource Naming

- Use plural resource names, such as `/chapters` and `/questions`.
- Use lowercase URL paths.
- Use nouns for ordinary resources.
- Use HTTP methods to express CRUD operations.
- Use explicit action endpoints for meaningful business transitions, such as publishing, unpublishing, and archiving.
- Use path parameters to identify resources.
- Use query parameters for filtering, sorting, and pagination.

### 2.3 Response Format

API request and response bodies use JSON unless otherwise specified.

```http
Content-Type: application/json
```

All timestamps are represented in ISO 8601 UTC format.

Example:

```json
{
  "createdAt": "2026-11-07T14:30:00Z"
}
```

### 2.4 Resource Identifiers

Resources use backend-generated identifiers.

Examples:

- `userId`
- `chapterId`
- `questionId`
- `revisionAttemptId`

Clients must not generate or modify database identifiers.

### 2.5 Authorization

RUCH supports two application roles:

- `ADMIN`
- `LEARNER`

Administrative endpoints require `ADMIN`.

Learner endpoints require `LEARNER`.

Public authentication endpoints do not require an existing authenticated identity.

The backend determines the current user from Spring Security's authenticated security context. Learner-facing APIs do not accept a user ID to select whose progress, revision history, or analytics to access.

## 3. Authentication and Security

### 3.1 Authentication Strategy

RUCH uses Spring Security with JWT-based authentication.

The proposed MVP design includes:

- Email and password login
- BCrypt password hashing
- Signed JWT access tokens
- Opaque refresh tokens
- Refresh-token rotation
- Server-side refresh-token tracking in MySQL
- Secure, HttpOnly cookies
- Role-based access control
- CSRF protection for cookie-authenticated state-changing requests

Proposed token lifetimes:

| Credential | Lifetime |
|---|---|
| Access token | 15 minutes |
| Refresh token | 7 days |

Token lifetimes are configurable security settings.

The frontend must not store access or refresh tokens in `localStorage`.

### 3.2 Cookie Strategy

Authentication credentials are delivered using HttpOnly cookies.

Production cookies must use:

- `HttpOnly`
- `Secure`
- An appropriate `SameSite` policy
- Restricted cookie paths where practical
- Appropriate expiration settings

The frontend sends cookies with requests using the browser's credential-handling mechanism.

For cross-origin frontend and backend deployments, CORS must explicitly allow the trusted frontend origin and credentialed requests.

Wildcard origins must not be used with credentialed CORS.

### 3.3 CSRF Protection

Because browser cookies automatically accompany requests, RUCH must protect state-changing endpoints against CSRF attacks.

The backend will use a Spring Security-compatible CSRF protection mechanism, with the frontend supplying a CSRF token through a request header.

The CSRF token must be distinct from authentication credentials.

### 3.4 Authentication Endpoints

| Method | Endpoint | Authorization | Description |
|---|---|---|---|
| POST | `/auth/register` | Public | Register a learner |
| POST | `/auth/login` | Public | Authenticate and issue credentials |
| POST | `/auth/refresh` | Valid refresh token | Rotate refresh token and issue new access token |
| POST | `/auth/logout` | Valid refresh token or access token | Revoke refresh credentials and clear cookies |
| GET | `/auth/me` | Authenticated | Retrieve current user |

All paths in the endpoint tables are relative to `/api/v1`.

### 3.5 Register Learner

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

Successful response:

```http
201 Created
```

```json
{
  "id": 101,
  "name": "Alex",
  "email": "alex@example.com",
  "role": "LEARNER"
}
```

Rules:

- Public registration creates `LEARNER` accounts only.
- The client cannot assign the `ADMIN` role.
- Email addresses must be unique.
- Passwords must be securely hashed before storage.
- Password hashes must never appear in API responses.
- Registration does not automatically authenticate the learner in the MVP.
- Admin accounts are provisioned separately.

### 3.6 Login

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

Successful response:

```http
200 OK
Set-Cookie: access_token=...; HttpOnly; Secure; SameSite=Lax
Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Lax
```

```json
{
  "id": 101,
  "name": "Alex",
  "email": "alex@example.com",
  "role": "LEARNER"
}
```

The cookie attributes shown are illustrative. The final cookie paths, domain policy, and SameSite configuration depend on deployment topology.

Invalid credentials return `401 Unauthorized`.

Authentication failures must not reveal whether a specific email address exists.

### 3.7 Refresh Authentication

```http
POST /api/v1/auth/refresh
```

The request uses the refresh-token cookie.

Successful response:

```http
204 No Content
```

The backend issues replacement authentication cookies.

Rules:

- Validate the refresh token.
- Verify that the refresh-token record is active.
- Rotate the refresh token.
- Invalidate the previous refresh token.
- Persist rotation changes atomically.
- Reject expired, revoked, or invalid tokens.
- Handle concurrent refresh attempts safely.
- Detect suspicious refresh-token reuse and revoke the affected token family according to the implemented security policy.

### 3.8 Logout

```http
POST /api/v1/auth/logout
```

Successful response:

```http
204 No Content
```

The backend revokes the presented refresh credentials when valid and clears authentication cookies.

Logout is designed to be safe to repeat. If credentials are already expired or absent, the backend can still clear cookies and return `204`.

An already-issued access JWT may remain valid until expiration unless access-token revocation is implemented separately.

### 3.9 Current Authenticated User

```http
GET /api/v1/auth/me
```

Successful response:

```json
{
  "id": 101,
  "name": "Alex",
  "email": "alex@example.com",
  "role": "LEARNER"
}
```

Expired or missing access credentials return `401 Unauthorized`.

## 4. Administrative Chapter APIs

Only authenticated administrators may access these endpoints.

### 4.1 Endpoint Summary

| Method | Endpoint | Description |
|---|---|---|
| POST | `/admin/chapters` | Create chapter |
| GET | `/admin/chapters` | List chapters, including unpublished and archived |
| GET | `/admin/chapters/{chapterId}` | Retrieve chapter |
| PATCH | `/admin/chapters/{chapterId}` | Update chapter metadata |
| POST | `/admin/chapters/{chapterId}/publish` | Publish chapter |
| POST | `/admin/chapters/{chapterId}/unpublish` | Unpublish chapter |
| POST | `/admin/chapters/{chapterId}/archive` | Archive chapter |
| POST | `/admin/chapters/{chapterId}/restore` | Restore archived chapter |

Authorization: `ADMIN` for every endpoint in this section.

### 4.2 Create Chapter

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

Response:

```http
201 Created
```

```json
{
  "id": 1,
  "title": "Java Fundamentals",
  "description": "Core Java concepts for technical interviews",
  "status": "DRAFT",
  "createdAt": "2026-11-07T14:30:00Z"
}
```

New chapters are initially unpublished.

### 4.3 Update Chapter

```http
PATCH /api/v1/admin/chapters/1
```

Request:

```json
{
  "title": "Core Java Fundamentals",
  "description": "Updated chapter description"
}
```

Only editable metadata fields may be changed through this endpoint.

Publication and archival status must be changed through dedicated lifecycle endpoints.

### 4.4 Publish Chapter

```http
POST /api/v1/admin/chapters/1/publish
```

Successful response:

```http
200 OK
```

```json
{
  "id": 1,
  "status": "PUBLISHED"
}
```

Rules:

- Chapter must exist.
- Chapter must not be archived.
- Publishing must satisfy configured content-validity rules.
- Repeated publishing of an already-published chapter is safe.
- Publishing a chapter does not automatically publish its draft questions.

### 4.5 Unpublish Chapter

```http
POST /api/v1/admin/chapters/1/unpublish
```

Unpublishing removes the chapter and its questions from learner-facing content and active analytics.

Existing learning progress and revision history are preserved.

### 4.6 Archive Chapter

```http
POST /api/v1/admin/chapters/1/archive
```

Archiving removes a chapter from active learner workflows without deleting historical data.

An archived chapter cannot accept new questions.

### 4.7 Restore Chapter

```http
POST /api/v1/admin/chapters/1/restore
```

Restoring an archived chapter returns it to an unpublished state.

Restoration does not automatically publish the chapter.

## 5. Administrative Question APIs

### 5.1 Endpoint Summary

| Method | Endpoint | Description |
|---|---|---|
| POST | `/admin/chapters/{chapterId}/questions` | Create question in chapter |
| GET | `/admin/chapters/{chapterId}/questions` | List chapter questions |
| GET | `/admin/questions/{questionId}` | Retrieve question |
| PATCH | `/admin/questions/{questionId}` | Update question |
| POST | `/admin/questions/{questionId}/publish` | Publish question |
| POST | `/admin/questions/{questionId}/unpublish` | Unpublish question |
| POST | `/admin/questions/{questionId}/archive` | Archive question |
| POST | `/admin/questions/{questionId}/restore` | Restore archived question |

Authorization: `ADMIN`.

### 5.2 Create Question

```http
POST /api/v1/admin/chapters/1/questions
```

Request:

```json
{
  "questionText": "What is polymorphism in Java?",
  "referenceAnswer": "Polymorphism allows an object to exhibit multiple forms."
}
```

Response:

```http
201 Created
```

```json
{
  "id": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism in Java?",
  "referenceAnswer": "Polymorphism allows an object to exhibit multiple forms.",
  "status": "DRAFT"
}
```

Rules:

- The chapter must exist.
- The chapter must not be archived.
- Question text and reference answer are required.
- The question initially has `DRAFT` status.
- The chapter relationship is determined by the URL.
- The backend does not trust a client-supplied chapter name.

### 5.3 Update Question

```http
PATCH /api/v1/admin/questions/10
```

Request:

```json
{
  "questionText": "Explain runtime polymorphism in Java.",
  "referenceAnswer": "Runtime polymorphism is achieved through method overriding."
}
```

This endpoint updates question content without changing its publication state.

### 5.4 Publish Question

```http
POST /api/v1/admin/questions/10/publish
```

Successful response:

```json
{
  "id": 10,
  "chapterId": 1,
  "status": "PUBLISHED"
}
```

Rules:

- Question must exist.
- Question must not be archived.
- Its chapter must not be archived.
- Required question content must be valid.
- Publishing a question does not automatically publish its chapter.

A question is visible to learners only when both the question and its parent chapter are published.

### 5.5 Unpublish Question

```http
POST /api/v1/admin/questions/10/unpublish
```

Unpublished questions are excluded from active learning, revision, and analytics calculations.

Historical learner records remain stored.

### 5.6 Archive and Restore Question

```http
POST /api/v1/admin/questions/10/archive
POST /api/v1/admin/questions/10/restore
```

Archiving preserves history while removing the question from active workflows.

Restoration returns the question to `DRAFT` status.

## 6. Learner Content APIs

These endpoints expose only content eligible for learner access.

Authorization: `LEARNER`.

### 6.1 Endpoint Summary

| Method | Endpoint | Description |
|---|---|---|
| GET | `/chapters` | List published chapters |
| GET | `/chapters/{chapterId}` | Retrieve published chapter |
| GET | `/chapters/{chapterId}/questions` | List published questions |
| GET | `/questions/{questionId}` | Retrieve published question |

### 6.2 List Chapters

```http
GET /api/v1/chapters?page=0&size=20
```

Response:

```json
{
  "items": [
    {
      "id": 1,
      "title": "Java Fundamentals",
      "description": "Core Java interview concepts",
      "totalQuestions": 25,
      "learnedQuestions": 10
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

Only published chapters are returned.

The `learnedQuestions` value is calculated for the authenticated learner.

### 6.3 List Questions in Chapter

```http
GET /api/v1/chapters/1/questions?page=0&size=20
```

Response:

```json
{
  "items": [
    {
      "id": 10,
      "chapterId": 1,
      "questionText": "What is polymorphism?",
      "isLearned": true
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

Only published questions belonging to published chapters are returned.

### 6.4 Retrieve Question

```http
GET /api/v1/questions/10
```

Response:

```json
{
  "id": 10,
  "chapterId": 1,
  "questionText": "What is polymorphism?",
  "referenceAnswer": "Polymorphism allows objects to take multiple forms.",
  "isLearned": true
}
```

Learn Mode may display the reference answer.

Revision Mode uses separate endpoints to support the answer-hidden recall workflow.

## 7. Learning Progress APIs

Authorization: `LEARNER`.

### 7.1 Endpoint Summary

| Method | Endpoint | Description |
|---|---|---|
| PUT | `/questions/{questionId}/learning-status` | Set learned or not learned |
| GET | `/learning/questions` | Retrieve learner's currently learned questions |

### 7.2 Mark Question as Learned

```http
PUT /api/v1/questions/10/learning-status
```

Request:

```json
{
  "learned": true
}
```

Response:

```http
200 OK
```

```json
{
  "questionId": 10,
  "isLearned": true,
  "learnedAt": "2026-11-07T15:00:00Z"
}
```

Rules:

- Learner must be authenticated.
- Question and chapter must be published.
- Viewing a question does not automatically mark it learned.
- Repeated requests setting the same state do not create duplicate learning transitions.
- Learning status is private to the authenticated learner.
- Marking a question learned makes it eligible for revision.

### 7.3 Mark Question as Not Learned

```http
PUT /api/v1/questions/10/learning-status
```

Request:

```json
{
  "learned": false
}
```

Response:

```json
{
  "questionId": 10,
  "isLearned": false,
  "learnedAt": null
}
```

Rules:

- Question becomes ineligible for new revision attempts.
- Existing revision attempts and scores remain stored.
- The question is excluded from current learned-question analytics.
- Relearning restores revision eligibility without deleting historical attempts.

### 7.4 List Learned Questions

```http
GET /api/v1/learning/questions?page=0&size=20
```

Returns currently learned questions that remain eligible for active learner workflows.

## 8. Revision APIs

Revision Mode allows learners to recall an answer, reveal the reference answer, and submit a self-assessed score.

Authorization: `LEARNER`.

### 8.1 Endpoint Summary

| Method | Endpoint | Description |
|---|---|---|
| GET | `/revision/questions` | List eligible revision questions |
| GET | `/revision/questions/{questionId}` | Retrieve revision question and previous performance |
| POST | `/revision/attempts` | Submit revision score |
| GET | `/revision/attempts` | List revision attempts |
| GET | `/revision/questions/{questionId}/history` | Retrieve question revision history |

### 8.2 Revision Eligibility

A question is eligible for revision only when:

- The learner has currently marked it as learned.
- The question is published.
- Its parent chapter is published.
- Neither the question nor chapter is archived.

Previously stored revision attempts do not automatically make an unlearned question eligible.

### 8.3 List Revision Questions

```http
GET /api/v1/revision/questions?page=0&size=20
```

Response:

```json
{
  "items": [
    {
      "questionId": 10,
      "chapterId": 1,
      "questionText": "What is polymorphism?",
      "previousScore": 3,
      "lastRevisedAt": "2026-11-05T12:00:00Z",
      "revisionCount": 2
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

### 8.4 Retrieve Revision Question

```http
GET /api/v1/revision/questions/10
```

Initial response:

```json
{
  "questionId": 10,
  "questionText": "What is polymorphism?",
  "previousScore": 3,
  "lastRevisedAt": "2026-11-05T12:00:00Z",
  "revisionCount": 2
}
```

The initial response intentionally excludes the reference answer.

To reveal the answer, the frontend calls the existing learner question endpoint:

```http
GET /api/v1/questions/10
```

The React frontend controls when the reference answer becomes visible.

This is a learning-experience convention rather than a security boundary: an authenticated learner may access published reference answers through Learn Mode.

Temporary recall notes remain exclusively in frontend memory and must not be transmitted or persisted.

### 8.5 Submit Revision Attempt

```http
POST /api/v1/revision/attempts
Idempotency-Key: 8a5b3e10-4f24-4e97-91c2-a9d18d05a62f
Content-Type: application/json
```

Request:

```json
{
  "questionId": 10,
  "score": 4
}
```

Successful response:

```http
201 Created
```

```json
{
  "revisionAttemptId": 501,
  "questionId": 10,
  "score": 4,
  "revisionCount": 3,
  "submittedAt": "2026-11-07T15:30:00Z"
}
```

Rules:

- Score must be an integer between 1 and 5.
- Question must be eligible for revision.
- The backend obtains the learner identity from authentication.
- Every distinct successful submission creates an immutable revision attempt.
- Latest revision state is updated consistently with attempt history.
- Attempt creation and latest-state updates occur within one database transaction.
- Concurrent submissions must not corrupt the revision count or latest-state ordering.
- The idempotency key is required.
- Idempotency keys are scoped to the authenticated learner and operation.
- Replaying the same key with the same payload returns the original successful result without creating another attempt.
- Reusing the same key with a different payload returns `409 Conflict`.
- The backend must enforce uniqueness atomically through database constraints or an equivalent transactional mechanism.

### 8.6 Revision History

```http
GET /api/v1/revision/questions/10/history?page=0&size=20
```

Response:

```json
{
  "items": [
    {
      "revisionAttemptId": 501,
      "score": 4,
      "submittedAt": "2026-11-07T15:30:00Z"
    },
    {
      "revisionAttemptId": 480,
      "score": 3,
      "submittedAt": "2026-11-05T12:00:00Z"
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 2,
  "totalPages": 1
}
```

Revision history is private to the authenticated learner.

Historical records are preserved even when a question becomes unlearned, unpublished, or archived. Historical access may be provided separately