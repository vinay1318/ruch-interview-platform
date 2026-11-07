# RUCH — User Workflows

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** User Workflow Specification  
**Version:** 1.0

---

## 1. Overview

RUCH is a chapter-based technical learning and revision platform that helps software developers learn technical concepts, practice active recall, evaluate their confidence, and track personal progress.

This document defines the end-to-end workflows for the two primary user roles:

- **Administrator:** Creates, manages, and publishes shared educational content.
- **Learner:** Studies published content, tracks learning progress, revises concepts, and reviews personal analytics.

The purpose of this document is to describe how users interact with RUCH and how the system responds to their actions.

### 1.1 Objectives

This document aims to:

1. Establish clear administrator and learner journeys.
2. Identify the steps required to complete each workflow.
3. Describe system responses and expected outcomes.
4. Identify important validation and failure scenarios.
5. Clarify transitions between learning, revision, and analytics.
6. Provide a reference for API, database, and frontend design.

### 1.2 Related Documents

- `docs/requirements/functional-requirements.md`
- `docs/requirements/non-functional-requirements.md`
- `docs/requirements/mvp-scope.md`
- `docs/requirements/product-success-metrics.md`

### 1.3 Scope

This document covers seven MVP workflows:

- WF-ADM-001: Administrator Content Creation
- WF-ADM-002: Administrator Publishing
- WF-LRN-001: Learner Registration and Login
- WF-LRN-002: First-Time Learn Mode
- WF-LRN-003: Mark as Learned / Not Learned
- WF-LRN-004: Revision
- WF-LRN-005: Returning Learner

AI scoring, spaced repetition, coding execution, and other post-MVP features are excluded.

---

## 2. User Roles

### 2.1 Administrator

RUCH initially supports one master administrator account.

The administrator can:

- Create and edit chapters.
- Create and edit questions.
- Maintain reference answers.
- Publish, unpublish, and archive content.
- Access the React administrator dashboard.

The administrator account is provisioned through a controlled setup process.

Public registration does not grant administrator privileges.

### 2.2 Learner

A learner can:

- Register and authenticate.
- Browse published chapters and questions.
- Read reference answers.
- Mark questions as learned or not learned.
- Revise eligible questions.
- Submit confidence scores.
- View personal analytics and revision history.

Learners cannot modify the shared question bank or access another learner's private progress.

---

## 3. WF-ADM-001: Administrator Content Creation

### 3.1 Objective

Allow the administrator to create educational chapters, questions, and reference answers using the React administrator dashboard.

### 3.2 Preconditions

- The administrator account exists.
- The administrator is authenticated.
- The administrator has the required authorization.

### 3.3 Main Workflow

1. Administrator logs in to RUCH.
2. Administrator opens the admin dashboard.
3. Administrator selects the chapter-management section.
4. Administrator chooses to create a chapter.
5. The application displays the chapter creation form.
6. Administrator enters the required chapter information.
7. Administrator submits the form.
8. The backend validates the submitted information.
9. The backend persists the chapter.
10. The application displays the created chapter.
11. Administrator opens the chapter.
12. Administrator selects the option to add a question.
13. Administrator enters the question content.
14. Administrator enters the corresponding reference answer.
15. Administrator submits the question form.
16. The backend validates and saves the question under the selected chapter.
17. The application displays the saved question.
18. Administrator may continue adding questions.

### 3.4 Expected Outcome

- The chapter is persisted.
- Questions are associated with the correct chapter.
- Reference answers are stored.
- Newly created content is not automatically exposed to learners before publication.

### 3.5 Alternative and Failure Scenarios

**Invalid input**

- The backend rejects invalid or incomplete required fields.
- The frontend displays a meaningful validation message.
- The administrator can correct the information and retry.

**Unauthorized request**

- The backend rejects requests without administrator authorization.

**Database failure**

- The application displays an appropriate error.
- A failed save does not report successful content creation.

### 3.6 Postconditions

The administrator has created educational content that can subsequently be reviewed, edited, and published.

---

## 4. WF-ADM-002: Administrator Publishing

### 4.1 Objective

Allow the administrator to control which chapters and questions are visible to learners.

### 4.2 Preconditions

- The administrator is authenticated.
- The relevant chapter or question exists.
- The administrator has permission to manage the content.

### 4.3 Main Workflow

1. Administrator opens the admin dashboard.
2. Administrator navigates to an existing chapter.
3. Administrator reviews the chapter information.
4. Administrator reviews its questions and reference answers.
5. Administrator selects the publish action for the chapter.
6. The frontend sends the publication request.
7. The backend validates the request and administrator permissions.
8. The backend updates the chapter's publication state.
9. Administrator publishes the relevant questions.
10. The backend updates their publication states.
11. The frontend displays the updated publication status.
12. Learners can access questions only when both the chapter and the corresponding questions are published.

### 4.4 Expected Outcome

Published chapters and questions become available through learner-facing APIs and the React learner interface.

### 4.5 Unpublishing Workflow

1. Administrator selects an existing published chapter or question.
2. Administrator chooses the unpublish action.
3. The backend updates the publication state.
4. The affected content is removed from active learner browsing and revision eligibility.
5. Existing learner progress and revision history remain preserved.

### 4.6 Archiving Workflow

1. Administrator selects a chapter or question.
2. Administrator chooses the archive action.
3. The backend updates the content's archive state.
4. Archived content is excluded from active learner workflows and analytics.
5. Historical learner records remain preserved.

### 4.7 Alternative and Failure Scenarios

**Incomplete content**

The backend shall reject publication when applicable content validation requirements are not satisfied.

**Unauthorized publication**

Learners and unauthenticated users cannot publish or unpublish content.

**Content unavailable after publication changes**

Learners attempting to access content that is no longer published shall receive an appropriate response.

### 4.8 Postconditions

Content visibility reflects the current publication state without deleting historical learning data.

---

## 5. WF-LRN-001: Learner Registration and Login

### 5.1 Objective

Allow learners to create accounts and securely access their personal learning environment.

### 5.2 Preconditions

- The RUCH application is available.
- The learner has access to the registration or login interface.

### 5.3 Registration Workflow

1. Learner opens RUCH.
2. Learner selects the registration option.
3. The application displays the registration form.
4. Learner enters the required account information.
5. Learner submits the form.
6. The backend validates the request.
7. The backend verifies that the account does not conflict with an existing account.
8. The backend securely hashes the password.
9. The backend creates a learner account.
10. The application confirms successful registration.
11. Learner proceeds to login.

### 5.4 Login Workflow

1. Learner opens the login page.
2. Learner enters their credentials.
3. Learner submits the login form.
4. The backend validates the credentials.
5. The authentication mechanism establishes an authenticated session or equivalent security context.
6. The learner is directed to the learner interface.
7. The learner can access their own learning progress and analytics.

The specific authentication mechanism shall be finalized during security design.

### 5.5 Alternative and Failure Scenarios

**Existing account**

The registration request is rejected according to the application's account uniqueness rules.

**Invalid credentials**

The application displays a generic authentication failure message without exposing sensitive account information.

**Unauthorized access**

Unauthenticated users cannot access protected learner resources.

**Role restrictions**

Learners cannot access administrator-only endpoints or dashboard operations.

### 5.6 Postconditions

The learner has a registered account and can authenticate to access their private learning environment.

---

## 6. WF-LRN-002: First-Time Learn Mode

### 6.1 Objective

Allow a newly registered learner to discover chapters, read questions, and begin learning.

### 6.2 Preconditions

- The learner is authenticated.
- At least one published chapter containing published questions is available.

### 6.3 Main Workflow

1. Learner logs in to RUCH.
2. The application displays the learner dashboard or chapter list.
3. Learner selects Learn Mode.
4. The application retrieves published chapters.
5. Learner selects a chapter.
6. The application displays the chapter's published questions.
7. Learner selects a question.
8. The application displays the question and its reference answer.
9. Learner reads and studies the reference answer.
10. The question remains not learned until the learner explicitly changes its status.
11. Learner may mark the question as learned.
12. Learner may continue to another question or return to the chapter list.

### 6.4 Expected Outcome

The learner can study published educational content without automatically modifying their learning progress.

### 6.5 First-Time State

For a newly registered learner:

- No questions are initially marked as learned.
- No revision attempts exist.
- No previous confidence scores exist.
- No revision history exists.
- Learning completion is initially 0% when published questions are available.
- Revision coverage and strength are unavailable when no questions are learned.

### 6.6 Alternative and Failure Scenarios

**No published chapters**

The application displays an appropriate empty state.

**Chapter contains no published questions**

The application displays an appropriate empty state.

**Content unpublished during browsing**

The backend rejects subsequent access to content that is no longer eligible for learner viewing.

### 6.7 Postconditions

The learner understands how to navigate Learn Mode and can begin explicitly tracking learned questions.

---

## 7. WF-LRN-003: Mark as Learned / Not Learned

### 7.1 Objective

Allow learners to explicitly control which questions they consider learned and eligible for revision.

### 7.2 Preconditions

- The learner is authenticated.
- The question exists and is currently published.
- The question belongs to a published chapter.

### 7.3 Mark as Learned Workflow

1. Learner opens a question in Learn Mode.
2. Learner studies the reference answer.
3. Learner selects **Mark as Learned**.
4. The frontend sends the request to the backend.
5. The backend identifies the authenticated learner.
6. The backend validates the question's eligibility.
7. The backend creates or updates the learner-specific learning-status record.
8. The question is marked as learned.
9. The frontend displays the updated learning status.
10. The question becomes eligible for revision.

### 7.4 Mark as Not Learned Workflow

1. Learner opens a previously learned question.
2. Learner selects **Mark as Not Learned**.
3. The frontend sends the request to the backend.
4. The backend identifies the authenticated learner.
5. The backend updates the learner-specific learning status.
6. The question is removed from active revision eligibility.
7. The frontend displays the updated status.
8. Historical revision attempts, previous scores, and timestamps remain preserved.

### 7.5 Relearning Workflow

1. Learner opens a question previously marked as not learned.
2. Learner reviews the reference answer.
3. Learner selects **Mark as Learned**.
4. The backend updates the learning status.
5. The question becomes eligible for revision again.
6. Existing revision history and latest revision state remain intact.

### 7.6 Expected Outcome

Learning status accurately reflects the learner's explicit choices.

Changing learning status does not delete historical revision data.

### 7.7 Alternative and Failure Scenarios

**Unauthorized update**

A learner cannot modify another learner's learning status.

**Unpublished content**

The backend rejects attempts to update learning status for ineligible content.

**Repeated status selection**

Repeating an already-applied learning-status action shall not create conflicting records.

### 7.8 Postconditions

The learner's active learning status and revision eligibility are updated consistently.

---

## 8. WF-LRN-004: Revision Workflow

### 8.1 Objective

Allow learners to practice active recall, compare their answers against reference material, and record confidence scores.

### 8.2 Preconditions

- The learner is authenticated.
- The learner has at least one currently learned question.
- The question and its chapter remain published.

### 8.3 Main Workflow

1. Learner opens Revise Mode.
2. The application retrieves eligible questions.
3. Learner selects a chapter or eligible question.
4. The application displays the question without revealing the reference answer.
5. The application displays previous revision information, if available:
    - Previous confidence score.
    - Last revision date.
    - Total revision count.
6. Learner attempts to recall the answer independently.
7. Learner may enter temporary recall notes.
8. Temporary notes remain in frontend memory and are not transmitted to the backend.
9. Learner selects **Reveal Answer**.
10. The application displays the reference answer.
11. Learner compares their recall against the reference answer.
12. Learner selects a confidence score between 1 and 5.
13. Learner submits the revision.
14. The frontend sends a submission identifier and confidence score to the backend.
15. The backend validates authentication, ownership, score range, and question eligibility.
16. The backend records the revision attempt and updates the latest revision state within a consistent transaction.
17. The backend returns a successful response.
18. The frontend displays the updated revision information.
19. Learner may continue to another eligible question.

### 8.4 First Revision Behavior

When a learner revises a question for the first time:

- Previous score is unavailable.
- Last revision date is unavailable.
- Previous revision count is zero.

After a successful submission:

- The first revision attempt is stored.
- The latest score is updated.
- The last revision timestamp is recorded.
- The revision count becomes one.

### 8.5 Subsequent Revision Behavior

When a learner revises the same question again:

- The previous score is available.
- The previous revision date is available.
- The existing revision count is displayed.
- A new successful submission adds another historical attempt.
- The latest revision state is updated.

### 8.6 Idempotency and Retry Behavior

If a client retries a submission using the same submission identifier:

- The backend shall not create a duplicate revision attempt.
- The revision count shall not increase again.
- The same logical submission shall not be processed twice.

### 8.7 Concurrent Submission Behavior

Concurrent submissions shall be handled without corrupting revision history, revision counts, or latest revision state.

### 8.8 Alternative and Failure Scenarios

**No eligible questions**

The application displays an appropriate empty state and directs the learner toward Learn Mode.

**Invalid confidence score**

The backend rejects scores outside the supported range.

**Question no longer eligible**

The backend rejects submissions for questions that are no longer learned or published.

**Network failure**

The frontend may retry the same logical submission using its original submission identifier.

**Database failure**

The transaction shall not leave partially updated revision records.

### 8.9 Postconditions

A successful revision attempt is persisted and reflected in the learner's revision history, latest revision state, and personal analytics.

---

## 9. WF-LRN-005: Returning Learner Workflow

### 9.1 Objective

Allow an existing learner to resume learning, review progress, and continue revising previously learned questions.

### 9.2 Preconditions

- The learner has an existing account.
- The learner has previously used RUCH.
- The application is available.

### 9.3 Main Workflow

1. Learner returns to RUCH.
2. Learner logs in if authentication is required.
3. After successful authentication, the application directs the learner to their personal dashboard.
4. The application retrieves the learner's current learning progress and revision information.
5. The dashboard displays:
    - Overall learning completion.
    - Overall revision coverage.
    - Overall confidence-based strength.
    - Chapter-level learning progress.
    - Weak questions requiring additional practice.
    - Available published chapters.
6. The learner reviews their current progress.
7. The learner chooses one of the following actions:
    - **Continue Learning:** Select a published chapter and open Learn Mode.
    - **Start Revision:** Open Revise Mode and select eligible learned questions.
    - **Review Progress:** Examine chapter-level analytics and revision history.
8. If the learner chooses Learn Mode, the application displays the selected chapter's published questions and their current learning statuses.
9. If the learner chooses Revise Mode, the application displays eligible questions and supports active recall, answer reveal, and confidence scoring.
10. After successful learning-status changes or revision submissions, the application updates the learner's progress and analytics.
11. The learner may return to the personal dashboard at any time.

### 9.3.1 Dashboard-First Navigation Rule

The personal dashboard shall be the default landing page for returning authenticated learners.

The application shall not automatically redirect returning learners to their last visited chapter.

Learners shall explicitly choose whether to continue learning, start revision, or review analytics.

This behavior is intended to give learners visibility into their progress and control over their next learning activity.

### 9.4 Expected Outcome

The learner can continue from their persisted progress without losing historical learning or revision information.

### 9.5 Content Change Behavior

If an administrator has unpublished or archived content since the learner's previous visit:

- The affected content is excluded from active learner workflows.
- Historical learner records remain preserved.
- Active analytics are recalculated using currently eligible published content.

### 9.6 Alternative and Failure Scenarios

**No currently learned questions**

The learner may continue using Learn Mode.

**No published content**

The application displays an appropriate empty state.

**Authentication expired**

The learner is required to authenticate again before accessing protected resources.

### 9.7 Postconditions

The learner can resume studying and revising with their existing progress intact.

---

## 10. Workflow Relationships

The primary learner journey follows this sequence:

```text
Registration / Login
        |
        v
   Learner Dashboard
        |
        v
     Learn Mode
        |
        v
    Select Chapter
        |
        v
    Select Question
        |
        v
   Read Reference Answer
        |
        v
    Mark as Learned
        |
        v
     Revise Mode
        |
        v
   Attempt Active Recall
        |
        v
    Reveal Answer
        |
        v
  Submit Confidence Score
        |
        v
   View Personal Analytics
        |
        v
  Continue Learning / Revision
```

Learners may move between Learn Mode, Revise Mode, and the dashboard whenever their current permissions and question eligibility allow it.

---

## 11. Workflow-Level Security Rules

The following rules apply across all workflows:

1. Protected operations require authentication.
2. Administrator operations require administrator authorization.
3. Learner progress belongs to the authenticated learner.
4. Learners cannot access or modify another learner's private records.
5. Learners cannot modify the shared question bank.
6. Backend validation is required even when frontend validation exists.
7. Unpublished or archived content is excluded from active learner workflows.
8. Sensitive credentials and temporary recall notes shall not be exposed through application logs or analytics integrations.

---

## 12. Workflow-Level Data Integrity Rules

The following rules apply to learning and revision operations:

1. Viewing a question does not automatically mark it as learned.
2. Learning status changes require explicit learner actions.
3. Marking a question as not learned preserves historical revision records.
4. Relearning restores revision eligibility without resetting previous history.
5. Revision submissions must use valid confidence scores.
6. Revision submissions must be idempotent.
7. Revision history and latest revision state must remain consistent.
8. Concurrent operations must not corrupt revision counts.
9. Active learner analytics must reflect current content publication status.
10. Historical learner records must remain preserved when content is unpublished or archived.

---

## 13. Workflow Acceptance Scenarios

### Scenario 1: Administrator Creates and Publishes Content

**Given** an authenticated administrator  
**When** the administrator creates a chapter, adds a question and reference answer, and publishes the required content  
**Then** the published question becomes available to learners.

### Scenario 2: Learner Registers and Logs In

**Given** a new learner  
**When** the learner successfully registers and authenticates  
**Then** the learner can access their private learning environment.

### Scenario 3: First-Time Learner Views a Question

**Given** an authenticated learner with no previous learning activity  
**When** the learner opens and reads a published question  
**Then** the question remains not learned until explicitly marked.

### Scenario 4: Learner Marks a Question as Learned

**Given** an authenticated learner viewing an eligible question  
**When** the learner selects Mark as Learned  
**Then** the question becomes eligible for revision.

### Scenario 5: Learner Marks a Question as Not Learned

**Given** a previously learned question with revision history  
**When** the learner selects Mark as Not Learned  
**Then** the question is removed from active revision eligibility while historical records remain preserved.

### Scenario 6: Learner Completes a Revision

**Given** an eligible learned question  
**When** the learner reveals the reference answer and submits a valid confidence score  
**Then** the attempt is stored and the latest revision state is updated.

### Scenario 7: Learner Retries a Revision Submission

**Given** a revision submission that was already successfully processed  
**When** the same submission identifier is submitted again  
**Then** no duplicate attempt or additional revision count is created.

### Scenario 8: Returning Learner Resumes Learning

**Given** a learner with existing progress and revision history  
**When** the learner returns and authenticates  
**Then** their existing progress is available and they can continue learning or revising.

---

## 14. Acceptance Criteria

- [x] Admin content creation workflow documented.
- [x] Admin publishing workflow documented.
- [x] Learner registration and login workflow documented.
- [x] First-time Learn Mode workflow documented.
- [x] Mark as Learned workflow documented.
- [x] Revision workflow documented.
- [x] Returning learner workflow documented.

---

## 15. Review and Status

**Status:** Draft — Pending Review  
**Ticket:** TICKET-005  
**Deliverable:** User Workflow Specification  
**Implementation:** Not applicable — user workflow documentation only.

This document defines the initial administrator and learner workflows for the RUCH MVP.

The workflows shall guide API design, frontend navigation, persistence design, and acceptance testing.

Changes to the workflows shall remain consistent with the approved functional requirements and MVP scope.