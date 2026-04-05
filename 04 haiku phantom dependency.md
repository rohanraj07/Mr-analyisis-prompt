# Prompt 04 — Haiku: Phantom Dependency Detector

## Purpose
Detect implicit coupling between two NX projects that are NOT linked in the dependency graph
but share type contracts, copied interfaces, or behavioral assumptions.
These are your silent production incident generators.

## Model
`claude-haiku-4-5`

## When To Run
Run for pairs of projects where the algorithm detects:
- Similar type/interface names in both projects (string similarity > 80%)
- Same API response shapes used in Angular service and NestJS controller in different libs
- Shared string constants (event names, route paths, env var names) copy-pasted across libs
- No declared NX dependency between them

## Pre-Computation Required (Algorithm, No AI)
1. Extract all exported TypeScript interfaces and types from each project's `index.ts`
2. Run name-similarity comparison across all project pairs (Levenshtein distance or fuzzy match)
3. Flag pairs where similarity > 80% with no declared dependency
4. Extract only the flagged type definitions to feed into this prompt (not full files)

---

## The Prompt

```
You are detecting hidden coupling in an NX monorepo built with Angular (frontend) and
NestJS (backend), structured using Domain-Driven Design.

WHAT IS PHANTOM DEPENDENCY:
Two projects have no declared relationship in the NX graph, but they are implicitly coupled
through shared knowledge — copy-pasted types, parallel data shapes, or assumed contracts.
This is dangerous because:
- NX doesn't know to rebuild Project B when Project A changes
- Divergence happens silently over months
- Runtime failures appear unrelated to the actual code change that caused them
- No static analysis tool catches it — only reasoning can

PHANTOM COUPLING TYPES:
1. TYPE_DUPLICATION    - Same interface/type defined in two places; diverges over time
2. CONTRACT_SHARING    - Angular service response type matches NestJS controller DTO by convention
3. EVENT_COUPLING      - Same event/message names as string literals in both projects
4. ROUTE_COUPLING      - Hardcoded API route paths in Angular matching NestJS route decorators
5. ENV_COUPLING        - Same environment variable names assumed in both without shared source
6. SCHEMA_COUPLING     - Database column names or JSON field names assumed in both layers

INPUT: Two projects to compare.
---
PROJECT A: {{project_a_name}}
TAGS: {{project_a_tags}}
LAYER: {{angular-frontend | nestjs-backend | shared}}

EXPORTED TYPES FROM PROJECT A:
{{project_a_exported_types}}

PROJECT B: {{project_b_name}}
TAGS: {{project_b_tags}}
LAYER: {{angular-frontend | nestjs-backend | shared}}

EXPORTED TYPES FROM PROJECT B:
{{project_b_exported_types}}

DECLARED NX DEPENDENCY BETWEEN THEM: {{yes | no}}
SAME DOMAIN SCOPE: {{yes | no}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "phantomCouplingDetected": true | false,
  "couplingType": "TYPE_DUPLICATION" | "CONTRACT_SHARING" | "EVENT_COUPLING" | "ROUTE_COUPLING" | "ENV_COUPLING" | "SCHEMA_COUPLING" | "none",
  "severity": "critical" | "major" | "minor" | "none",
  "confidence": <0-100>,
  "evidence": [
    {
      "inProjectA": "<type name, constant, or route in Project A>",
      "inProjectB": "<matching type name, constant, or route in Project B>",
      "similarityAssessment": "<identical | structurally-same | semantically-similar>",
      "divergenceRisk": "<what breaks in production if these diverge>",
      "lastSafeToIgnore": "<condition under which this coupling is acceptable>"
    }
  ],
  "recommendation": "<one sentence: what to do about this>",
  "proposedFix": {
    "approach": "extract-to-shared-lib" | "add-nx-dependency" | "add-contract-tests" | "ignore",
    "targetLib": "<suggested shared library name, or null>",
    "effort": "trivial" | "low" | "medium" | "high",
    "breakingChange": true | false
  }
}
```

---

## Example Input

```
PROJECT A: retirement-data-access
TAGS: scope:retirement,type:data-access
LAYER: angular-frontend

EXPORTED TYPES FROM PROJECT A:
interface RetirementProjection {
  participantId: string;
  projectedBalance: number;
  retirementDate: Date;
  contributionRate: number;
  employerMatch: number;
}

interface ProjectionResponse {
  data: RetirementProjection;
  calculatedAt: string;
  modelVersion: string;
}

PROJECT B: retirement-projection-api
TAGS: scope:retirement,type:infrastructure
LAYER: nestjs-backend

EXPORTED TYPES FROM PROJECT B:
export class RetirementProjectionDto {
  participantId: string;
  projectedBalance: number;
  retirementDate: Date;
  contributionRate: number;
  employerMatch: number;
}

export class ProjectionResponseDto {
  data: RetirementProjectionDto;
  calculatedAt: string;
  modelVersion: string;
}

DECLARED NX DEPENDENCY BETWEEN THEM: no
SAME DOMAIN SCOPE: yes
```

## Example Output

```json
{
  "phantomCouplingDetected": true,
  "couplingType": "CONTRACT_SHARING",
  "severity": "critical",
  "confidence": 97,
  "evidence": [
    {
      "inProjectA": "RetirementProjection interface",
      "inProjectB": "RetirementProjectionDto class",
      "similarityAssessment": "structurally-same",
      "divergenceRisk": "If NestJS adds a required field to the DTO, Angular silently receives undefined for that field. No compile error. Silent data corruption at runtime.",
      "lastSafeToIgnore": "Never — same-domain frontend/backend sharing a response contract must have a single source of truth."
    },
    {
      "inProjectA": "ProjectionResponse.modelVersion: string",
      "inProjectB": "ProjectionResponseDto.modelVersion: string",
      "similarityAssessment": "identical",
      "divergenceRisk": "Type of modelVersion could change (e.g. to a structured object) in one place without updating the other.",
      "lastSafeToIgnore": "Never — this is the same field."
    }
  ],
  "recommendation": "Extract shared types to a scope:retirement/type:domain library and have both projects depend on it explicitly.",
  "proposedFix": {
    "approach": "extract-to-shared-lib",
    "targetLib": "retirement-domain-models",
    "effort": "low",
    "breakingChange": false
  }
}
```

---

## Output Aggregation

After processing all flagged pairs:

```json
{
  "totalPairsAnalyzed": 10,
  "phantomCouplingFound": 4,
  "critical": 2,
  "major": 2,
  "estimatedProductionRisk": "high",
  "topFindings": [...]
}
```

Feed `critical` findings directly into Prompt 06 (Sonnet diagnosis).
`major` findings go into the migration backlog.