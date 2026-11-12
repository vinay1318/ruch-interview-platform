# T15 — Design Analytics Formulas

## 1. Objective

Define the chapter-level analytics formulas for the RUCH (Read, Understand, Code, Hone) learning and revision platform.

The analytics system measures how much a learner has studied, how much they have revised, how well they performed during revision, and their overall demonstrated mastery of learned questions.

The MVP will support four metrics:

1. Learning Completion
2. Revision Coverage
3. Revision Accuracy
4. Chapter Strength

All metrics are calculated independently for each learner and chapter.

---

## 2. Analytics Variables

| Variable | Definition |
|---|---|
| T | Total active questions in a chapter |
| L | Questions currently marked as learned |
| R | Distinct learned questions reviewed at least once |
| S | Sum of the latest valid revision scores for reviewed learned questions |
| U | Learned questions not yet reviewed (L − R) |

### Constraints

- T ≥ 0
- 0 ≤ L ≤ T
- 0 ≤ R ≤ L
- U = L − R
- Revision scores must be integers between 1 and 5.
- Only the latest revision score per question is used.
- Unlearned questions are excluded from revision analytics.

---

## 3. Learning Completion

### Definition

Learning Completion measures the percentage of chapter questions explicitly marked as learned.

### Formula

`Learning Completion (%) = (L / T) × 100`

### Example

A Java Collections chapter contains:

- Total questions: 20
- Learned questions: 15

Calculation:

`(15 / 20) × 100 = 75%`

**Learning Completion = 75%**

### Business Rules

- Only questions currently marked as learned count toward completion.
- Unmarking a learned question immediately reduces the learned count.
- Revision scores do not affect learning completion.
- If the chapter contains zero questions, completion is 0%.

---

## 4. Revision Coverage

### Definition

Revision Coverage measures the percentage of learned questions that have been revised at least once.

### Formula

`Revision Coverage (%) = (R / L) × 100`

### Example

- Learned questions: 15
- Reviewed questions: 9

Calculation:

`(9 / 15) × 100 = 60%`

**Revision Coverage = 60%**

### Business Rules

- Only learned questions are eligible for revision coverage.
- A question reviewed multiple times counts as one reviewed question.
- A question is considered reviewed after a valid revision score has been submitted.
- Unreviewed learned questions do not count toward the reviewed count.
- Unlearned questions are excluded.
- If no questions are learned, revision coverage is 0%.

---

## 5. Revision Accuracy

### Definition

Revision Accuracy measures the learner's average self-assessed performance across questions that have been revised.

It answers:

"How well do I know the questions I have already revised?"

### Formula

`Revision Accuracy (%) = (S / (5 × R)) × 100`

Where:

- S = Sum of latest revision scores
- R = Number of reviewed learned questions
- 5 = Maximum score per question

### Revision Score Mapping

| Score | Mastery Percentage |
|---|---|
| 1 | 20% |
| 2 | 40% |
| 3 | 60% |
| 4 | 80% |
| 5 | 100% |

### Example

A learner reviews five questions and assigns these scores:

| Question | Latest Score |
|---|---|
| Q1 | 5 |
| Q2 | 3 |
| Q3 | 4 |
| Q4 | 2 |
| Q5 | 5 |

Total score:

`S = 5 + 3 + 4 + 2 + 5 = 19`

Calculation:

`Revision Accuracy = (19 / (5 × 5)) × 100`

**Revision Accuracy = 76%**

### Business Rules

- Only reviewed and currently learned questions contribute.
- Only the latest score per question is considered.
- Revising a question again updates its score contribution.
- Previous scores may be retained as historical records but do not affect current accuracy.
- Unreviewed questions are excluded from the denominator.
- If no learned questions have been reviewed, revision accuracy is 0%.

### Important Distinction

Revision Accuracy is based on learner-provided self-assessment scores.

It does not represent independently verified answer correctness.

---

## 6. Chapter Strength

### Definition

Chapter Strength measures demonstrated revision mastery across all currently learned questions.

It combines revision coverage and revision accuracy into a single metric.

Unlike Revision Accuracy, Chapter Strength also accounts for learned questions that have not yet been revised.

### Approved Formula — Option B

`Chapter Strength (%) = (S / (5 × L)) × 100`

Where:

- S = Sum of latest revision scores for reviewed learned questions
- L = Total currently learned questions
- 5 = Maximum score per question

### Example

A chapter contains:

- Total questions: 20
- Learned questions: 15
- Reviewed questions: 9
- Average latest revision score: 4/5
- Unreviewed learned questions: 6

Total score:

`S = 9 × 4 = 36`

Calculation:

`Chapter Strength = (36 / (5 × 15)) × 100`

`Chapter Strength = (36 / 75) × 100`

**Chapter Strength = 48%**

### Relationship Between Metrics

Chapter Strength can also be calculated using:

`Chapter Strength (%) = (Revision Coverage (%) × Revision Accuracy (%)) / 100`

Example:

`(60 × 80) / 100 = 48%`

### Business Rules

- Unreviewed learned questions contribute zero to chapter strength.
- Unlearned questions are excluded from the denominator.
- Each reviewed learned question contributes its latest revision score.
- A question reviewed multiple times contributes only its latest score.
- If no questions are learned, chapter strength is 0%.
- Chapter strength reaches 100% only when every currently learned question has been reviewed and has a latest score of 5/5.
- Chapter strength can decrease if a learner changes a question's latest score to a lower value.

### Important Distinction

An unreviewed question contributing zero does not mean the learner has no knowledge of the topic.

It means mastery has not yet been demonstrated through RUCH's revision workflow.

---

## 7. Complete Analytics Example

Consider a Java Multithreading chapter.

| Metric | Value |
|---|---|
| Total questions | 20 |
| Learned questions | 15 |
| Reviewed questions | 9 |
| Unreviewed learned questions | 6 |
| Average latest revision score | 4/5 |
| Sum of latest revision scores | 36 |

### Calculations

**Learning Completion**

`(15 / 20) × 100 = 75%`

**Revision Coverage**

`(9 / 15) × 100 = 60%`

**Revision Accuracy**

`(36 / (5 × 9)) × 100 = 80%`

**Chapter Strength**

`(36 / (5 × 15)) × 100 = 48%`

### Final Analytics

| Metric | Result |
|---|---|
| Learning Completion | 75% |
| Revision Coverage | 60% |
| Revision Accuracy | 80% |
| Chapter Strength | 48% |

### Interpretation

The learner has completed 75% of the chapter's learning material.

They have revised 60% of the questions they marked as learned.

Their average revision performance is 80%.

Their demonstrated mastery across all learned questions is currently 48%.

---

## 8. Edge Cases

| Scenario | Expected Behavior |
|---|---|
| Chapter contains zero questions | All metrics return 0% |
| No questions are learned | All metrics return 0% |
| Questions learned but none reviewed | Revision Coverage, Revision Accuracy, and Chapter Strength return 0% |
| All questions learned but none reviewed | Learning Completion = 100%; remaining metrics = 0% |
| All learned questions reviewed with 5/5 | Coverage, Accuracy, and Strength = 100% |
| All learned questions reviewed with 3/5 | Coverage = 100%; Accuracy and Strength = 60% |
| Question reviewed multiple times | Use latest revision score only |
| Question marked as unlearned | Exclude from active revision calculations |
| Learned question never reviewed | Count toward Chapter Strength denominator with zero score contribution |
| Question's score decreases | Recalculate Revision Accuracy and Chapter Strength |
| Question's score increases | Recalculate Revision Accuracy and Chapter Strength |
| Question becomes learned again | Include in active calculations according to its current learning status and eligible revision records |

### Relearning Rule

For the MVP, when a learner marks a question as unlearned and later marks it as learned again, previously submitted revision scores remain stored as history but are not automatically restored as current mastery.

The question must be reviewed again to contribute to revision coverage, revision accuracy, and chapter strength.

This prevents stale revision scores from being treated as newly demonstrated mastery.

---

## 9. Data and Calculation Rules

### User Isolation

- Analytics must be calculated for the authenticated learner.
- A learner cannot access another learner's analytics.
- Shared chapter and question content must remain separate from personal learning progress.

### Score Handling

- Valid scores are integers from 1 to 5.
- Invalid scores must be rejected.
- Current mastery calculations use the latest eligible revision score.
- Historical revision attempts do not increase the reviewed-question count.

### Numeric Precision

- Calculations must use decimal or floating-point arithmetic rather than integer division.
- Internal calculations must retain sufficient precision.
- Displayed percentages are rounded to two decimal places.
- All metric values must remain between 0% and 100%.
- Division by zero must be handled explicitly.

### Data Consistency

- Only active chapter questions are included in analytics.
- Deleted or inactive questions must not contribute to active chapter analytics.
- Analytics must reflect the learner's current learning status.
- Revision records must not be counted multiple times because of database joins.
- Recalculation must produce consistent results from the same underlying data.

---

## 10. Implementation Guidance

The MVP backend will calculate analytics using the Java Spring Boot application and MySQL database.

The analytics logic should be encapsulated within the Analytics module.

### Suggested Backend Responsibilities

1. Retrieve total active question count for the chapter.
2. Retrieve the authenticated learner's currently learned question count.
3. Retrieve the number of eligible reviewed learned questions.
4. Retrieve the sum of their latest eligible revision scores.
5. Apply the four analytics formulas.
6. Handle zero-denominator cases.
7. Return the calculated percentages through the analytics API.

### Suggested Response Fields

- `chapterId`
- `totalQuestions`
- `learnedQuestions`
- `reviewedQuestions`
- `unreviewedLearnedQuestions`
- `learningCompletionPercentage`
- `revisionCoveragePercentage`
- `revisionAccuracyPercentage`
- `chapterStrengthPercentage`

The final endpoint path and response contract will be defined or confirmed in the relevant API implementation ticket.

### MVP Scope

- No AI-based scoring required.
- No spaced repetition algorithm required.
- No Redis caching required.
- No Kafka or asynchronous analytics processing required.
- No separate analytics microservice required.

Analytics can initially be calculated on demand.

---

## 11. Acceptance Criteria

- [x] Learning completion formula defined
- [x] Revision coverage formula defined
- [x] Chapter strength formula defined
- [x] Unlearned questions excluded from revision mastery
- [x] Unreviewed learned questions handled
- [x] Zero-question edge cases defined
- [x] Formulas documented with examples
- [x] Revision Accuracy metric added and defined
- [x] Revision score-to-percentage mapping documented
- [x] Repeated revision scoring rules documented
- [x] Undo Mark as Learned behavior documented
- [x] Data isolation and calculation rules documented

---

## 12. Final Design Decision

RUCH will use four chapter-level analytics metrics:

1. **Learning Completion** — Measures learning progress.
2. **Revision Coverage** — Measures revision participation.
3. **Revision Accuracy** — Measures self-assessed performance on reviewed questions.
4. **Chapter Strength** — Measures coverage-adjusted demonstrated mastery across learned questions.

Chapter Strength uses the approved Option B formula.

These formulas are finalized for the MVP design.

Backend implementation, database queries, automated testing, and frontend visualization will be completed in subsequent development tickets.