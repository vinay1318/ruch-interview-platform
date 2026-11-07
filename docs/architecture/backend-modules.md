# RUCH — Backend Module Design

## 1. Purpose

This document defines the logical backend modules of the RUCH application, their responsibilities, ownership boundaries, and permitted interactions.

RUCH follows a modular monolithic architecture implemented with Java 21, Spring Boot, Spring Security, Spring Data JPA, and MySQL.

All modules execute within one Spring Boot application and use one logical MySQL database.

The design prioritizes business cohesion, clear module ownership, transactional consistency, and maintainability.

## 2. Architectural Principles

### 2.1 Package by Feature

Backend functionality shall be organized by business capability rather than centralized technical layers.

Each module may contain its own controllers, services, repositories, entities, and DTOs.

### 2.2 Single Responsibility

Each module shall own a distinct business capability and the rules associated with it.

### 2.3 Encapsulation

Modules shall expose operations through well-defined service interfaces or application-facing contracts.

Other modules shall not directly modify a module's entities or use its repositories to bypass business rules.

### 2.4 In-Process Communication

Modules shall communicate through Java method calls.

Internal REST calls, message brokers, and distributed transactions are not required.

### 2.5 Shared Database, Logical Ownership

All modules shall use one MySQL database.

Each module shall own the persistence operations associated with its business responsibility.

A shared physical database does not imply unrestricted cross-module access.

### 2.6 Security

Authentication and authorization shall be enforced at appropriate application boundaries.

Learner-owned data must remain isolated by authenticated user identity.

## 3. Authentication Module

**Package:** `authentication`

### Responsibilities

- Process login requests.
- Validate credentials using Spring Security.
- Verify submitted passwords against securely stored hashes.
- Establish and validate authenticated security contexts.
- Support logout and session termination according to the selected authentication mechanism.
- Enforce or integrate role-based access controls.
- Handle authentication failures securely.

### Owned Logic

- Authentication workflow.
- Credential verification.
- Authentication security configuration and supporting components.

### Dependencies

- User module for account identity, credential hashes, account status, and roles.
- Spring Security for authentication infrastructure.

### Boundaries

- Does not own user profile management.
- Does not manage chapters or questions.
- Does not read or modify learner progress.
- Does not store plaintext passwords.

The exact session or token mechanism will be determined during detailed security design.

## 4. User Module

**Package:** `user`

### Responsibilities

- Register learner accounts.
- Manage user account records.
- Maintain account identity and role assignments.
- Enforce account uniqueness rules.
- Provide account information to Authentication through a controlled interface.
- Support administrator account provisioning through a restricted process.

### Owned Data

- User identity.
- Account information.
- Credential hashes.
- Account status.
- Role assignments.

### Dependencies

- Shared security infrastructure for password hashing during registration.
- Database persistence infrastructure.

### Boundaries

- Does not authenticate login requests.
- Does not manage revision attempts.
- Does not store chapter or question content.
- Does not calculate learner analytics.

Public registration shall assign learner privileges only.

Administrator privileges shall not be assignable through public registration.

## 5. Chapter Module

**Package:** `chapter`

### Responsibilities

- Create chapters.
- Update chapter metadata.
- Retrieve chapters.
- Publish and unpublish chapters.
- Archive chapters.
- Validate chapter-level publication requirements.
- Expose chapter eligibility information to other modules.

### Owned Data

- Chapter identifier.
- Chapter metadata.
- Chapter publication state.
- Chapter archive state.

### Dependencies

- Authentication and authorization infrastructure for protected administrator operations.
- Question module through a controlled interface when chapter-level rules require question information.

### Boundaries

- Does not own question text or reference answers.
- Does not modify learner learning status.
- Does not delete learner revision history.
- Does not calculate personal analytics.

Only eligible published chapters shall appear in active learner workflows.

## 6. Question Module

**Package:** `question`

### Responsibilities

- Create questions within chapters.
- Update question content.
- Maintain reference answers.
- Retrieve questions.
- Publish and unpublish questions.
- Archive questions where supported by the content lifecycle.
- Validate question-level publication requirements.
- Provide question content and publication eligibility information to other modules.

### Owned Data

- Question identifier.
- Associated chapter identifier.
- Question content.
- Reference answer.
- Question publication state.
- Question archive state, where applicable.

### Dependencies

- Chapter module for chapter existence and eligibility.
- Authentication and authorization infrastructure for protected administrator operations.

### Boundaries

- Does not manage learner confidence scores.
- Does not modify learned status.
- Does not store revision attempts.
- Does not calculate learner analytics.

A question is available to learners only when the question and its parent chapter are both published and otherwise eligible.

## 7. Learning Progress Module

**Package:** `learning`

### Responsibilities

- Mark questions as learned.
- Mark questions as not learned.
- Restore learned status when a learner relearns a question.
- Retrieve learner-specific learning status.
- Determine current learning eligibility.
- Provide learning-status information to Revision and Analytics.

### Owned Data

- Learner identifier.
- Question identifier.
- Current learned status.
- Learning-status timestamps as required by the persistence design.

### Dependencies

- Authentication infrastructure for the acting learner's identity.
- Question and Chapter modules for content eligibility.
- User module for account references when required.

### Boundaries

- Does not modify shared question content.
- Does not delete historical revision attempts.
- Does not calculate confidence scores.
- Does not modify another learner's records.

### Important Rules

Viewing a question shall not mark it as learned.

Marking a question as not learned removes it from active revision eligibility while preserving historical revision data.

Relearning restores revision eligibility without resetting previous revision history.

## 8. Revision Module

**Package:** `revision`

### Responsibilities

- Retrieve revision-eligible questions.
- Retrieve previous revision information.
- Validate confidence scores between 1 and 5.
- Process revision submissions.
- Persist revision attempt history.
- Maintain the latest revision state.
- Maintain revision counts.
- Enforce submission idempotency.
- Handle concurrent submissions consistently.

### Owned Data

- Revision attempt identifier.
- Submission identifier.
- Learner identifier.
- Question identifier.
- Confidence score.
- Submission timestamp.
- Latest revision state.
- Revision count.

### Dependencies

- Learning Progress module for current learned status.
- Question and Chapter modules for publication eligibility.
- Authentication infrastructure for learner identity.

### Boundaries

- Does not mark questions as learned or not learned.
- Does not edit reference answers.
- Does not manage user accounts.
- Does not store temporary recall notes.

### Transactional Rules

For each new valid submission, the revision attempt and corresponding latest revision state must be updated consistently.

Duplicate submissions using the same logical submission identifier must not create additional attempts or increment counts.

Concurrent submissions must not corrupt history or latest revision state.

## 9. Analytics Module

**Package:** `analytics`

### Responsibilities

- Calculate learning completion.
- Calculate revision coverage.
- Calculate chapter strength.
- Calculate overall strength.
- Identify weak questions.
- Provide learner-specific dashboard metrics.
- Support internal product adoption and retention reporting when the required activity records are available.

### Owned Logic

- Metric definitions.
- Aggregation rules.
- Eligibility filters.
- Analytics response models.

### Dependencies

- Chapter module for published chapter information.
- Question module for published question information.
- Learning Progress module for current learned status.
- Revision module for latest revision information and history.

### Boundaries

- Does not modify learned status.
- Does not submit revisions.
- Does not edit shared content.
- Does not own authentication credentials.

### Metric Rules

**Learning Completion**

Currently learned published questions / Total published questions × 100.

**Revision Coverage**

Currently learned published questions revised at least once / Currently learned published questions × 100.

**Strength**

Sum of latest confidence scores for currently learned published questions / (Currently learned published questions × 5) × 100.

Currently learned but unrevised questions contribute zero to the strength numerator.

Metrics with a zero denominator shall be reported as unavailable.

Analytics shall exclude currently ineligible content from active calculations while preserving historical records.

## 10. Module Dependency Rules

RUCH shall follow explicit module dependency rules to preserve the boundaries of its modular monolithic architecture.

### 10.1 Approved Dependencies

| Calling Module | Permitted Business Module Dependencies |
|---|---|
| Authentication | User |
| User | None |
| Chapter | None |
| Question | Chapter |
| Learning Progress | Chapter, Question |
| Revision | Learning Progress, Chapter, Question |
| Analytics | Chapter, Question, Learning Progress, Revision |

Shared security and infrastructure components may be used where required.

### 10.2 Chapter and Question Dependency Direction

The Chapter and Question modules shall remain separate logical modules.

The Question module may depend on the Chapter module to:

- Validate chapter existence.
- Retrieve chapter metadata required by question operations.
- Verify chapter publication and archive eligibility.

The Chapter module shall not directly depend on the Question module.

This rule prevents circular dependencies and preserves clear ownership.

### 10.3 Cross-Module Publishing Coordination

Operations that require both Chapter and Question functionality may be coordinated by an application-level content publishing coordinator.

The coordinator shall:

1. Receive or process the requested publishing operation.
2. Invoke the appropriate Chapter and Question application services.
3. Enforce applicable cross-module publishing rules.
4. Establish a suitable transaction boundary when multiple persistent changes must succeed together.
5. Return the final operation result.

The coordinator shall not bypass module services by directly modifying repositories belonging to either module.

A dedicated coordinator class shall be introduced only when a real workflow requires it.

### 10.4 Repository Ownership

Each module shall own its persistence access.

Other modules shall not directly access repositories belonging to that module.

Cross-module operations shall use explicitly defined interfaces.

### 10.5 Transaction Management

Operations that modify multiple related records shall use appropriate Spring-managed transaction boundaries.

Because all modules share one Spring Boot application and one MySQL database, local database transactions are sufficient for the MVP.

### 10.6 Avoiding Circular Dependencies

Business module dependencies shall follow a directed structure.

Circular service dependencies are prohibited.

Shared infrastructure shall not be used as a workaround to introduce hidden circular business dependencies.

### 10.7 Future Evolution

Module boundaries may evolve when supported by actual requirements.

The initial design does not assume that modules will become independently deployed microservices.

## 11. Shared Infrastructure

The backend may include limited shared infrastructure packages.

### Common

Examples:

- Standard API error responses.
- Shared exception handling.
- Cross-cutting validation utilities.

### Config

Examples:

- Spring Security configuration.
- Application configuration.
- CORS configuration.
- Persistence configuration.

Shared infrastructure shall not become a location for unrelated business logic.

## 12. Suggested Package Structure

```text
com.ruch.ruch_interview_platform
│
├── authentication/
│   ├── controller/
│   ├── service/
│   ├── dto/
│   └── security/
│
├── user/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── chapter/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── question/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── learning/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── revision/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── analytics/
│   ├── controller/
│   ├── service/
│   └── dto/
│
├── common/
│
└── config/
```

This structure is illustrative.

Subpackages and classes shall be created when needed rather than generating empty boilerplate in advance.

## 13. Example Cross-Module Workflows

### 13.1 Learner Marks a Question as Learned

1. The authenticated learner submits a learning-status request.
2. Learning Progress identifies the acting learner.
3. Learning Progress verifies question and chapter eligibility through the owning modules.
4. Learning Progress updates the learner-specific status.
5. The updated state is persisted.
6. The API returns the result.

### 13.2 Learner Submits a Revision

1. The learner submits a confidence score and unique submission identifier.
2. Revision identifies the authenticated learner.
3. Revision checks learned status through Learning Progress.
4. Revision checks publication eligibility through the content-owning modules.
5. Revision validates the score and submission identifier.
6. Revision persists the new attempt and latest revision state transactionally.
7. The API returns the updated revision information.

### 13.3 Learner Opens Dashboard

1. The authenticated learner opens the dashboard.
2. Analytics identifies the acting learner.
3. Analytics obtains eligible content information.
4. Analytics obtains current learned statuses.
5. Analytics obtains latest revision scores and revision history information.
6. Analytics calculates completion, coverage, strength, and weak-question information.
7. The API returns learner-specific analytics.
8. React renders the dashboard.

## 14. Architectural Constraints

The MVP shall not introduce:

- Independent backend microservices.
- Separate databases for each module.
- Internal HTTP communication between modules.
- Kafka or RabbitMQ for ordinary learning and revision operations.
- Redis without a measured caching requirement.
- Distributed transactions.
- A dedicated API gateway solely for internal module routing.

Modules are logical boundaries within one deployable Spring Boot application.

## 15. Future Evolution

The modular structure shall support future capabilities such as:

- Coding exercises.
- Secure code execution.
- AI-assisted evaluation.
- Mock interviews.
- Spaced repetition.
- Advanced analytics.

Future functionality may introduce additional modules when justified.

Existing modules shall not be split into microservices solely because the application grows in features.
