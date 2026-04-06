# Prompt 04 — Haiku: Phantom Dependency Detector

## Model: claude-haiku-4-5
## Input: suspectPairs array from Prompt 00 + exported types from each pair
## Purpose: Find implicit coupling that NX graph does not know about

---

## What This Finds

NX's project graph shows declared dependencies.
It cannot see implicit contracts — copy-pasted types, parallel response shapes,
shared string constants — that couple two libs behaviorally without a declared link.

This is dangerous because:
- NX does not rebuild the dependent when the source changes
- Divergence happens silently over months
- Runtime failures appear unrelated to the code change that caused them

This is especially common between Angular data-access libs (frontend)
and NestJS domain/infrastructure libs (backend) in the same domain scope.
They share an API contract but often have no declared NX link.

---

## How To Prepare The Input

From `prompt00-output.json`, take the `suspectPairs` array.

For each pair:
1. Find the Angular lib's `index.ts` — copy its exported interfaces and types
2. Find the NestJS lib's `index.ts` — copy its exported classes and DTOs
3. You only need the type/interface/class declarations — not implementations

Paste both into the prompt below.

---

## The Prompt

Copy everything below. Fill in the {{variables}}. Paste into gateway.

---

```
You are detecting hidden coupling in an NX monorepo (Angular + NestJS, DDD structure).

ARCHITECTURAL CONTEXT:
- Cross-domain dependencies are intentional in this codebase
- High lib count from deliberate splitting is intentional
- Focus only on IMPLICIT coupling: two projects sharing contracts
  WITHOUT a declared NX dependency between them

WHAT IS PHANTOM DEPENDENCY:
Two projects have no declared NX link but share implicit knowledge through:
1. TYPE_DUPLICATION    — same interface defined in both places, diverges silently
2. CONTRACT_SHARING    — Angular response type matches NestJS DTO by convention (copy-paste)
3. EVENT_COUPLING      — same event/message name as a string literal in both projects
4. ROUTE_COUPLING      — hardcoded API route path in Angular matching NestJS route decorator
5. SCHEMA_COUPLING     — database field names or JSON keys assumed identically in both

WHY THIS MATTERS:
If NestJS adds a required field to its DTO, Angular silently receives undefined.
No compile error. No NX rebuild triggered. Silent runtime failure.
The fix is not just adding a dependency link — it's extracting the contract
to a shared lib that both sides declare a dependency on.

INPUT: Suspect pairs (same scope, no declared NX link).
---
{{#each pair}}
PAIR {{index}}:
Angular lib: {{angularLib}} ({{angularTags}})
Exported types:
{{angularExportedTypes}}

NestJS lib: {{nestjsLib}} ({{nestjsTags}})
Exported types / DTOs:
{{nestjsExportedTypes}}

Declared NX dependency between them: NO
---
{{/each}}

For each pair, detect if implicit coupling exists.
Only flag if you see CONCRETE EVIDENCE — matching field names, identical structures,
or same string literals. Do not flag coincidental similar naming.

Respond ONLY in this exact JSON array. No markdown. No preamble.

[
  {
    "pairIndex": <1-based>,
    "angularLib": "<name>",
    "nestjsLib": "<name>",
    "sharedScope": "<scope:x>",
    "phantomCouplingDetected": true | false,
    "couplingType": "TYPE_DUPLICATION|CONTRACT_SHARING|EVENT_COUPLING|ROUTE_COUPLING|SCHEMA_COUPLING|none",
    "severity": "critical|major|minor|none",
    "evidence": "<one sentence describing the specific matching contract with field names>",
    "divergenceRisk": "<one sentence: what breaks in production if these diverge>",
    "fix": {
      "approach": "extract-to-shared-contracts-lib|add-nx-dependency|add-contract-tests",
      "targetLibName": "<suggested name for shared contracts lib, or null>",
      "effort": "hours|days"
    }
  }
]
```

---

## After You Get The Response

Save as: `nx-analysis/monorepo-a/prompt04-output.json`

For Prompt 06 (Sonnet), include only:
- Items where `phantomCouplingDetected` is `true`
- Items where `severity` is `"critical"` or `"major"`

Include only: `angularLib`, `nestjsLib`, `couplingType`, `severity`, `divergenceRisk`
Do not include full evidence detail in the Sonnet payload — keep it small.
