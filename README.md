# RUCH — Read. Understand. Code. Hone.

**A structured learning and revision platform for software developers.**

RUCH is a full-stack application designed to help developers strengthen technical knowledge through organized learning, active recall, confidence-based revision, and personalized progress tracking.

Instead of simply reading interview questions repeatedly, RUCH aims to help learners understand concepts, assess how well they remember them, and identify areas that need improvement.

> **Project Status:** Early Development — Functional requirements defined; backend foundation in progress.

---

## The Problem

Software developers preparing for technical interviews often face several challenges:

- Learning materials are scattered across multiple platforms.
- Tracking which concepts have been learned is difficult.
- Repeatedly reading answers can create a false sense of understanding.
- Weak areas are not always easy to identify.
- Revision progress is often tracked manually or not tracked at all.

RUCH aims to address these challenges through a structured learning and revision workflow.

## How RUCH Works

RUCH is designed around three core activities.

### 1. Learn

Learners browse technical chapters, explore questions, and study reference answers.

After understanding a question, the learner explicitly selects **Mark as Learned**.

Simply opening or reading a question does not automatically mark it as learned.

Learners can also reverse their learning status without losing historical revision records.

### 2. Revise

Previously learned questions become eligible for active recall.

During revision:

1. The question is displayed without its reference answer.
2. The learner attempts to recall the answer.
3. The reference answer is revealed for comparison.
4. The learner assigns a confidence score from 1 to 5.
5. The revision attempt is recorded for progress tracking.

Temporary typed recall notes remain in the frontend and are not stored in the backend.

### 3. Track Progress

RUCH is designed to provide personalized analytics, including:

- Learning completion percentage.
- Revision coverage.
- Confidence-based strength score.
- Weak questions requiring additional practice.
- Chapter-level progress.
- Historical revision scores and timestamps.

Each learner's progress is maintained independently.

---

## Core Features

| Feature | Description | Status |
|---|---|---|
| Role-based access | Administrator and learner roles | Planned |
| Chapter management | Create, update, publish, and archive chapters | Planned |
| Question management | Maintain questions and reference answers | Planned |
| Shared question bank | Centralized published content for all learners | Planned |
| Learn Mode | Study questions and explicitly track learning status | Planned |
| Revise Mode | Practice active recall using learned questions | Planned |
| Confidence scoring | Self-assessment using a 1–5 scale | Planned |
| Revision history | Preserve historical revision attempts | Planned |
| Personal analytics | Track completion, revision coverage, and strength | Planned |
| React frontend | Interactive learning and revision interface | Planned |

---

## Technology Stack

### Backend

- Java 21
- Spring Boot
- Spring Security
- Spring Data JPA / Hibernate
- REST APIs
- Maven
- JUnit and Mockito

### Database

- MySQL
- Flyway for database migrations

### Frontend (Planned)

- React
- JavaScript / TypeScript
- Monaco Editor (potential future enhancement)

### Development Tools

- IntelliJ IDEA
- Git and GitHub
- Postman

The initial architecture is a **modular monolith**. Additional infrastructure will be introduced when justified by product requirements and operational needs.

---

## Architecture

The initial target architecture is:

```text
                  +----------------------+
                  |    React Frontend    |
                  |       (Planned)      |
                  +----------+-----------+
                             |
                         REST APIs
                             |
                  +----------v-----------+
                  |  Spring Boot Backend |
                  |                      |
                  |  - Authentication    |
                  |  - Content Management|
                  |  - Learning Progress |
                  |  - Revision Engine   |
                  |  - Analytics         |
                  +----------+-----------+
                             |
                       JPA / Hibernate
                             |
                  +----------v-----------+
                  |        MySQL         |
                  +----------------------+
```

This diagram represents the planned architecture, not a fully implemented deployment.

### Design Principles

- Start with a modular monolith rather than premature microservices.
- Separate shared educational content from learner-specific data.
- Enforce authorization and data isolation at the backend.
- Preserve revision history when learning status changes.
- Handle revision submissions idempotently.
- Maintain transactional consistency between revision attempts and latest revision state.
- Introduce asynchronous processing only when there is a clear requirement.
---

## Getting Started

### Prerequisites

- Java 21
- Git
- An IDE such as IntelliJ IDEA

MySQL will be required when database-backed features are implemented.


## Development Philosophy

RUCH is being developed incrementally, with an emphasis on understanding the problem before selecting the technology.

The goal is to build a useful product while applying practical software engineering principles such as clean architecture, maintainability, testability, data consistency, and operational reliability.

The architecture and feature set will evolve based on actual requirements and user feedback.
