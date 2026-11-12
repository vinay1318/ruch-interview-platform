# T16 — Architecture Decisions and Tradeoffs

## 1. Purpose

Document the major engineering decisions, alternatives, tradeoffs, assumptions, limitations, and future scaling options for the RUCH (Read, Understand, Code, Hone) platform.

The MVP prioritizes:

- Maintainability and clear module boundaries
- Security and learner data isolation
- Reliable learning and revision workflows
- Efficient access to shared educational content
- Simplicity of development and deployment
- Incremental scalability

## 2. Architecture Overview

### Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Angular with TypeScript |
| Backend | Java 21, Spring Boot |
| Architecture | Modular Monolith |
| Security | Spring Security, JWT |
| Persistence | Spring Data JPA, Hibernate |
| Primary Database | MySQL |
| Caching | Redis, Spring Cache |
| Communication | REST APIs over HTTPS |
| Messaging | No Kafka in MVP |

### Backend Modules

1. Authentication
2. User Management
3. Chapter Management
4. Question Management
5. Learning Progress
6. Revision
7. Analytics

Administrative operations are authorization-controlled capabilities within the relevant modules.

### High-Level Request Flow

**Read request for shared content:**

Angular → Spring Boot → Redis → MySQL on cache miss

**Write request:**

Angular → Spring Boot → MySQL → Cache invalidation after successful commit

**Learner-specific request:**

Angular → Spring Boot → MySQL

Redis is not part of learner progress, revision scoring, or analytics persistence in the MVP.

---

## 3. Decision 1 — Modular Monolith

### Selected Approach

Use a modular monolith built with Java 21 and Spring Boot.

Modules run within one application process while maintaining explicit responsibilities and boundaries.

### Alternatives Considered

- Traditional monolith
- Modular monolith
- Microservices

### Rationale

RUCH initially targets approximately 100 users and supports closely related workflows.

A modular monolith provides:

- Simpler development and deployment
- Straightforward database transactions
- Easier debugging and integration testing
- Lower operational overhead
- Reduced infrastructure requirements
- Clear separation of responsibilities

### Tradeoffs

**Advantages**

- One backend deployment artifact
- No distributed network calls between business modules
- Easier transaction management
- Faster initial development
- Lower operational complexity

**Disadvantages**

- Modules share application resources.
- Individual modules cannot be independently deployed.
- Scaling typically involves replicating the entire backend.
- Poorly enforced boundaries can cause tight coupling.
- A backend process failure can affect all modules.

### Engineering Guidelines

- Keep module responsibilities explicit.
- Avoid direct access to another module's internal repositories.
- Prefer service interfaces for cross-module interactions.
- Prevent circular dependencies.
- Separate controllers, services, repositories, and domain logic.
- Use module-level and integration tests.
- Keep shared infrastructure abstractions separate from business logic.

### Reconsider When

- Modules require independent deployment.
- Different workloads require substantially different scaling.
- Team ownership requires separate release cycles.
- Operational isolation becomes necessary.

---

## 4. Decision 2 — MySQL

### Selected Approach

Use MySQL as the primary relational database and durable source of truth.

### Alternatives Considered

- PostgreSQL
- MongoDB
- DynamoDB
- Other NoSQL databases

### Rationale

RUCH stores structured, relational data:

- Users
- Chapters
- Questions
- Learning progress
- Revision attempts
- Revision scores

These entities require relationships, constraints, and transactional consistency.

MySQL provides:

- ACID transactions through InnoDB
- Foreign keys
- Unique constraints
- SQL joins and aggregations
- Indexing
- Mature Spring Boot integration

### Tradeoffs

**Advantages**

- Strong relational consistency
- Mature tooling
- Straightforward transactional updates
- Suitable for structured application data
- Efficient queries when properly indexed

**Disadvantages**

- Schema evolution requires migrations.
- Poor indexing can cause performance problems.
- Large revision-history tables may require optimization.
- Scaling database writes is more complex than scaling stateless application instances.

### Why MySQL Instead of PostgreSQL?

Both databases are suitable for RUCH.

MySQL is selected as a practical project choice, not because PostgreSQL lacks the required capabilities.

The MVP does not require a database-specific feature that justifies switching.

### Engineering Guidelines

- Use InnoDB.
- Use `utf8mb4` encoding.
- Define primary and foreign keys.
- Add appropriate indexes and unique constraints.
- Use database migrations.
- Avoid unnecessary full-table scans.
- Enforce learner data isolation in application authorization and database queries.

---

## 5. Decision 3 — Spring Data JPA

### Selected Approach

Use Spring Data JPA with Hibernate for primary database access.

### Alternatives Considered

- JDBC
- JdbcTemplate
- MyBatis
- jOOQ

### Rationale

RUCH contains relational entities and standard CRUD operations.

JPA reduces repetitive persistence code and integrates with Spring transaction management.

### Advantages

- Repository abstractions
- Object-relational mapping
- Reduced boilerplate
- Transaction integration
- Entity relationship management
- Rapid development of CRUD operations

### Disadvantages

- N+1 query problems
- Lazy-loading exceptions
- Unexpected SQL generation
- Persistence-context memory overhead
- Complex aggregate queries may require custom SQL
- Poor fetching strategies can increase database load

### Engineering Guidelines

- Prefer appropriate lazy-loading strategies.
- Avoid returning JPA entities directly from APIs.
- Use DTOs and projections.
- Use pagination for large result sets.
- Monitor generated SQL.
- Define transaction boundaries.
- Avoid unnecessary eager fetching.
- Use native SQL when justified.

### Analytics Considerations

Chapter analytics require:

- Total question counts
- Learned question counts
- Reviewed question counts
- Latest revision score aggregation

Use efficient database aggregation queries rather than loading entire revision histories into application memory.

JPA remains the default persistence mechanism, but optimized SQL is permitted.

---

## 6. Decision 4 — Redis Caching

### Selected Approach

**Include Redis in the MVP for selective caching of shared chapter and question content.**

Use Spring Cache with Redis as the cache provider.

Redis is an optimization layer, not the primary database.

### 6.1 Rationale

RUCH contains shared educational content that may be requested repeatedly by different learners.

Examples:

- Chapter lists
- Chapter metadata
- Questions grouped by chapter
- Question details used in Learn Mode

This content is relatively read-heavy and changes less frequently than learner-specific progress.

Caching shared content can reduce repeated database queries and improve response times.

Redis also provides practical experience with distributed caching and cache invalidation.

### 6.2 Approved MVP Cache Scope

| Data | Cache in Redis? |
|---|---|
| Chapter list | Yes |
| Chapter metadata | Yes |
| Questions by chapter | Yes |
| Shared question details | Yes, when useful |
| User learning progress | No |
| Revision scores | No |
| Revision history | No |
| Learner analytics | No |
| JWT/session state | No |
| Billing data | No |

**Important:** Cached question content must not contain learner-specific state or private answer submissions.

### 6.3 Cache-Aside Pattern

The application will use the cache-aside pattern through Spring Cache.

**Cache hit:**

1. Learner requests chapter content.
2. Spring Boot checks Redis.
3. Cached content is returned.
4. MySQL is not queried for that content.

**Cache miss:**

1. Learner requests chapter content.
2. Redis has no valid entry.
3. Spring Boot queries MySQL.
4. The result is cached in Redis.
5. The response is returned to the learner.

MySQL remains authoritative.

### 6.4 Cache Keys

Proposed cache names and keys:

| Cache | Key |
|---|---|
| Chapter list | `chapters:all` |
| Chapter details | `chapters:{chapterId}` |
| Chapter questions | `questions:chapter:{chapterId}` |
| Question details | `questions:detail:{questionId}` |

These are logical naming conventions. The implementation may add version prefixes and serialization details.

Only cache DTOs containing appropriate shared content.

### 6.5 Cache Invalidation

Cache invalidation is required whenever an administrator changes shared content.

**Chapter created**

- Invalidate chapter list.

**Chapter updated**

- Invalidate chapter list.
- Invalidate the affected chapter detail.
- Invalidate related question-list caches if the change affects their response.

**Chapter deleted or deactivated**

- Invalidate chapter list.
- Invalidate affected chapter details.
- Invalidate related chapter question lists.
- Invalidate any affected individual question caches.

**Question created**

- Invalidate the affected chapter's question list.
- Invalidate chapter metadata or list caches if they contain question counts.

**Question updated**

- Invalidate the affected chapter's question list.
- Invalidate the individual question cache.
- Invalidate any other cached representation containing the changed question.

**Question deleted or deactivated**

- Invalidate the affected chapter's question list.
- Invalidate the individual question cache.
- Invalidate affected chapter metadata if required.

**Question moved between chapters**

- Invalidate the old chapter's question list.
- Invalidate the new chapter's question list.
- Invalidate the question detail cache.
- Invalidate any affected chapter summaries.

### 6.6 Transaction Consistency

Database writes must complete successfully before cache invalidation occurs.

Recommended approach:

1. Perform the administrative update within a database transaction.
2. Commit the MySQL transaction.
3. Trigger cache invalidation after the successful commit.

Do not evict caches before a transaction commits.

A rolled-back database update must not be treated as a successful content change.

**Consistency limitation:** MySQL commits and Redis invalidations are not one atomic transaction. Concurrent reads may briefly repopulate stale data, and failed invalidations may leave stale entries until expiry.

The MVP will use short-lived caching, after-commit invalidation, and monitoring. Stronger coordination may be introduced if strict freshness requirements emerge.

### 6.7 Cache Expiration

Initial proposed TTL:

**15 minutes for shared chapter and question content.**

The TTL is configurable and must be validated through testing.

The TTL is a safety mechanism, not a substitute for explicit invalidation.

A cache entry can be evicted before its TTL expires.

### 6.8 Redis Failure Handling

Redis must not become a mandatory dependency for core read operations when MySQL remains available.

Expected behavior:

- Redis available: use cached data when possible.
- Redis unavailable: query MySQL directly.
- Redis cache miss: query MySQL and attempt to populate the cache.
- Redis write failure: do not fail an otherwise successful read solely because caching failed.

A suitable Spring Cache error-handling strategy must be implemented and tested.

Cache invalidation failures require logging and monitoring because they may cause stale reads.

Redis outages may increase MySQL load.

### 6.9 Advantages

- Reduced repeated database reads
- Potentially lower response latency
- Shared cache across multiple backend instances
- Practical distributed caching experience
- Foundation for future performance improvements

### 6.10 Disadvantages

- Additional infrastructure
- Memory consumption
- Cache invalidation complexity
- Potential stale data
- Redis availability concerns
- Additional testing and monitoring requirements
- Cache serialization and compatibility considerations

### 6.11 Performance Validation

Caching must be evaluated using measurements.

Compare:

- Cache-hit response latency
- Cache-miss response latency
- Database query count
- Cache hit ratio
- Redis memory usage
- API performance with Redis disabled or unavailable

No performance improvement percentage is assumed before testing.

### 6.12 Scope Restrictions

Redis will not initially be used for:

- Persistent business data
- Revision score storage
- Learning progress storage
- Analytics result caching
- JWT token storage
- Distributed locking
- Messaging
- Job queues

These capabilities may be reconsidered separately when justified.

---

## 7. Decision 5 — No Kafka in MVP

### Selected Approach

Do not introduce Kafka in the initial MVP.

### Rationale

Current workflows are primarily synchronous:

- Authentication
- Chapter management
- Question management
- Learning progress updates
- Revision scoring
- Chapter analytics

These operations do not require a distributed event-streaming platform.

### Advantages

- Simpler architecture
- Lower resource consumption
- Easier debugging
- Reduced operational complexity
- Fewer distributed failure scenarios

### Limitations

- No durable distributed event-streaming infrastructure
- Long-running operations require alternative processing strategies
- Future high-volume asynchronous workloads may require messaging

### Future Use Cases

Kafka or another messaging solution may become useful for:

- AI interview processing events
- Notifications
- Audit event pipelines
- Analytics event ingestion
- Background workflows
- External integrations

### Alternatives Before Kafka

Evaluate simpler mechanisms first:

- Spring scheduled tasks
- Background workers
- Database-backed job queues
- Managed message queues

Kafka should be introduced only when its capabilities are justified by actual requirements.

---

## 8. Decision 6 — JWT Authentication

### Selected Approach

Use Spring Security with JWT authentication.

### Rationale

RUCH requires secure authentication and authorization for learners and administrators.

Stateless JWT authentication supports REST APIs without requiring a server-side HTTP session for every request.

### Advantages

- Suitable for REST APIs
- Integrates with Spring Security
- Supports stateless backend instances
- Simplifies some horizontal scaling scenarios

### Tradeoffs

- Token expiration requires careful handling.
- Logout and revocation require an explicit strategy.
- Token compromise is a security concern.
- Authentication alone does not enforce resource ownership.

### Security Rules

- Use HTTPS in deployed environments.
- Validate JWT signatures and expiration.
- Enforce Admin and Learner permissions.
- Protect signing keys.
- Validate ownership of learner-specific resources.
- Do not cache private learner information in shared Redis caches.
- Do not expose sensitive authentication data in logs.

---

## 9. Future Scaling Strategy

### Phase 1 — MVP

Target approximately 100 users.

Architecture:

- Angular frontend
- Java 21 Spring Boot modular monolith
- MySQL
- Spring Data JPA
- Redis for shared chapter/question caching
- JWT authentication

Priorities:

- Functional correctness
- Security
- Cache consistency
- Maintainability
- Basic monitoring

### Phase 2 — Performance Optimization

Potential improvements:

- Database indexing
- Query optimization
- Pagination
- Connection pool tuning
- Redis cache-hit monitoring
- Cache-key and TTL tuning
- API performance testing
- Load testing

### Phase 3 — Horizontal Scaling

Potential improvements:

- Multiple stateless Spring Boot instances
- Load balancer
- Shared Redis deployment
- Managed MySQL
- Centralized logging
- Monitoring and alerting

### Phase 4 — Asynchronous Processing

Potential additions:

- Background workers
- Managed message queues
- Kafka if justified
- Asynchronous AI interview processing
- Notification processing
- Background analytics

### Phase 5 — Commercial SaaS

Potential requirements:

- Subscription management
- Payment integration
- Tenant and user isolation
- Rate limiting
- Usage quotas
- Audit logging
- Backup and recovery
- Monitoring and alerting
- Operational reliability

### Phase 6 — Selective Service Extraction

Potential future service candidates:

- AI Interview Service
- Billing Service
- Notification Service
- Analytics Processing Service

Microservices are not mandatory for growth. Service extraction will depend on measured scaling, deployment, reliability, and organizational requirements.

---

## 10. Known Assumptions

1. The MVP initially targets approximately 100 users.
2. Initial traffic is expected to be moderate.
3. Chapter and question content is shared across learners.
4. Shared educational content is read more frequently than it is modified.
5. Administrative content updates are relatively infrequent.
6. MySQL remains the authoritative database.
7. Redis is used only for selected shared-content caches.
8. Learner progress and revision data remain in MySQL.
9. Analytics are calculated from authoritative data.
10. AI interview scoring is outside the initial MVP.
11. Subscription billing is outside the initial MVP.
12. One backend deployment is sufficient for initial development.
13. Cache TTL values are configurable and subject to performance testing.
14. Redis failure should not prevent core reads when MySQL is available.
15. Future scaling decisions will be based on measured requirements.

These assumptions are not production performance guarantees.

---

## 11. Known Limitations

### Availability

A single backend instance and primary database may introduce single points of failure.

### Redis Consistency

Cache entries may briefly contain stale content because database commits and cache invalidations are not atomic.

### Redis Operations

Redis introduces additional configuration, monitoring, memory management, and failure-handling requirements.

### Cache Invalidation

Administrative updates must invalidate all affected cache representations.

### Scalability

A modular monolith cannot independently scale its modules without architectural changes.

### Database Performance

Large revision-history datasets may require query optimization, indexing, or archival strategies.

### Analytics

Revision scores are learner-provided self-assessments rather than independently verified correctness measurements.

### AI Features

AI interviewing, automated evaluation, and advanced recommendations are deferred.

### SaaS Readiness

The MVP does not yet implement every requirement of a production subscription-based platform.

---

## 12. Architecture Principles

1. Prefer the simplest architecture that satisfies current requirements.
2. Maintain explicit module boundaries.
3. Keep MySQL as the durable source of truth.
4. Treat Redis as an optimization, not authoritative storage.
5. Cache only appropriate shared content in the MVP.
6. Invalidate caches after successful database commits.
7. Design for graceful degradation during Redis failures.
8. Preserve learner data isolation.
9. Measure performance before making scaling decisions.
10. Avoid premature distributed systems complexity.
11. Use relational constraints and transactions for data integrity.
12. Introduce new infrastructure when justified by requirements.
13. Preserve the ability to evolve the architecture incrementally.

---

## 13. Final Architecture Decision

RUCH will use:

- **Angular** for the frontend
- **Java 21 and Spring Boot** for the backend
- **Modular Monolith** architecture
- **MySQL** as the source of truth
- **Spring Data JPA** for persistence
- **Redis with Spring Cache** for shared chapter and question caching
- **Spring Security and JWT** for authentication
- **No Kafka** in the MVP

Redis is intentionally limited to shared, read-heavy content to provide caching benefits without introducing unnecessary consistency risks for learner-specific data.

The architecture will evolve based on actual product requirements, measured performance, and operational needs.

**Guiding principle: Build for current requirements while preserving reasonable options for future growth.**