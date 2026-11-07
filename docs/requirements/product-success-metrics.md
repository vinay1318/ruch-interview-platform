# RUCH — Product Success Metrics

**Project:** RUCH (Read. Understand. Code. Hone.)  
**Document Type:** Product Success Metrics Specification  
**Version:** 1.0

---

## 1. Overview

RUCH is a chapter-based technical learning and revision platform designed to help software developers improve their knowledge through structured learning, active recall, confidence-based self-assessment, and personalized progress tracking.

This document defines the metrics used to evaluate whether RUCH delivers value to its learners and attracts sustained usage.

Product success shall be evaluated using two categories:

1. Learning engagement and self-assessed progress.
2. User adoption and retention.

These metrics are distinct from technical performance metrics such as API latency, system availability, and infrastructure utilization.

### 1.1 Objectives

The objectives of this document are to:

- Establish consistent definitions for learning progress metrics.
- Measure learner engagement with revision activities.
- Evaluate early user adoption.
- Identify whether learners return to the platform.
- Establish initial beta success targets.
- Ensure metrics are calculated consistently and respect user privacy.

### 1.2 Related Documents

- `docs/requirements/functional-requirements.md`
- `docs/requirements/non-functional-requirements.md`
- `docs/requirements/mvp-scope.md`

The formulas in this document shall remain consistent with the Functional Requirements Specification.

---

## 2. Metric Categories

RUCH shall distinguish between:

### 2.1 Learning Metrics

Metrics that describe an individual learner's progress and self-assessed confidence.

Examples:

- Learning completion.
- Revision coverage.
- Chapter strength.

### 2.2 Product Metrics

Metrics that describe adoption and ongoing engagement with the application.

Examples:

- Activated learners.
- Weekly returning learners.
- Returning-user rate.

### 2.3 Technical Performance Metrics

Metrics that describe the reliability and efficiency of the application.

Examples:

- API response times.
- Error rates.
- Application availability.
- Database query performance.

Technical performance metrics are governed by the Non-Functional Requirements Specification and shall not be confused with product success metrics.

---

## 3. Learning Completion

### MET-LEARN-001: Definition

Learning completion measures the percentage of currently published questions that a learner has explicitly marked as learned.

### Formula

Learning Completion (%) =

(Currently Learned Published Questions / Total Published Questions) × 100

### Example

A chapter contains 20 published questions.

A learner has marked 15 of those questions as learned.

Learning Completion = (15 / 20) × 100 = 75%

### Rules

- Only questions belonging to currently published chapters are included.
- Only currently published questions are included.
- Viewing a question does not count as learning completion.
- Marking a question as learned increases the learned count.
- Marking a question as not learned decreases the learned count.
- Historical revision activity does not automatically determine current learned status.
- Archived or unpublished questions are excluded from active calculations.
- When no published questions exist, learning completion is unavailable rather than 0%.

### Purpose

Learning completion indicates how much of the available learning material a learner has explicitly covered.

It does not independently measure knowledge accuracy or mastery.

---

## 4. Revision Coverage

### MET-REV-001: Definition

Revision coverage measures the percentage of currently learned questions that have been revised at least once.

### Formula

Revision Coverage (%) =

(Currently Learned Questions Revised at Least Once / Total Currently Learned Questions) × 100

### Example

A learner has marked 15 published questions as learned.

The learner has revised 10 of those questions at least once.

Revision Coverage = (10 / 15) × 100 = 66.67%

### Rules

- Only currently learned questions are included.
- Questions must belong to currently published chapters and remain published.
- A revision is counted when a valid revision attempt has been successfully recorded.
- Multiple revisions of the same question count as one covered question.
- Marking a question as not learned removes it from the active coverage calculation.
- Historical revision attempts remain preserved.
- If the learner marks the question as learned again, its previous revision history remains valid.
- When no questions are currently learned, revision coverage is unavailable.

### Purpose

Revision coverage indicates how much of the learner's currently learned material has been revisited through active recall.

It does not measure the frequency or quality of every revision attempt.

---

## 5. Chapter Strength

### MET-STR-001: Definition

Chapter strength measures a learner's self-assessed confidence across all currently learned questions within a chapter.

The metric uses the latest recorded confidence score for each currently learned question.

Questions that have not yet been revised contribute zero.

### Formula

Chapter Strength (%) =

(Sum of Latest Confidence Scores / (Currently Learned Questions × 5)) × 100

### Example

A chapter contains 20 published questions.

A learner has marked 15 questions as learned.

Of those 15 questions:

- 10 have been revised.
- 5 have never been revised.
- The latest confidence scores of the 10 revised questions sum to 35.

Chapter Strength = (35 / (15 × 5)) × 100 = 46.67%

### Rules

- Only currently learned, published questions within published chapters are included.
- The latest recorded confidence score is used for each question.
- Scores range from 1 to 5.
- Unrevised learned questions contribute zero.
- Historical scores are preserved when a question is marked as not learned.
- Relearning a question restores it to the active strength calculation using its retained latest score, if one exists.
- Archived or unpublished questions are excluded from active strength calculations.
- When no questions are currently learned, chapter strength is unavailable.

### Purpose

Chapter strength provides a combined indicator of revision participation and self-reported confidence.

It is not an objective measurement of technical mastery.

---

## 6. Initial User Adoption

### MET-ADOPT-001: Definition

Initial user adoption measures how many distinct registered learners perform at least one meaningful learning activity during the first 30 days after the beta launch.

For the initial MVP, a meaningful learning activity is defined as either:

- Successfully marking a published question as learned.
- Successfully submitting a valid revision confidence score.

Simply registering, logging in, or viewing a chapter does not count as activation.

### Formula

Activated Learners =

Count of Distinct Learners Who Complete at Least One Qualifying Learning Activity During the Measurement Window

### Initial Beta Target

**30 activated learners within the first 30 days after beta launch.**

The initial registered-user capacity target is 100 learners.

The activation target is an initial product hypothesis and may be adjusted after observing actual usage.

### Rules

- Each learner is counted once per measurement window.
- Administrator accounts are excluded.
- Test accounts and automated test activity are excluded where identifiable.
- Qualifying actions must be successfully persisted.
- Failed or rejected requests do not count.
- The first 30-day measurement window begins at the documented beta launch timestamp.

### Purpose

This metric indicates whether registered users are engaging with the product's core value rather than merely creating accounts.

### Additional Context Metric

RUCH may also calculate activation rate:

Activation Rate (%) =

(Activated Learners / Registered Learners in the Defined Cohort) × 100

Cohort membership and measurement dates must be defined consistently before comparing activation rates.

---

## 7. Returning-User Metric

### MET-RET-001: Definition

The weekly returning-user rate measures the proportion of learners active in one calendar week who perform another meaningful learning activity in the following calendar week.

For this metric, a meaningful learning activity uses the same qualifying actions defined in Section 6.

### Formula

Weekly Returning-User Rate (%) =

(Learners Active in Both Week W and Week W+1 / Learners Active in Week W) × 100

### Example

During Week 1, 20 distinct learners perform a meaningful learning activity.

During Week 2, 8 of those same learners perform another meaningful learning activity.

Weekly Returning-User Rate = (8 / 20) × 100 = 40%

### Initial Beta Target

**40% weekly returning-user rate**, evaluated once sufficient activity data is available.

This is a proposed initial target, not an established benchmark.

### Rules

- A learner must perform at least one qualifying activity in each of the two consecutive weeks.
- Each learner is counted only once per week.
- Merely opening the application or logging in does not count.
- Administrator and identifiable test activity are excluded.
- Weeks shall be measured consistently using UTC calendar-week boundaries.
- The metric shall be calculated only for completed weeks.
- When the preceding week has no qualifying active learners, the rate is unavailable.
- The metric may be volatile for small beta cohorts and should be interpreted alongside the number of eligible learners.

### Purpose

The returning-user metric indicates whether learners repeatedly engage with RUCH's core learning workflow.

Returning usage is an early signal of product value but does not independently establish learning effectiveness.

---

## 8. Product Success Dashboard

The MVP shall provide personal learning metrics to individual learners.

### 8.1 Learner Dashboard

| Metric | Visibility |
|---|---|
| Learning completion | Individual learner |
| Revision coverage | Individual learner |
| Chapter strength | Individual learner |
| Weak questions | Individual learner |
| Revision history | Individual learner |

### 8.2 Product-Level Evaluation

Initial adoption and retention metrics shall be used by the product owner to evaluate beta success.

A dedicated administrative analytics dashboard for adoption and retention is not required for the MVP.

Product-level metrics may initially be calculated through controlled database queries or internal reports.

Any such reporting shall respect learner privacy and application security requirements.

---

## 9. Measurement and Data Sources

Metrics shall use authoritative application records.

| Metric | Primary Data Source |
|---|---|
| Learning completion | Published questions and learner learning-status records |
| Revision coverage | Learning-status records and persisted revision history |
| Chapter strength | Latest revision state and current learning status |
| Activated learners | Successful learning-status transitions and revision submissions |
| Weekly returning users | Dated, persisted qualifying learning activities |

### 9.1 Activity Tracking Requirement

Accurate adoption and retention reporting requires sufficient historical activity information.

A current learning-status record alone may not reliably identify every qualifying action performed during an earlier measurement period.

The implementation shall therefore provide an auditable way to identify qualifying learning activities by user and timestamp.

This may be achieved through lightweight activity records or another equivalent reliable mechanism.

The implementation should avoid unnecessary event-streaming infrastructure for the MVP.

### 9.2 Privacy Requirements

- Individual learning data shall remain private.
- Product-level reporting should use aggregate results where possible.
- Reports shall not expose passwords, authentication credentials, or temporary recall notes.
- Product metrics shall not bypass backend authorization rules.

---

## 10. Product Metrics vs. Technical Performance Metrics

RUCH shall maintain a clear separation between product outcomes and technical system performance.

| Product Success Metric | Technical Performance Metric |
|---|---|
| Learning completion | API latency |
| Revision coverage | HTTP error rate |
| Chapter strength | Database query time |
| Activated learners | Concurrent request capacity |
| Weekly returning users | Application availability |

### Example

An application may respond to every request in 100 milliseconds but still provide little value if learners do not return.

Similarly, learners may find the product useful, but slow or unreliable APIs can eventually reduce engagement.

Both categories matter, but they answer different questions.

**Product metrics answer:** Are learners using RUCH and progressing through its learning workflows?

**Technical metrics answer:** Is RUCH operating efficiently, securely, and reliably?

---

## 11. Initial Beta Success Targets

| Metric | Initial Target | Measurement |
|---|---|---|
| Learning completion | Track per learner and chapter | Percentage |
| Revision coverage | Track per learner and chapter | Percentage |
| Chapter strength | Track per learner and chapter | Percentage |
| Initial adoption | 30 activated learners in first 30 days | Distinct learners |
| Returning-user rate | 40% week-over-week | Percentage |

Learning metrics are initially descriptive rather than assigned arbitrary universal success thresholds.

A learner who completes only a few chapters may still derive substantial value from the platform.

Product-level targets shall be reviewed after beta usage data becomes available.

---

## 12. Metric Validation

The implementation shall include tests covering:

- Correct numerator and denominator selection.
- Exclusion of archived and unpublished content.
- Marking questions as learned and not learned.
- Retention of historical revision records.
- Questions with no revision attempts.
- Multiple revisions of the same question.
- Zero-denominator handling.
- User data isolation.
- Distinct-user counting for adoption.
- Consecutive-week matching for retention.
- Exclusion of duplicate submissions from qualifying activity counts.

Metric calculations shall remain consistent with the functional requirements.

---

## 13. Acceptance Criteria

- [x] Learning completion metric defined.
- [x] Revision coverage metric defined.
- [x] Chapter strength metric defined.
- [x] Initial user adoption metric defined.
- [x] Returning-user metric defined.
- [x] Product success metrics clearly distinguished from technical performance metrics.

---

## 14. Review and Status

**Status:** Approved  
**Ticket:** TICKET-004  
**Deliverable:** Product Success Metrics Specification  
**Implementation:** Not applicable — metric definition and product measurement planning only.

### Approved Beta Targets

- **Initial adoption:** 30 activated learners within the first 30 days after beta launch.
- **Weekly returning-user rate:** 40% of learners active in one completed calendar week return and perform a qualifying learning activity in the following week.

These targets are initial product hypotheses and shall be validated using actual beta usage data.

Learning completion, revision coverage, and chapter strength shall follow the formulas and eligibility rules established in the Functional Requirements Specification.

Product success metrics shall remain separate from technical performance and reliability metrics.

This document establishes the initial product success measurement framework for RUCH.

Metric targets may be revised after beta launch based on observed adoption, learner behavior, and user feedback.