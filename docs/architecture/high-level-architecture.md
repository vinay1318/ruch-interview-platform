# RUCH — High-Level Architecture

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** High-Level Architecture Specification  
**Version:** 1.0

---

## 1. Purpose

This document defines the proposed high-level architecture of the RUCH MVP.

RUCH is a chapter-based technical learning and revision platform that enables administrators to manage shared educational content and learners to track their individual learning progress, revision history, and confidence scores.

The architecture prioritizes:

- Clear separation of responsibilities.
- Maintainability and testability.
- Secure access to learner-specific data.
- Transactional consistency.
- Simplicity appropriate to initial product scale.
- Extensibility for future capabilities.

The MVP shall use a modular monolithic backend rather than a distributed microservices architecture.

## 2. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | React | Administrator and learner interfaces |
| Backend | Java 21, Spring Boot | REST APIs and business logic |
| Security | Spring Security | Authentication and role-based authorization |
| Persistence | Spring Data JPA | Database access |
| Database | MySQL | Persistent application data |
| Database migrations | Flyway | Version-controlled schema changes |
| Build | Maven | Dependency management and builds |
| Backend testing | JUnit, Mockito | Unit and service-level testing |

The React frontend and Spring Boot backend communicate through JSON-based REST APIs over HTTPS in deployed environments.

## 3. Architectural Style

### 3.1 Modular Monolith

RUCH shall initially use a modular monolithic architecture.

A modular monolith is a single deployable backend application whose internal functionality is organized into cohesive modules.

Each module owns a defined area of business responsibility.

The modules execute in the same application process and can participate in local database transactions.

### 3.2 Reasons for Selecting a Modular Monolith

The MVP has an initial planning capacity of approximately:

- 100 registered learners.
- 10 concurrent active learners.
- 1,000 published questions.
- 2,000 revision attempts per day.

These are planning assumptions, not measured production traffic.

At this scale, independent microservices, distributed messaging, and separate databases would introduce unnecessary operational and development complexity.

A modular monolith supports:

- Faster development and debugging.
- Simpler deployment.
- Easier transactional consistency.
- Lower infrastructure cost.
- Clear internal ownership boundaries.
- Future architectural evolution when justified.

### 3.3 Deployment Boundary

The Spring Boot backend is one deployable application.

Modules are logical code boundaries, not independently deployed services.

The React frontend is a separate client application.

MySQL is the persistent data store.

## 4. System Components

### 4.1 React Frontend

The React application provides interfaces for both administrators and learners.

**Administrator features:**

- Authentication.
- Chapter management.
- Question and reference-answer management.
- Publication and archive controls.

**Learner features:**

- Registration and login.
- Personal dashboard.
- Learn Mode.
- Revise Mode.
- Personal analytics and revision history.

The frontend is responsible for:

- Rendering application screens.
- Collecting user input.
- Managing temporary UI state.
- Calling backend REST APIs.
- Displaying validation and error responses.

The frontend shall not be trusted to enforce authorization or business rules.

Temporary recall notes entered during revision remain in frontend memory and are not transmitted or persisted.

### 4.2 Spring Boot Backend

The backend owns:

- Authentication and authorization.
- Business rules.
- Content publication eligibility.
- Learner-specific progress.
- Revision submission processing.
- Idempotency.
- Transaction management.
- Analytics calculations.
- Database persistence.

All protected operations must validate the authenticated user's identity and permissions.

### 4.3 MySQL Database

RUCH shall initially use one logical MySQL database.

It stores:

- User accounts and roles.
- Chapters.
- Questions and reference answers.
- Content publication and archive states.
- Learner-specific learning status.
- Revision attempts.
- Latest revision state.
- Minimal activity records required for reliable adoption and retention measurement, when implemented.

The database shall enforce appropriate constraints, relationships, and indexes.

Flyway shall manage schema migrations.

## 5. Backend Modules

### 5.1 Identity and Access Module

**Responsibility:** Manage user identity and access permissions.

Includes:

- Learner registration.
- Credential validation.
- Secure password hashing.
- Authentication.
- User roles.
- Administrator authorization.

The module establishes the authenticated user identity used by other modules.

### 5.2 Content Module

**Responsibility:** Manage the shared educational question bank.

Includes:

- Chapters.
- Questions.
- Reference answers.
- Content editing.
- Publishing and unpublishing.
- Archiving.
- Published-content retrieval.

The administrator manages shared content.

Learners can read eligible published content but cannot modify it.

### 5.3 Learning Module

**Responsibility:** Manage learner-specific learning status.

Includes:

- Mark as Learned.
- Mark as Not Learned.
- Relearning.
- Current learned status.
- Revision eligibility.

Learning records belong to individual learners.

Viewing a question shall not automatically mark it as learned.

### 5.4 Revision Module

**Responsibility:** Manage active recall revision submissions and history.

Includes:

- Eligible-question retrieval.
- Confidence scores from 1 to 5.
- Revision attempt history.
- Latest revision score.
- Revision count.
- Idempotent submission processing.
- Concurrent submission consistency.

Revision attempts shall be persisted transactionally.

The backend shall not receive temporary recall notes.

### 5.5 Analytics Module

**Responsibility:** Calculate personal learning and revision metrics.

Includes:

- Learning completion.
- Revision coverage.
- Confidence-based chapter strength.
- Overall strength.
- Weak-question identification.
- Chapter-level progress.

Analytics shall use the authenticated learner's records and currently eligible published content.

Historical records remain preserved when content becomes unpublished or archived.

The module may also support internal product adoption and retention reporting using qualifying activity records.

## 6. Shared Content and Personal Progress Separation

RUCH shall distinguish between shared educational content and learner-owned activity.

### 6.1 Shared Content

Shared content includes:

- Chapters.
- Questions.
- Reference answers.
- Publication states.

A published question is a single shared content record that may be accessed by multiple learners.

### 6.2 Personal Progress

Personal data includes:

- Learned/not-learned status.
- Revision attempts.
- Latest confidence scores.
- Revision counts.
- Learner analytics.

These records must be associated with the authenticated learner.

### 6.3 Example

Suppose a published question asks:

"What is idempotency in distributed systems?"

Learner A may have:

- Learned status: Learned.
- Revision count: 4.
- Latest score: 5.

Learner B may have:

- Learned status: Not Learned.
- Revision count: 0.
- Latest score: Unavailable.

Both learners reference the same question content, but their progress is independent.

### 6.4 Isolation Rule

The backend shall derive the acting learner's identity from the authenticated security context.

Learners shall not be allowed to select another learner's identity to read or modify private progress.

Database queries and service methods shall enforce the relevant ownership boundaries.

## 7. Request Flow

### 7.1 General REST Request Flow

1. A user performs an action in React.
2. React sends an HTTPS request to a Spring Boot REST endpoint.
3. Spring Security authenticates the request when required.
4. Authorization checks determine whether the operation is permitted.
5. The REST controller validates and maps the request.
6. The appropriate application service executes business rules.
7. The service interacts with repositories or other internal modules as needed.
8. Spring Data JPA performs database operations.
9. MySQL returns the requested or persisted data.
10. The backend returns a structured JSON response.
11. React updates the user interface.

### 7.2 Example: Mark as Learned

1. Learner opens a published question.
2. Learner selects Mark as Learned.
3. React sends the learning-status update request.
4. Spring Security identifies the learner.
5. The Learning module validates that the question and chapter are published.
6. The Learning module creates or updates the learner's learning-status record.
7. MySQL persists the change.
8. The backend returns the updated status.
9. React displays Learned.
10. The question becomes eligible for revision.

### 7.3 Example: Revision Submission

1. Learner opens an eligible question in Revise Mode.
2. Learner attempts active recall.
3. Learner reveals the reference answer.
4. Learner selects a confidence score from 1 to 5.
5. React submits the question reference, score, and unique submission identifier.
6. Spring Security identifies the learner.
7. The Revision module validates the score and current eligibility.
8. The backend checks whether the logical submission has already been processed.
9. For a new valid submission, the Revision module records the attempt and updates the latest revision state in a transaction.
10. MySQL commits the changes.
11. The backend returns the updated revision information.
12. React refreshes the displayed revision state.

Retries using the same submission identifier must not create duplicate attempts.

## 8. Authentication and Authorization Flow

### 8.1 Learner Registration

1. React displays the registration form.
2. Learner submits account information.
3. Spring Boot validates the request.
4. The Identity and Access module verifies account uniqueness.
5. The password is securely hashed.
6. The learner account is persisted in MySQL.
7. The application confirms successful registration.

Public registration shall create learner accounts only.

### 8.2 Login

1. React submits the learner's credentials over HTTPS.
2. Spring Security processes the authentication request.
3. The backend validates the credentials against the stored password hash.
4. On success, the application establishes an authenticated session or equivalent security mechanism.
5. React navigates the learner to the personal dashboard.
6. Subsequent protected requests carry the required authentication information.
7. Spring Security validates the authentication context and applicable permissions.

The specific session/token mechanism shall be selected during detailed security design.

### 8.3 Administrator Authorization

Administrator operations require the administrator role.

Learner accounts must not be able to create, edit, publish, unpublish, or archive shared content.

Authorization is enforced by the backend, regardless of which UI controls are visible.

### 8.4 Learner Data Authorization

A learner may access only their own private progress and revision records.

The backend shall enforce this restriction for reads and writes.

## 9. Internal Module Communication

Modules shall communicate through clearly defined internal service interfaces.

Examples:

- Learning checks content publication eligibility through Content.
- Revision checks current learned status through Learning.
- Revision checks publication eligibility through Content.
- Analytics reads the relevant content, learning, and revision data to calculate metrics.

Modules shall not communicate through HTTP merely because they are separate logical modules.

Module boundaries shall avoid unnecessary circular dependencies.

Where cross-module database transactions are required, the backend may use local Spring transaction management.

## 10. Data Consistency and Transactions

### 10.1 Learning Status

Learning-status updates must preserve a consistent current state for each learner-question combination.

### 10.2 Revision Submission

A successful new revision submission must consistently update:

- The revision attempt history.
- The latest revision state.
- The revision count.

These changes must occur within an appropriate transaction.

### 10.3 Idempotency

Each logical revision submission shall have a unique submission identifier.

The backend shall enforce duplicate prevention using an appropriate database constraint and transactional processing strategy.

### 10.4 Concurrency

Concurrent operations must not produce:

- Duplicate logical attempts.
- Lost revision counts.
- Inconsistent latest scores.
- Unauthorized cross-learner updates.

The exact locking and concurrency-control strategy shall be defined during detailed persistence design.

## 11. Analytics Architecture

Learning analytics shall be calculated from persisted application data.

The core formulas are:

**Learning Completion**

Currently learned published questions / Total published questions × 100

**Revision Coverage**

Currently learned published questions with at least one revision / Currently learned published questions × 100

**Strength**

Sum of latest confidence scores for currently learned published questions / (Currently learned published questions × 5) × 100

Currently learned questions without a revision contribute zero to the strength numerator.

Metrics with zero applicable denominators are unavailable.

### 11.1 Product Analytics

The MVP may integrate Google Analytics 4 for privacy-appropriate product usage insights, subject to applicable consent requirements.

GA4 is not required to calculate authoritative learner progress, revision history, adoption, or retention.

The MySQL-backed application remains the authoritative source for those records.

GA4 shall not receive passwords, temporary recall notes, reference-answer contents, or personally identifiable information.

GA4 is an optional external analytics integration, not an additional backend service or dependency for core application workflows.

## 12. Deployment Overview

The initial deployment consists of:

1. A React frontend.
2. One Spring Boot backend application.
3. One MySQL database.

The specific hosting provider and deployment configuration will be selected separately.

The backend shall use environment-specific configuration and externalized secrets.

The production deployment shall use HTTPS.

Database schema changes shall be managed using Flyway.

## 13. Components Not Required for MVP

The following are intentionally excluded from the initial architecture:

### 13.1 Microservices

The MVP does not require independent services for content, learning, revision, or analytics.

### 13.2 Kafka or RabbitMQ

Core workflows do not require asynchronous distributed messaging.

Revision submissions can be processed transactionally within Spring Boot and MySQL.

### 13.3 Redis

The initial scale does not justify a dedicated caching infrastructure.

Caching may be considered later if performance measurements reveal a specific need.

### 13.4 Kubernetes

Container orchestration is not required for the initial deployment.

### 13.5 API Gateway

A dedicated API gateway is unnecessary for a single backend application.

### 13.6 Separate Databases per Module

The MVP uses one logical MySQL database.

Logical ownership boundaries are enforced through code structure, access rules, and persistence design.

### 13.7 Distributed Transactions

The MVP does not require distributed transaction coordination.

## 14. Future Extensibility

The modular structure should allow future additions such as:

- Browser-based coding exercises.
- Secure Java code execution.
- AI-assisted interview practice.
- AI-assisted answer evaluation.
- Spaced repetition.
- More advanced learner analytics.
- Caching based on measured performance.
- Asynchronous processing for workloads that justify it.

Future capabilities shall be evaluated independently.

The MVP architecture shall not introduce infrastructure solely to anticipate possible future requirements.

## 15. Architectural Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Modules become tightly coupled | Define module ownership and internal service boundaries |
| Learner data leaks across accounts | Derive identity from authentication context and enforce ownership checks |
| Duplicate revision attempts | Use submission identifiers and database uniqueness constraints |
| Concurrent updates corrupt revision state | Use transactional persistence and appropriate concurrency control |
| Analytics becomes expensive | Start with indexed queries; measure before optimizing |
| Premature infrastructure complexity | Keep one backend deployment and one database |
| Future features disrupt existing modules | Preserve clear interfaces and avoid unnecessary cross-module dependencies |

This document establishes the proposed architecture for the RUCH MVP.

Detailed package structure, entity relationships, API contracts, authentication mechanism, and concurrency strategy will be finalized in subsequent design tickets.