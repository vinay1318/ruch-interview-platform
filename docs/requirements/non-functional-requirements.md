# RUCH — Non-Functional Requirements

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** Non-Functional Requirements Specification  
**Version:** 1.0

---

## 1. Overview

RUCH is a chapter-based learning and revision platform designed to help software developers improve technical knowledge through structured learning, active recall, confidence-based self-assessment, and personalized progress tracking.

This document defines the quality attributes and operational expectations of the RUCH platform.

While the Functional Requirements Specification describes what the system must do, this document describes how securely, reliably, efficiently, and maintainably those capabilities should operate.

### 1.1 Objectives

The primary objectives of these non-functional requirements are to:

- Protect user accounts and personal learning information.
- Enforce strict isolation between learner-specific records.
- Preserve learning progress and revision history reliably.
- Establish measurable performance expectations.
- Support an initial target of 100 registered learners.
- Maintain a clean, testable, and extensible application architecture.
- Provide a foundation for future performance testing and production readiness.

### 1.2 Initial Scope

These requirements apply to:

1. User authentication and authorization.
2. Administrator-managed educational content.
3. Learner-specific learning progress.
4. Revision submissions and history.
5. Personal analytics.
6. REST API operations.
7. Database persistence.
8. Application testing, monitoring, and deployment readiness.

Performance and capacity targets are initial engineering assumptions and must be validated through testing.

---

## 2. Security Requirements

Security is a foundational requirement because RUCH manages user accounts and private learning information.

### NFR-SEC-001: Authentication

Protected application endpoints shall require successful user authentication.

Public endpoints, such as registration and login, shall be explicitly identified.

### NFR-SEC-002: Role-Based Authorization

The platform shall enforce role-based access control.

- Administrators may manage shared educational content.
- Learners may access published content and manage their own progress.
- Learners shall not access administrator-only operations.

Authorization shall be enforced by the backend rather than relying exclusively on frontend restrictions.

### NFR-SEC-003: Password Protection

User passwords shall never be stored in plaintext.

Passwords shall be processed using a suitable adaptive password-hashing algorithm, such as BCrypt or Argon2.

### NFR-SEC-004: Secure Communication

Production application traffic shall use HTTPS.

Sensitive credentials and authentication information shall not be transmitted over unencrypted public connections.

### NFR-SEC-005: Secrets Management

Database credentials, API keys, authentication signing secrets, and other sensitive configuration values shall not be committed to source control.

Secrets shall be provided through environment variables or an appropriate secrets-management mechanism.

### NFR-SEC-006: Input Validation

The backend shall validate incoming requests, including:

- Required fields.
- Field lengths.
- Supported values.
- Confidence score ranges.
- Resource identifiers.
- Invalid or malformed payloads.

Invalid requests shall be rejected with appropriate HTTP responses.

### NFR-SEC-007: Error Handling

Application error responses shall not expose:

- Passwords or authentication secrets.
- Database credentials.
- Internal stack traces.
- Sensitive infrastructure details.
- Other learners' private information.

Detailed diagnostic information shall be restricted to appropriate application logs.

### NFR-SEC-008: Authentication Abuse Protection

Public authentication endpoints shall include protections against repeated unauthorized access attempts.

Rate limiting or equivalent safeguards shall be introduced before public production deployment.

### NFR-SEC-009: Secure Dependency Management

Application dependencies shall be maintained and reviewed for known security vulnerabilities.

Critical security updates shall be prioritized.

---

## 3. User Data Isolation

RUCH maintains a shared question bank while storing individual learning progress and revision history separately.

Data isolation is required to prevent unauthorized access to another learner's records.

### NFR-ISO-001: Learner Ownership

Learning progress, revision state, revision history, and personal analytics shall be associated with the authenticated learner.

### NFR-ISO-002: Backend Ownership Enforcement

Learners shall only be permitted to access or modify their own private records.

The backend shall determine the acting user's identity from the authenticated security context.

A user-supplied identifier shall not be trusted as proof of ownership.

### NFR-ISO-003: Cross-User Access Prevention

Changing request parameters, resource identifiers, or API payloads shall not allow a learner to access another learner's private data.

### NFR-ISO-004: Shared Content Separation

Shared educational content shall remain logically separate from learner-specific records.

Questions and reference answers may be shared across users, while learning and revision data remain private.

### NFR-ISO-005: Data Integrity Constraints

The database shall enforce appropriate uniqueness and referential-integrity constraints.

For example, a learner-question pair shall not have multiple conflicting current learning-status records.

### NFR-ISO-006: Isolation Verification

Automated tests shall verify that:

- Learner A can access their own progress.
- Learner A cannot access Learner B's private progress.
- Learner A cannot modify Learner B's revision records.
- Learners cannot invoke administrator-only operations.

---

## 4. Reliability and Data Consistency

RUCH must reliably preserve learner progress and revision records.

### NFR-REL-001: Atomic Revision Updates

Recording a revision attempt and updating the corresponding latest revision state shall be performed as one consistent logical operation.

If a required database operation fails, the transaction shall not leave partially updated revision data.

### NFR-REL-002: Idempotent Submissions

Revision submissions shall support idempotency through a unique submission identifier.

Retrying the same submission shall not:

- Create duplicate revision attempts.
- Increment revision counts multiple times.
- Apply the same confidence score as multiple independent attempts.

### NFR-REL-003: Concurrent Update Safety

Concurrent revision submissions shall not cause:

- Lost updates.
- Incorrect revision counts.
- Inconsistent latest revision states.
- Duplicate processing of the same submission identifier.

Appropriate database locking, constraints, or concurrency-control mechanisms shall be used.

### NFR-REL-004: Learning Progress Durability

Successfully committed learning-status changes shall remain persisted across application restarts.

### NFR-REL-005: Historical Data Preservation

Marking a question as not learned shall not delete existing revision history.

Archiving or unpublishing educational content shall not automatically remove historical learner records.

### NFR-REL-006: Failure Handling

Application failures shall produce meaningful diagnostic logs without exposing sensitive information.

Unexpected errors shall return controlled responses to clients.

### NFR-REL-007: Database Backup and Recovery

Before public production launch, the platform shall have:

- A defined database backup strategy.
- A documented recovery procedure.
- A tested restoration process.

The backup frequency and recovery objectives shall be determined based on deployment requirements.

### NFR-REL-008: Availability Objective

For the initial hosted beta, RUCH shall target **99% monthly application availability**, excluding announced maintenance windows.

This is an initial operational objective, not a guaranteed service-level agreement.

---

## 5. Capacity and Scalability

The initial release shall prioritize simplicity while supporting a realistic early-user workload.

### NFR-CAP-001: Initial Registered User Target

The platform shall be designed to support approximately **100 registered learners** during the initial beta phase.

### NFR-CAP-002: Concurrent User Assumption

Initial performance testing shall assume approximately **10 concurrently active learners**.

Registered user count and concurrent user count shall be treated as separate capacity measures.

### NFR-CAP-003: Initial Content Volume

Initial capacity planning shall assume approximately:

- 100 registered learners.
- 10 concurrently active learners.
- 1,000 published questions.
- 2,000 revision attempts per day.

These figures are planning assumptions and do not represent measured production traffic.

### NFR-CAP-004: Scalability Approach

The initial application shall use a modular monolithic architecture.

Microservices, distributed caching, message brokers, and other infrastructure shall not be mandatory for the initial release.

### NFR-CAP-005: Growth Readiness

The architecture should allow future improvements such as:

- Database query optimization.
- Connection-pool tuning.
- Application instance scaling.
- Asynchronous background processing.
- Caching where supported by measured demand.
- Independent execution services for future coding challenges.

Scaling decisions shall be guided by observed bottlenecks and actual user demand.

### NFR-CAP-006: Capacity Validation

Load testing shall be conducted before public beta deployment to validate the initial concurrent-user and response-time assumptions.

---

## 6. Performance Requirements

Performance targets are defined for common backend operations.

These targets represent initial goals and may be revised after implementation and load testing.

### NFR-PERF-001: API Response Times

| API Operation | Initial p95 Target |
|---|---|
| Retrieve published chapters | Less than 300 ms |
| Retrieve questions within a chapter | Less than 500 ms |
| Retrieve a reference answer | Less than 300 ms |
| Mark a question as learned | Less than 500 ms |
| Mark a question as not learned | Less than 500 ms |
| Submit a revision confidence score | Less than 500 ms |
| Retrieve personal analytics | Less than 800 ms |

### NFR-PERF-002: Performance Measurement

API response-time targets shall be evaluated using the 95th-percentile latency (p95).

For example, a p95 target of 500 ms means that approximately 95% of measured requests should complete within 500 ms.

### NFR-PERF-003: Measurement Conditions

Initial performance targets shall be evaluated:

- Under the defined 10-concurrent-learner test workload.
- With representative chapter, question, and revision data.
- At the backend API boundary.
- Excluding external client network latency.
- After an appropriate application warm-up period.

The workload distribution and test environment shall be documented alongside test results.

### NFR-PERF-004: Database Query Efficiency

Database access shall avoid unnecessary repeated queries and inefficient data retrieval patterns.

Pagination shall be considered for growing question lists and revision histories.

### NFR-PERF-005: Analytics Performance

Personal analytics should be calculated efficiently without requiring unnecessary full-history scans for every request.

Optimization shall be introduced based on profiling and measured query performance.

### NFR-PERF-006: Performance Regression Detection

Significant performance regressions shall be investigated when detected through load tests, monitoring, or profiling.

---

## 7. Maintainability Requirements

RUCH shall be structured to support incremental feature development and long-term maintenance.

### NFR-MAIN-001: Modular Architecture

The backend shall follow a modular monolithic architecture with clear responsibility boundaries.

Planned functional areas include:

- Authentication and user management.
- Chapter and question management.
- Learning progress.
- Revision processing.
- Personal analytics.

### NFR-MAIN-002: Separation of Responsibilities

Application code shall separate:

- HTTP request handling.
- Business rules.
- Persistence operations.
- Security and authorization.
- Data transfer representations.

Business rules shall not be unnecessarily embedded in controllers.

### NFR-MAIN-003: Database Versioning

Database schema changes shall be managed through version-controlled migrations using Flyway.

Production schema changes shall not rely on uncontrolled automatic schema generation.

### NFR-MAIN-004: Configuration Management

Environment-specific settings shall be externalized where appropriate.

Sensitive settings shall not be hardcoded into application source files.

### NFR-MAIN-005: Code Readability

Code shall use meaningful names, clear responsibilities, and consistent formatting.

Complex business rules and architectural decisions shall be documented when necessary.

### NFR-MAIN-006: Dependency Management

Project dependencies shall be managed through Maven.

Unnecessary libraries and infrastructure dependencies should be avoided.

### NFR-MAIN-007: Architecture Documentation

Important design decisions and tradeoffs should be documented as the application evolves.

### NFR-MAIN-008: Incremental Development

New features shall be implemented in manageable units, with corresponding tests and documentation updates.

---

## 8. Testing and Quality Requirements

Automated testing shall be used to validate business behavior, security, and data consistency.

### NFR-TEST-001: Unit Testing

Core business rules shall have unit tests.

Examples include:

- Learning-status transitions.
- Revision eligibility.
- Confidence score validation.
- Learning completion calculations.
- Revision coverage calculations.
- Strength score calculations.

### NFR-TEST-002: Integration Testing

Integration tests shall verify interactions between application services, persistence components, and the database.

### NFR-TEST-003: Security Testing

Automated tests shall validate:

- Authentication requirements.
- Role-based authorization.
- Resource ownership.
- Cross-user access restrictions.
- Rejection of unauthorized requests.

### NFR-TEST-004: Idempotency Testing

Tests shall verify that repeated submissions with the same identifier do not create duplicate revision attempts.

### NFR-TEST-005: Concurrency Testing

Tests shall verify that concurrent revision submissions preserve consistent revision counts and latest revision state.

### NFR-TEST-006: API Validation Testing

Tests shall cover invalid payloads, unsupported values, missing required fields, and expected error responses.

### NFR-TEST-007: Test Coverage Target

Core business logic shall target at least **80% line coverage** as an initial quality goal.

Coverage percentage shall not replace meaningful assertions, edge-case testing, or integration testing.

### NFR-TEST-008: Continuous Integration

A CI pipeline shall execute automated build and test checks before changes are merged into the primary branch.

### NFR-TEST-009: Regression Testing

Existing tests shall continue to pass when new features or changes are introduced.

---

## 9. Observability and Operational Requirements

The platform shall provide sufficient visibility to diagnose failures and understand operational behavior.

### NFR-OPS-001: Application Logging

The backend shall produce structured or consistently formatted logs for important operational events and failures.

### NFR-OPS-002: Sensitive Data Protection

Logs shall not expose passwords, authentication tokens, private recall notes, or other sensitive credentials.

### NFR-OPS-003: Health Monitoring

The application shall expose an appropriately secured health-check mechanism suitable for development and deployment monitoring.

### NFR-OPS-004: Operational Metrics

The platform should support monitoring of:

- API request volume.
- API response times.
- HTTP error rates.
- Database connectivity.
- Application health.

### NFR-OPS-005: Diagnostic Context

Relevant errors should include sufficient request or correlation context to support troubleshooting without exposing private user information.

---

## 10. Architecture and Technology Constraints

The initial implementation shall use the following technology direction.

| Area | Technology |
|---|---|
| Backend | Java 21, Spring Boot |
| API | REST |
| Security | Spring Security |
| Persistence | Spring Data JPA / Hibernate |
| Database | MySQL |
| Database migrations | Flyway |
| Build | Maven |
| Backend testing | JUnit, Mockito, integration testing |
| Frontend | React (planned) |
| Architecture | Modular monolith |
| Source control | Git and GitHub |

---

## 11. Initial Quality Targets Summary

| Quality Attribute | Initial Target |
|---|---|
| Security | Authenticated access, role-based authorization, secure credential handling |
| Data isolation | No unauthorized cross-user access |
| Availability | 99% monthly target for hosted beta, excluding announced maintenance |
| Registered users | 100 |
| Concurrent active learners | 10 |
| Published questions | 1,000 |
| Revision attempts | 2,000 per day |
| Chapter retrieval p95 | Under 300 ms |
| Revision submission p95 | Under 500 ms |
| Personal analytics p95 | Under 800 ms |
| Core business logic coverage | Target 80% line coverage |
| Revision consistency | Atomic, idempotent, concurrency-safe |
| Database recovery | Documented and tested before public launch |

All numerical performance and capacity targets are initial assumptions pending validation.

---

## 12. Acceptance Criteria

- [x] Security requirements defined.
- [x] User data isolation requirements defined.
- [x] Reliability expectations documented.
- [x] Initial 100-user capacity target documented.
- [x] Performance goals defined as initial assumptions.
- [x] Maintainability expectations documented.
- [x] Testing expectations documented.
