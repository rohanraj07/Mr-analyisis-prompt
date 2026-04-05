# Prompt 05 — Haiku: RFC / ADR Need Detector

## Purpose
Determine whether a PR introduces a genuinely novel architectural pattern that requires
a new Architecture Decision Record. Prevents both ADR sprawl (too many) and ADR gaps
(novel patterns shipping without a decision record).

## Model
`claude-haiku-4-5` (detection only)
→ If `requiresADR: true`, escalate to Prompt 08 (Sonnet RFC Drafter)

## When To Run
On every merged PR, or pre-merge as a gate. Cheap enough to run on all of them.

## Pre-Computation Required (Algorithm, No AI)
1. Extract PR diff summary: files changed, new packages added to package.json, new NX libs created
2. Extract existing ADR titles from your ADR directory (titles only — not content)
3. Run static pattern detection first:
   - New npm package added? → flag
   - New NX library created? → flag  
   - New NestJS decorator pattern? → flag
   - New Angular state management pattern? → flag
   - If none flagged → skip this prompt entirely (most PRs)

---

## The Prompt

```
You are an architectural pattern detector for an NX monorepo using Angular and NestJS,
structured with Domain-Driven Design.

YOUR JOB:
Determine if this PR introduces a NEW architectural pattern not yet covered by existing ADRs.
Be conservative — most PRs don't need ADRs. Only flag if:
1. A genuinely new pattern is being established that others will follow
2. A significant technology or library is being introduced
3. A cross-cutting concern is being implemented for the first time
4. An existing ADR is being intentionally deviated from (needs an amendment or new ADR)

DO NOT flag for:
- Standard feature development following existing patterns
- Bug fixes
- Dependency version bumps (unless major version with breaking changes)
- Test additions
- Documentation updates
- Refactors that don't change the pattern

EXISTING ADR TITLES (for deduplication — if covered, do not flag):
{{#each existing_adrs}}
ADR-{{number}}: {{title}}
{{/each}}

INPUT: PR summary data.
---
PR TITLE: {{pr_title}}
PR DESCRIPTION: {{pr_description}}
AUTHOR SENIORITY: {{junior | mid | senior | principal}}
FILES CHANGED: {{files_changed_count}}
NEW PACKAGES ADDED TO PACKAGE.JSON: {{new_packages_list_or_none}}
NEW NX LIBRARIES CREATED: {{new_libs_list_or_none}}
NEW NX TAGS INTRODUCED: {{new_tags_or_none}}

KEY CODE PATTERNS DETECTED BY STATIC ANALYSIS:
{{static_patterns_list}}

SCOPE OF CHANGE:
- Angular changes: {{yes | no}}
- NestJS changes: {{yes | no}}
- Shared library changes: {{yes | no}}
- Infrastructure/config changes: {{yes | no}}
- Cross-scope changes: {{yes | no}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "requiresADR": true | false,
  "confidence": <0-100>,
  "reason": "<one sentence: why this does or does not need an ADR>",
  "patternType": "caching" | "security" | "api-design" | "state-management" | "library-structure" | "error-handling" | "testing" | "observability" | "cross-cutting" | "technology-adoption" | "none",
  "closestExistingADR": "<ADR-number if this is covered or closely related, or null>",
  "adrAction": "new" | "amend-existing" | "none",
  "noveltyAssessment": "<one sentence: what specifically is new about this pattern>",
  "whoShouldDecide": "author" | "team-lead" | "principal-architect" | "architecture-board"
}
```

---

## Example 1: Does NOT require ADR

```
PR TITLE: feat(retirement): add projection caching to retirement calculator
PR DESCRIPTION: Adds 5-minute TTL cache to projection service using existing CacheDecorator
NEW PACKAGES ADDED: none
NEW NX LIBRARIES CREATED: none
KEY PATTERNS: @Cacheable decorator usage, existing pattern
```

```json
{
  "requiresADR": false,
  "confidence": 92,
  "reason": "This follows the existing caching pattern established in ADR-002 — no new decisions needed.",
  "patternType": "none",
  "closestExistingADR": "ADR-002",
  "adrAction": "none",
  "noveltyAssessment": "No novelty — standard application of an existing ADR.",
  "whoShouldDecide": "author"
}
```

---

## Example 2: DOES require ADR

```
PR TITLE: feat(auth): implement WebSocket-based session invalidation
PR DESCRIPTION: Using Socket.io to push session invalidation events to Angular clients
NEW PACKAGES ADDED: socket.io, socket.io-client, @nestjs/websockets
NEW NX LIBRARIES CREATED: shared-websocket-gateway, auth-websocket-client
KEY PATTERNS: WebSocket module, Gateway decorator, new real-time pattern
```

```json
{
  "requiresADR": true,
  "confidence": 96,
  "reason": "Introduces WebSocket as a new real-time communication pattern — this affects security architecture, Angular state management, NestJS module structure, and Kubernetes deployment config.",
  "patternType": "technology-adoption",
  "closestExistingADR": null,
  "adrAction": "new",
  "noveltyAssessment": "First use of WebSocket in this monorepo — establishes patterns others will follow for real-time features.",
  "whoShouldDecide": "principal-architect"
}
```

---

## Routing Logic After This Prompt

```
requiresADR: false → done, no further action
requiresADR: true, adrAction: "new" → run Prompt 08 (Sonnet RFC Drafter)
requiresADR: true, adrAction: "amend-existing" → flag for manual review with closestExistingADR reference
whoShouldDecide: "architecture-board" → block merge until reviewed
whoShouldDecide: "principal-architect" → flag in PR, don't block
whoShouldDecide: "team-lead" → add comment to PR, non-blocking
```

---

## Output Aggregation (Weekly Report)

```json
{
  "prsAnalyzed": 47,
  "requiresADR": 3,
  "amendments": 1,
  "noAction": 43,
  "pendingDecisions": [
    { "pr": "#2891", "patternType": "technology-adoption", "assignedTo": "principal-architect" }
  ]
}
```