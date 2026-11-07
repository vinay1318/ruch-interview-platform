# RUCH — MVP Scope Definition

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** Minimum Viable Product Scope  
**Version:** 1.0
---

## 1. Overview

RUCH is a chapter-based technical learning and revision platform designed to help software developers improve their knowledge through structured learning, active recall, confidence-based self-assessment, and personalized progress tracking.

This document defines the Minimum Viable Product (MVP) scope for RUCH.

The MVP focuses on delivering a complete learning and revision experience, supported by a basic administrator dashboard, while deliberately excluding advanced capabilities that are not essential for validating the product.

The objective is to release a usable platform, gather feedback from real learners, and evolve the product based on demonstrated needs.

### 1.1 Purpose

This document establishes:

- Features included in the initial MVP.
- Features explicitly excluded or deferred.
- Core administrator and learner workflows.
- Initial architecture and technology boundaries.
- MVP readiness and success criteria.
- Principles for controlling scope changes.

### 1.2 Related Documents

- `docs/requirements/functional-requirements.md`
- `docs/requirements/non-functional-requirements.md`

The functional requirements define expected application behavior, while the non-functional requirements define quality expectations.

This document determines which capabilities must be delivered in the initial release.

---

## 2. MVP Objectives

The initial release aims to:

1. Provide secure authentication and authorization for administrators and learners.
2. Deliver a basic React administrator dashboard for managing educational content.
3. Maintain a centralized, administrator-managed question bank.
4. Allow learners to study published questions and reference answers.
5. Support explicit tracking of learned and not-learned questions.
6. Enable active recall through structured revision sessions.
7. Record confidence scores and preserve revision history.
8. Provide basic personal learning analytics.
9. Deliver a minimal, usable React frontend for learners.
10. Support an initial beta with approximately 100 registered learners and 10 concurrently active learners.

The MVP prioritizes usability, correctness, security, reliability, and maintainability over advanced features and distributed infrastructure.

---

## 3. In-Scope Features

### MVP-001: Authentication and Authorization

The MVP shall support:

- Learner registration.
- User login and logout.
- One master administrator account.
- Administrator and learner roles.
- Backend-enforced role-based authorization.
- Secure password storage.
- Protection of learner-specific resources.
- Appropriate handling of unauthorized and forbidden requests.

The administrator account shall be provisioned through a controlled setup process rather than public registration.

Learners shall not be able to assign themselves administrator privileges.

Authentication and authorization shall be enforced by Spring Security.

### MVP-002: Administrator Content Management

The MVP shall provide secured REST APIs and a basic React-based administrator dashboard.

The administrator shall be able to:

- Create and edit chapters.
- Publish, unpublish, and archive chapters.
- Create and edit questions.
- Create and update reference answers.
- Publish, unpublish, and archive questions.
- Organize questions under chapters.
- View existing chapters and their associated questions.

The administrator dashboard shall provide basic forms, lists, and content-management actions.

All administrator operations shall enforce backend role-based authorization.

Advanced content-management capabilities, such as bulk imports, rich-text editors, collaborative editing, and content versioning, are excluded from the MVP.

### MVP-003: Shared Question Bank

The MVP shall provide:

- One centralized question bank.
- Published chapters accessible to learners.
- Published questions and reference answers.
- Consistent shared educational content.
- Independent learner-specific progress.

All learners shall access the same published question bank.

Learners shall not be permitted to create, edit, publish, or archive shared educational content.

Unpublished or archived content shall not appear in active learner workflows.

Historical learner records associated with unpublished or archived content shall remain preserved.

### MVP-004: Learn Mode

The MVP shall allow learners to:

- Browse published chapters.
- View published questions.
- Read reference answers.
- Explicitly mark questions as learned.
- Mark previously learned questions as not learned.
- Mark questions as learned again.

Viewing or reading a question shall not automatically change its learning status.

Marking a question as learned shall make it eligible for revision, provided the question and its chapter remain published.

Marking a question as not learned shall remove it from active revision eligibility without deleting historical revision records.

Relearning a question shall restore revision eligibility while retaining its previous revision history and scores.

### MVP-005: Revise Mode

The MVP shall support:

- Revision of currently learned, published questions.
- Question-first presentation with the reference answer hidden.
- Explicit reveal of the reference answer.
- Temporary frontend-only recall notes.
- Confidence-based self-assessment.
- Progression to another eligible question.

Before a revision attempt, the learner shall be able to view:

- Previous confidence score, if available.
- Last revision date, if available.
- Total previous revision count.

For a question that has never been revised, the previous score and last revision date shall be unavailable, and the revision count shall be zero.

Temporary recall notes shall not be transmitted to or stored by the backend.

### MVP-006: Confidence Scoring

The MVP shall support confidence scores from 1 to 5.

| Score | Meaning |
|---|---|
| 1 | Unable to recall |
| 2 | Limited recall |
| 3 | Partial understanding |
| 4 | Mostly correct |
| 5 | Confident and accurate recall |

The learner shall assign the score manually after revealing and reviewing the reference answer.

The backend shall validate the submitted confidence score.

Automated AI-based scoring is excluded from the MVP.

### MVP-007: Revision History and State

The MVP shall preserve:

- Historical revision attempts.
- Latest confidence score.
- Last revision timestamp.
- Total revision count.

Each revision attempt shall be associated with the authenticated learner and the corresponding question.

Revision submissions shall be idempotent and transactionally consistent.

Repeated submissions using the same submission identifier shall not create duplicate revision attempts.

Concurrent submissions shall not corrupt revision counts or latest revision state.

Historical records shall remain preserved when a learner changes a question's learning status or when content is archived.

### MVP-008: Basic Personal Analytics

The MVP shall provide:

- Total currently learned questions.
- Learning completion percentage.
- Revision coverage percentage.
- Confidence-based strength score.
- Identification of weak questions.
- Basic chapter-level learning progress.
- Personal revision history.

Analytics shall follow the definitions established in the Functional Requirements Specification.

Learning completion shall represent the proportion of published questions currently marked as learned.

Revision coverage shall represent the proportion of currently learned questions that have been revised at least once.

Strength shall be calculated using the latest confidence scores of currently learned questions, with unrevised learned questions contributing zero.

When no questions are currently learned, the strength metric shall be displayed as unavailable rather than as a misleading percentage.

Unpublished or archived content shall be excluded from active learning analytics while preserving historical records.

Analytics shall remain private to the authenticated learner.

Advanced trend analysis, predictive recommendations, and AI-generated learning insights are excluded from the MVP.

### MVP-009: Minimal React Frontend

The MVP shall include a React-based interface for both learners and administrators.

#### Learner Interface

- Registration and login.
- Browse published chapters and questions.
- Learn Mode.
- Mark questions as learned or not learned.
- Revise Mode with answer reveal.
- Confidence score submission.
- Personal analytics dashboard.

#### Administrator Interface

- Administrator login.
- Chapter listing and management.
- Chapter creation and editing forms.
- Question listing and management.
- Question creation and editing forms.
- Reference answer management.
- Publish, unpublish, and archive actions.

Both interfaces may be implemented within the same React application using role-specific routes and navigation.

The frontend shall enforce appropriate navigation and role-based visibility while relying on backend authorization for security.

The interface shall be responsive and usable on common desktop and mobile screen sizes.

Advanced animations, complex design systems, and sophisticated administrative workflows are excluded from the MVP.

### MVP-010: Foundational Quality and Testing

The MVP shall include:

- Request validation and controlled error handling.
- Authentication and authorization tests.
- Cross-user data isolation tests.
- Unit tests for core business rules.
- Persistence and transaction integration tests.
- Idempotency and concurrency tests for revision submissions.
- Version-controlled database migrations.
- Basic application logging and health monitoring.
- Automated build and test checks.
- Basic deployment and database recovery preparation before public beta.

These requirements support product correctness and are not optional feature enhancements.

---

## 4. Out-of-Scope Features

The following capabilities are explicitly excluded from the initial MVP.

| Feature | Reason for Deferral |
|---|---|
| AI-based answer scoring | Manual confidence scoring is sufficient to validate the initial revision workflow |
| Spaced repetition algorithms | Initial revision can be learner-driven |
| Browser-based coding IDE | Adds significant editor and execution complexity |
| Automated code execution | Requires secure execution isolation and additional infrastructure |
| AI-assisted code review | Depends on coding functionality and external model integration |
| Timed mock interviews | Not essential for validating learning and revision |
| Advanced analytics | Basic progress and confidence metrics are sufficient initially |
| Personalized AI recommendations | Requires usage data and additional evaluation |
| Kafka | No initial requirement justifies distributed event streaming |
| Microservices | A modular monolith is sufficient for the initial target |
| Redis | Deferred until load testing or profiling demonstrates a need for caching, distributed rate limiting, or other shared infrastructure |
| Advanced admin dashboard features | Basic React admin content management is included; bulk imports, collaborative editing, and advanced workflows are deferred |

Out-of-scope features may be reconsidered after the MVP is validated.

### 4.1 Redis — Deferred Infrastructure Enhancement

Redis is excluded from the initial MVP because the expected workload does not currently justify a distributed caching layer.

Potential future use cases include:

- Caching frequently accessed published chapters and questions.
- Reducing repeated database queries for shared reference content.
- Supporting distributed rate limiting.
- Caching expensive analytics responses when justified by measured performance.

Redis will be introduced when profiling, load testing, or operational requirements demonstrate a clear benefit.

MySQL will remain the authoritative data store for learner progress, revision history, and shared educational content.

### 4.2 Kafka and Microservices — Excluded from MVP

The initial RUCH application shall use a modular monolithic architecture.

Kafka and microservices are excluded because the MVP does not require independently deployed services or distributed event processing.

Potential future use cases for asynchronous messaging include:

- Coding submission processing.
- AI evaluation workflows.
- Notification processing.
- Analytics event processing.
- Background task execution.

These capabilities shall be considered only when corresponding product features or operational requirements justify them.

---

## 5. MVP User Journeys

### 5.1 Administrator Journey

1. Administrator authenticates through the React application.
2. Administrator opens the admin dashboard.
3. Administrator creates a chapter.
4. Administrator creates questions and reference answers.
5. Administrator publishes the chapter and its questions.
6. Published content becomes available to learners.
7. Administrator may edit, unpublish, or archive content when necessary.

### 5.2 Learner — Learning Journey

1. Learner registers or logs in.
2. Learner selects a published chapter.
3. Learner opens a published question.
4. Learner reads the reference answer.
5. Learner explicitly marks the question as learned.
6. The question becomes eligible for revision.

A learner may reverse the learned status without losing previous revision history.

### 5.3 Learner — Revision Journey

1. Learner selects a chapter.
2. The platform identifies currently learned, published questions.
3. Learner starts revision.
4. The question is displayed without its reference answer.
5. The learner can view previous score, last revision date, and revision count.
6. Learner attempts active recall.
7. Learner reveals the reference answer.
8. Learner submits a confidence score from 1 to 5.
9. The platform saves the revision attempt and updates the latest revision state.
10. Learner continues to another eligible question.

### 5.4 Learner — Analytics Journey

1. Learner opens their personal dashboard.
2. The platform displays learning completion.
3. The platform displays revision coverage.
4. The platform displays confidence-based strength.
5. Learner identifies weak questions.
6. Learner returns to Learn Mode or Revise Mode to improve understanding.

---

## 6. MVP Architecture

The initial architecture shall use a modular monolith.

```text
                  React Application
                  /               \
          Admin Dashboard     Learner Interface
                  \               /
                   \             /
                    HTTPS / REST
                         |
                         v
               Spring Boot Application
                         |
             +-----------+-----------+
             |                       |
      Authentication            Content Management
      & Authorization           Chapters & Questions
             |                       |
             +-----------+-----------+
                         |
                  Learning Progress
                         |
                  Revision Processing
                         |
                  Personal Analytics
                         |
                         v
                    MySQL Database
```

### 6.1 Technology Direction

| Component | Technology |
|---|---|
| Backend | Java 21, Spring Boot |
| Frontend | React |
| Security | Spring Security |
| Persistence | Spring Data JPA / Hibernate |
| Database | MySQL |
| Database migrations | Flyway |
| Build | Maven |
| Testing | JUnit, Mockito, integration testing |
| API style | REST |
| Architecture | Modular monolith |

The MVP shall not require Kafka, Redis, microservices, or a distributed code-execution service.

### 6.2 Architectural Principles

The MVP architecture shall follow these principles:

- Prefer simplicity over unnecessary distributed infrastructure.
- Maintain clear module boundaries.
- Enforce authentication and authorization at the backend.
- Preserve learner-specific data isolation.
- Use MySQL as the authoritative persistent data store.
- Use transactions and constraints for consistency-critical operations.
- Introduce infrastructure only when requirements or measurements justify it.
- Preserve the ability to evolve the application incrementally.

---

## 7. MVP Success Criteria

The MVP shall be considered ready for initial beta testing when:

- An administrator can authenticate through the React application.
- An administrator can create, edit, publish, unpublish, and archive chapters and questions through the React administrator dashboard.
- All administrator dashboard operations are protected by backend role-based authorization.
- An administrator can manage reference answers.
- A learner can register and authenticate.
- Learners can browse published chapters and questions.
- Learners can explicitly mark questions as learned or not learned.
- Only eligible questions appear in active revision.
- Learners can reveal answers and submit confidence scores.
- Revision history is persisted correctly.
- Personal analytics are available and isolated by learner.
- A minimal React frontend supports the complete learner workflow.
- Core security, consistency, and testing requirements are satisfied.
- The application can be deployed and accessed by invited beta testers.

Initial beta readiness does not require advanced AI features or distributed infrastructure.

---

## 8. Initial Capacity Assumptions

| Metric | Initial Assumption |
|---|---|
| Registered learners | 100 |
| Concurrent active learners | 10 |
| Published questions | 1,000 |
| Revision attempts per day | 2,000 |

These assumptions are planning targets, not verified performance results.

Performance and capacity shall be validated through testing.

---

## 9. Future Development Direction

Following MVP validation, potential enhancements include:

### 9.1 Learning Improvements

- Spaced repetition.
- Personalized revision scheduling.
- Advanced analytics and learning trends.
- Intelligent recommendations.

### 9.2 Coding Practice

- Embedded browser-based IDE.
- Java code execution.
- Automated test-case evaluation.
- Coding performance tracking.

### 9.3 AI Capabilities

- AI-assisted answer evaluation.
- AI code review.
- Interview simulation.
- Personalized feedback.

### 9.4 Platform Infrastructure

- Event-driven workflows using Apache Kafka where justified.
- Asynchronous background processing.
- Redis caching based on measured performance needs.
- Independent services for specialized workloads.

Future features shall be prioritized based on user feedback, product value, and engineering tradeoffs.

---

## 10. Scope Management

New feature requests shall be evaluated against the following questions:

1. Is the feature necessary for a learner to complete the core learning and revision journey?
2. Does it address a critical security, reliability, or usability issue?
3. Can the MVP deliver its intended value without it?
4. Will implementing it delay validation with real users?
5. Can it be introduced safely after the MVP?

Features that do not materially contribute to initial product validation should generally be deferred.

Changes to the approved MVP scope shall be reflected in this document and the project backlog.

---

## 11. Acceptance Criteria

- [x] Administrator content management included in MVP.
- [x] Authentication included in MVP.
- [x] Learn Mode included in MVP.
- [x] Revise Mode included in MVP.
- [x] Basic personal analytics included in MVP.
- [x] Minimal React frontend included in MVP.
- [x] Basic React administrator dashboard included in MVP.
- [x] AI-based scoring deferred.
- [x] Spaced repetition deferred.
- [x] Redis deferred.
- [x] Kafka excluded from MVP.
- [x] Microservices excluded from MVP.

---

## 12. Review and Status

**Status:** Approved  
**Ticket:** TICKET-003  
**Deliverable:** MVP Scope Definition  
**Implementation:** Not applicable — product scope definition only.

This document establishes the approved MVP boundary for RUCH.

The scope may evolve after implementation feedback and early user validation. All changes shall be documented and reviewed before being incorporated into the MVP backlog.