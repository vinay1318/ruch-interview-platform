# RUCH — Functional Requirements

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** Functional Requirements Specification  
**Version:** 1.0

---

## 1. Overview

RUCH is a chapter-based learning and revision platform designed to help software developers strengthen their technical knowledge through structured learning, active recall, confidence-based self-assessment, and progress tracking.

The platform provides a centralized question bank maintained by an administrator, while allowing each learner to independently manage their learning progress, revision history, and performance analytics.

### 1.1 Objectives

The primary objectives of RUCH are to:

- Organize technical knowledge into structured chapters and questions.
- Provide a consistent reference question bank for all learners.
- Encourage intentional learning through explicit progress tracking.
- Improve knowledge retention through active recall and repeated revision.
- Help learners identify weak areas using confidence-based assessments.
- Provide personalized analytics to monitor learning and revision progress.

### 1.2 Initial Scope

The initial release focuses on:

1. User registration, authentication, and role-based access.
2. Administrator-managed chapters, questions, and reference answers.
3. A shared, published question bank.
4. Individual learner progress tracking.
5. Learn Mode.
6. Revise Mode.
7. Confidence-based revision scoring.
8. Personal learning and revision analytics.

Integrated coding environments, automated code execution, AI-assisted evaluations, and event-driven integrations are potential future enhancements and are outside the initial release scope.

---

## 2. User Roles and Permissions

RUCH supports two user roles.

### 2.1 Administrator

The administrator manages the platform's shared educational content.

**Permissions:**

- Create, update, publish, and archive chapters.
- Create, update, publish, and archive questions.
- Create and update reference answers.
- Organize questions within chapters.
- Manage the availability of educational content.

The initial release supports one master administrator account.

### 2.2 Learner

A learner uses the published content to study, revise, and monitor personal progress.

**Permissions:**

- Register and authenticate.
- Browse published chapters and questions.
- Read reference answers in Learn Mode.
- Mark questions as learned or not learned.
- Revise previously learned questions.
- Submit confidence scores.
- View personal learning and revision analytics.
- Review personal revision history.

Learners cannot create, modify, publish, or archive shared educational content.

### 2.3 Data Isolation

All learners access the same published question bank, but learning progress and revision records are maintained independently for each learner.

A learner must not be able to view or modify another learner's private progress, revision history, or analytics.

---

## 3. Shared Question Bank

### FR-001: Centralized Question Bank

The platform shall maintain a centralized repository of chapters, questions, and reference answers.

### FR-002: Shared Content

All learners shall access the same published educational content.

### FR-003: Independent Progress

Each learner shall maintain independent learning statuses, revision scores, revision histories, and analytics.

### FR-004: Published Content Visibility

Only published chapters and published questions shall be available in active learner workflows.

Draft, archived, or otherwise unpublished content shall not appear in the active learner question bank.

### FR-005: Content History Preservation

Archiving or unpublishing content shall not automatically delete historical learner progress or revision records.

---

## 4. Chapter Management

### FR-006: Create Chapter

The administrator shall be able to create a chapter representing a technical subject or topic.

Examples include:

- Java Fundamentals
- Java Collections
- Spring Boot
- Apache Kafka
- Database Management
- System Design
- Data Structures and Algorithms

### FR-007: Update Chapter

The administrator shall be able to update chapter information.

### FR-008: Publish Chapter

The administrator shall be able to publish a chapter to make its published questions available to learners.

### FR-009: Archive Chapter

The administrator shall be able to archive a chapter, removing it from active learner workflows while preserving historical records.

### FR-010: Chapter Organization

Questions shall be organized under their respective chapters.

---

## 5. Question Management

### FR-011: Create Question

The administrator shall be able to create questions within a chapter.

### FR-012: Reference Answer

Each question shall have a reference answer maintained by the administrator.

### FR-013: Update Question

The administrator shall be able to update question content and reference answers.

### FR-014: Publish Question

The administrator shall be able to publish a question, making it available to learners when its parent chapter is also published.

### FR-015: Archive Question

The administrator shall be able to archive a question without automatically deleting existing learning or revision history.

### FR-016: Shared Content Consistency

Changes to published question content shall be reflected in the shared question bank for all learners.

Learner-specific progress and revision records shall remain independent of shared content updates.

---

## 6. Learn Mode

Learn Mode enables learners to study published questions and understand their reference answers.

### FR-017: Browse Chapters

Learners shall be able to browse available published chapters.

### FR-018: Browse Questions

Learners shall be able to view published questions belonging to a selected published chapter.

### FR-019: View Reference Answers

Learners shall be able to read the reference answer associated with a question.

### FR-020: Mark as Learned

Learners shall be able to explicitly mark a question as learned.

A question becomes eligible for Revise Mode only after the learner marks it as learned.

### FR-021: Explicit Learning Confirmation

Viewing a chapter, opening a question, or reading a reference answer shall not automatically change learning status.

Only an explicit learner action shall update the status.

### FR-022: Mark as Not Learned

Learners shall be able to reverse a previously learned status by selecting **Mark as Not Learned**.

When a question is marked as not learned:

- It shall no longer be eligible for active revision.
- Its historical revision attempts shall be preserved.
- Its previous revision score, revision count, and last revision timestamp shall not be deleted.
- It shall no longer contribute to currently learned-question analytics.

### FR-023: Relearning

A learner shall be able to mark a previously unlearned question as learned again.

When this happens:

- The question becomes eligible for revision again.
- Previously recorded revision history remains available.
- Previously recorded revision state remains available.

### 6.1 Learn Mode Workflow

1. Learner selects a published chapter.
2. Learner selects a published question.
3. The platform displays the question and reference answer.
4. Learner studies the content.
5. Learner explicitly selects **Mark as Learned**.
6. The platform updates the learner's learning status.
7. The question becomes eligible for Revise Mode.

The learner may subsequently select **Mark as Not Learned** to reverse this status.

---

## 7. Revise Mode

Revise Mode helps learners strengthen knowledge retention through active recall.

### FR-024: Revision Eligibility

Only questions that are both published and currently marked as learned by the learner shall be eligible for revision.

The parent chapter must also be published.

### FR-025: Question-First Presentation

The platform shall initially display the question without revealing its reference answer.

### FR-026: Active Recall

Learners shall have an opportunity to recall the answer before revealing the reference answer.

### FR-027: Reveal Reference Answer

Learners shall be able to explicitly reveal the reference answer for comparison.

### FR-028: Temporary Recall Notes

Learners may type temporary recall notes in the frontend.

These notes shall:

- Remain in frontend state.
- Not be submitted to the backend.
- Not be stored in the database.
- Not become part of revision history.

### FR-029: Previous Revision Information

Before submitting a revision, the learner shall be able to view:

- Previous confidence score.
- Last revision timestamp.
- Total revision count.

For a question that has never been revised:

- Previous score is unavailable.
- Last revision timestamp is unavailable.
- Revision count is zero.

### FR-030: Submit Revision

After revealing the reference answer, the learner shall be able to submit a confidence score.

### FR-031: Continue Revision

After submitting a revision score, the learner shall be able to proceed to another eligible question.

### 7.1 Revise Mode Workflow

1. Learner selects a published chapter.
2. The platform identifies questions currently marked as learned.
3. Learner starts a revision session.
4. The platform displays an eligible question with its reference answer hidden.
5. Learner recalls the answer mentally or uses temporary frontend notes.
6. Learner reveals the reference answer.
7. Learner compares their recall with the reference answer.
8. Learner assigns a confidence score from 1 to 5.
9. The platform records the revision attempt.
10. Learner proceeds to another eligible question.

---

## 8. Confidence Scoring

### FR-032: Five-Point Confidence Scale

Each revision attempt shall use an integer confidence score from 1 to 5.

| Score | Description |
|---|---|
| 1 | Unable to recall the answer |
| 2 | Can recall only a small portion |
| 3 | Partial understanding or incomplete recall |
| 4 | Mostly correct, with minor gaps |
| 5 | Confident understanding and accurate explanation |

### FR-033: Score Validation

The backend shall accept only valid confidence scores within the defined range.

### FR-034: Revision History

Every successfully recorded revision attempt shall be preserved in the learner's revision history.

### FR-035: Latest Revision State

For each learner-question combination, the platform shall maintain:

- Latest confidence score.
- Last revision timestamp.
- Total revision count.

### FR-036: Revision Data Isolation

Revision history and latest revision state shall be associated with the authenticated learner and the corresponding question.

### FR-037: Idempotent Revision Submission

Each revision submission shall have an identifier that allows the backend to detect duplicate submissions.

Retrying the same submission shall not create duplicate revision attempts or increment the revision count more than once.

### FR-038: Consistent Revision Updates

Recording a revision attempt and updating its latest revision state shall be handled consistently as one logical operation.

Concurrent submissions shall not cause lost updates, incorrect counts, or inconsistent latest revision information.

---

## 9. Personal Analytics

RUCH shall provide learner-specific analytics based on published content, current learning status, and revision records.

### FR-039: Learned Questions

The platform shall display the number of currently published questions marked as learned by the learner.

### FR-040: Learning Completion Percentage

Learning completion shall represent the percentage of currently published questions that the learner has marked as learned.

**Formula:**

`Learning Completion (%) = (Learned Published Questions / Total Published Questions) × 100`

When no published questions exist, the percentage shall be treated as unavailable.

### FR-041: Revision Coverage

Revision coverage shall represent the percentage of currently learned questions that have been revised at least once.

**Formula:**

`Revision Coverage (%) = (Currently Learned Questions Revised at Least Once / Currently Learned Questions) × 100`

When no questions are currently learned, revision coverage shall be unavailable.

### FR-042: Strength Score

Strength score shall measure confidence across the learner's currently learned questions.

**Formula:**

`Strength (%) = (Sum of Latest Confidence Scores / (Currently Learned Questions × 5)) × 100`

Rules:

- Only currently learned, published questions contribute to the calculation.
- A learned question with no revision history contributes a score of zero.
- A question marked as not learned is excluded.
- When no questions are currently learned, strength is unavailable.

### FR-043: Weak Questions

The platform shall help learners identify questions with low latest confidence scores.

The exact weak-question threshold may be configured during analytics implementation.

### FR-044: Revision History

Learners shall be able to review their historical revision attempts, including confidence scores and timestamps.

### FR-045: Chapter-Level Analytics

The platform shall support learning and revision progress metrics for individual chapters.

### FR-046: Content Completion vs. Learner Completion

The platform shall distinguish between:

**Chapter Content Completion:** The extent to which chapter content has been published against an optional administrator-defined target.

**Learner Completion:** The extent to which an individual learner has marked currently published questions as learned.

These metrics shall not be treated as interchangeable.

### FR-047: Private Analytics

Personal analytics shall be accessible only to the authenticated learner, subject to any explicitly authorized administrative functionality introduced in future versions.

---

## 10. Core Business Rules

The following rules apply throughout the initial release.

| Rule ID | Business Rule |
|---|---|
| BR-001 | Only the administrator can manage shared educational content. |
| BR-002 | All learners access the same published question bank. |
| BR-003 | Learner progress is private and independently maintained. |
| BR-004 | Reading a question never automatically marks it as learned. |
| BR-005 | Learners can explicitly mark questions as learned or not learned. |
| BR-006 | Only currently learned, published questions are eligible for revision. |
| BR-007 | Reference answers remain hidden until explicitly revealed in Revise Mode. |
| BR-008 | Confidence scores must be integers between 1 and 5. |
| BR-009 | Historical revision attempts are preserved when learning status changes. |
| BR-010 | Typed recall notes are not stored or transmitted to the backend. |
| BR-011 | Duplicate revision submissions must not create duplicate attempts. |
| BR-012 | Revision history and latest revision state must remain consistent. |
| BR-013 | Archived or unpublished content is excluded from active learner workflows. |
| BR-014 | Analytics must reflect current learning status and published content. |

---

## 11. Example User Journey

Consider a learner studying Java Collections.

**Step 1 — Learning**

The learner opens the Java Collections chapter and selects the question:

*How does HashMap work internally?*

The learner reads the reference answer and selects **Mark as Learned**.

The question is now eligible for revision.

**Step 2 — First Revision**

The learner opens Revise Mode.

RUCH displays the question without its reference answer.

The learner recalls the explanation, reveals the reference answer, and submits confidence score **3**.

RUCH records:

- Latest confidence score: 3
- Revision count: 1
- Last revision timestamp: Time of submission

**Step 3 — Subsequent Revision**

The learner revises the same question again and submits confidence score **4**.

RUCH updates the latest revision state:

- Latest confidence score: 4
- Revision count: 2
- Last revision timestamp: Time of second submission

Both revision attempts remain available in history.

**Step 4 — Mark as Not Learned**

The learner decides that their understanding is insufficient and selects **Mark as Not Learned**.

The question is removed from active revision eligibility.

Its historical scores and revision count remain preserved.

**Step 5 — Relearning**

The learner studies the question again and selects **Mark as Learned**.

The question becomes eligible for revision again, with its previous revision history intact.

---

## 12. Future Enhancements

The following capabilities may be evaluated in future releases:

- Browser-based coding editor.
- Java code compilation and execution in isolated environments.
- Automated coding test cases.
- AI-assisted code reviews and feedback.
- Timed coding challenges and mock interviews.
- Event-driven workflows using Apache Kafka.
- Advanced learning recommendations and revision scheduling.

These enhancements are not required for completion of the initial functional scope.

---

## 13. Acceptance Criteria

Ticket 1 is considered complete when the following requirements are documented and agreed upon:

- [x] Administrator and learner roles defined.
- [x] Shared question bank behavior documented.
- [x] Chapter and question management requirements defined.
- [x] Learn Mode workflow documented.
- [x] Explicit Mark as Learned behavior documented.
- [x] Mark as Not Learned and relearning behavior documented.
- [x] Revise Mode workflow documented.
- [x] Confidence scoring requirements defined.
- [x] Revision history preservation documented.
- [x] Personal analytics requirements defined.

---

## 14. Approval and Status

**Status:** Approved  
**Ticket:** TICKET-001  
**Deliverable:** Functional Requirements Specification  
**Implementation:** Not applicable — documentation and requirements definition only.

This document establishes the functional baseline for the RUCH initial release. Subsequent system design, API design, database modeling, and implementation decisions should align with these requirements.

Changes to the functional baseline should be reflected in this document as the product evolves.