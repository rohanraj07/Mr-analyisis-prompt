# Prompt 01 — Haiku: DDD Domain Violation Classifier

## Purpose
Classify a single dependency edge in your NX project graph as a DDD violation or not.
Run this for every cross-domain edge your algorithm flags.

## Model
`claude-haiku-4-5`

## When To Run
After exporting `nx-graph.json` and computing which edges cross domain boundaries
(i.e. `scope:X` → `scope:Y` where X ≠ Y, or any edge that violates DDD layer rules).

Run once per flagged edge. Collect all JSON responses into `violations.json`.

## Input Required
From `domain-map.txt` and `nx-graph.json`:
- `from_project` — name of the dependent project
- `from_tags` — its NX tags (e.g. `scope:retirement,type:feature`)
- `to_project` — name of the dependency project
- `to_tags` — its NX tags
- `implicit_or_explicit` — explicit = declared in project.json, implicit = found via AST import scan only

---

## The Prompt

```
You are a DDD architecture classifier for an NX monorepo using Angular (frontend) and NestJS (backend).

DOMAIN STRUCTURE RULES:
- type:domain     = core business logic, entities, value objects
                    ONLY depends on: type:util within same scope
- type:feature    = orchestration/use-case layer (Angular smart components, NestJS controllers)
                    ONLY depends on: type:domain, type:data-access within SAME scope
- type:data-access = API clients (Angular), repositories/services (NestJS)
                    ONLY depends on: type:domain within same scope
- type:ui         = Angular presentational components (dumb components)
                    ONLY depends on: type:feature, type:domain within same scope
- type:util       = pure utilities, helpers, constants
                    NO scope dependencies allowed — must be truly generic
- type:infrastructure = NestJS guards, interceptors, pipes, middleware
                    ONLY depends on: type:domain

ALLOWED dependency directions (strict DDD):
  ui → feature → domain → util
  ui → data-access → domain
  feature → data-access
  infrastructure → domain
  anything → scope:shared (if scope:shared/type:util only)

NEVER ALLOWED (these are violations):
  domain → feature        (domain cannot know about features)
  domain → ui             (domain cannot know about UI)
  domain → data-access    (domain cannot know about repos)
  util → any scoped lib   (util must be scope-free)
  feature → feature (cross-scope)
  domain → domain (cross-scope, unless scope:shared)
  data-access → feature
  ui → ui (cross-scope, unless scope:shared)

INPUT: One dependency edge to classify.
---
FROM PROJECT: {{from_project}}
FROM TAGS: {{from_tags}}

TO PROJECT: {{to_project}}
TO TAGS: {{to_tags}}

DEPENDENCY TYPE: {{explicit | implicit}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "violation": true | false,
  "severity": "critical" | "major" | "minor" | "none",
  "rule_broken": "<which specific DDD rule is broken, or null if no violation>",
  "layer_direction": "<e.g. domain→feature, cross-scope feature→feature, etc. or null>",
  "reason": "<one sentence maximum explaining the violation>",
  "fix": "<one sentence: what should change to resolve this>",
  "effort": "trivial" | "low" | "medium" | "high"
}
```

---

## Example Input

```
FROM PROJECT: retirement-calculator
FROM TAGS: scope:retirement,type:domain

TO PROJECT: planning-projection-feature
TO TAGS: scope:planning,type:feature

DEPENDENCY TYPE: implicit
```

## Example Output

```json
{
  "violation": true,
  "severity": "critical",
  "rule_broken": "domain→feature cross-scope",
  "layer_direction": "domain→feature",
  "reason": "A domain layer in scope:retirement cannot depend on a feature layer in scope:planning — domain must be unaware of orchestration and cannot cross bounded context boundaries.",
  "fix": "Extract the shared concept into a scope:shared/type:domain library and have both scopes depend on that instead.",
  "effort": "medium"
}
```

---

## How To Run At Scale

```bash
# Pseudo-code for batch processing
for each edge in cross_domain_edges:
  fill {{variables}} in prompt
  call claude-haiku-4-5
  append response to violations.json

# Filter results
cat violations.json | jq '[.[] | select(.violation == true)] | sort_by(.severity)'
```

## Output Aggregation

After all edges are processed, group by severity for Sonnet input:

```json
{
  "critical": [...violations...],
  "major": [...violations...],
  "minor": [...violations...],
  "totalViolations": 23,
  "criticalCount": 4
}
```

Feed only `critical` and `major` arrays into Prompt 06 (Sonnet diagnosis).
`minor` violations go into the migration backlog, not the live demo.