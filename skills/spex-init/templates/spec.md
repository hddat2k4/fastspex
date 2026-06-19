---
feature: <name>
status: draft        # draft | approved
---
# Spec: [FEATURE_NAME]

## Introduction
[Prose: what this builds & why; which files/modules it touches (brownfield) or the overall
shape (greenfield); what is explicitly NOT changed; dependencies on other specs.]

## Glossary   (optional — include when domain terms need pinning)
- **[Term]** — [definition].

## Requirements

### Requirement 1: [Short Title] — [Must | Should | Could]
**User Story:** As a [role], I want [capability], so that [benefit].

#### Acceptance Criteria
<!-- EARS, NUMBERED → criterion IDs read 1.1, 1.2 (restart per requirement). Patterns:
  Event-driven : WHEN [trigger], THE SYSTEM SHALL [response]
  Ubiquitous   : THE SYSTEM SHALL [response]
  State-driven : WHILE [state], THE SYSTEM SHALL [response]
  Unwanted     : IF [condition], THEN THE SYSTEM SHALL [response]
  Optional     : WHERE [feature included], THE SYSTEM SHALL [response]
  Precondition : GIVEN [precondition] WHEN [event] THEN [outcome] -->
1. WHEN [trigger], THE SYSTEM SHALL [response].
2. THE SYSTEM SHALL [response].
3. IF [error condition], THEN THE SYSTEM SHALL [error handling].

**Out of scope:** [what Requirement 1 does NOT cover; "—" if none].

### Requirement 2: [Short Title] — [Must | Should | Could]
**User Story:** As a [role], I want [capability], so that [benefit].

#### Acceptance Criteria
1. THE SYSTEM SHALL [behavior].

**Out of scope:** —

## Non-goals   (optional — overall boundary)
- [explicitly NOT building]

## Business Rules (Restated)   (optional — when pre-existing BR IDs exist)
- **BR-XXX-001** — [rule]. Implemented in Requirement N.
