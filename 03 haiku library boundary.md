# Prompt 03 — Haiku: Library Boundary Analyzer

## Purpose
Determine whether a library should be split (fission) or flagged as a merge candidate (fusion).
Targets libraries where the algorithm detects poor export utilization or excessive coupling.

## Model
`claude-haiku-4-5`

## When To Run
Run for any library meeting ONE of these algorithmic criteria:
- More than 15 dependents AND cache hit rate < 60%
- More than 60% of consumers use fewer than 30% of exports
- Commit velocity > 30 commits/90 days AND more than 10 dependents
- Single library tagged with 2+ different `type:` values (mixed responsibilities)

## Pre-Computation Required (Algorithm, No AI)
Before running this prompt, compute from `import-frequency.txt` and `nx-graph.json`:
1. Total exports from the library (count exported symbols from `index.ts`)
2. Which exports each consumer project actually imports
3. Group consumers by their import pattern (consumers using same exports = same group)

This computation is cheap and deterministic. AI only gets the summary.

---

## The Prompt

```
You are an NX monorepo library boundary specialist working with Angular and NestJS codebases
structured using Domain-Driven Design.

CORE PRINCIPLE:
In NX, if library A changes, ALL its dependents must rebuild (unless cache hit).
The goal of library boundaries is: maximize cache reuse by minimizing unnecessary rebuilds.
A library with mixed responsibilities causes unrelated consumers to rebuild together.

SPLIT SIGNAL (fission candidate):
- Library has 2+ distinct consumer groups using non-overlapping export sets
- High commit velocity in one area causing rebuilds in unrelated consumers
- Library tagged with multiple type: values (mixed DDD layers)

MERGE SIGNAL (fusion candidate):
- Two libraries always imported together by the same consumers
- One library has fewer than 3 dependents and fewer than 200 LOC
- Libraries share the same domain scope and type tag

NX CACHING IMPACT OF SPLITTING:
If you split lib A into A-core and A-extended:
- Consumers of A-core no longer rebuild when A-extended changes
- Cache hit rate improvement = (consumers of A-core / total consumers) × (commit % in A-extended)

INPUT: Library analysis data.
---
LIBRARY NAME: {{library_name}}
TAGS: {{tags}}
LINES OF CODE: {{loc}}
TOTAL EXPORTED SYMBOLS: {{total_exports}}
TOTAL DEPENDENTS: {{total_dependents}}
CACHE HIT RATE (last 10 builds): {{cache_hit_rate}}%
COMMITS (last 90 days): {{commits_90d}}

CONSUMER GROUPS (pre-computed by algorithm):
Group 1: {{group1_count}} projects use only: [{{group1_exports}}]
Group 2: {{group2_count}} projects use only: [{{group2_exports}}]
Group 3 (if exists): {{group3_count}} projects use only: [{{group3_exports}}]

TOP 5 MOST CHANGED FILES IN THIS LIBRARY (last 90 days):
1. {{file1}} — {{commits1}} commits
2. {{file2}} — {{commits2}} commits
3. {{file3}} — {{commits3}} commits
4. {{file4}} — {{commits4}} commits
5. {{file5}} — {{commits5}} commits

SIBLING LIBRARIES (same scope, similar type):
{{sibling_libs_with_dependent_count}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "recommendation": "split" | "merge-candidate" | "keep",
  "confidence": <0-100>,
  "primaryReason": "<one sentence: the single most important reason for this recommendation>",
  "nxCacheImpact": "<describe how current boundaries hurt caching specifically>",
  "proposedChange": {
    "type": "fission" | "fusion" | "none",
    "parts": [
      {
        "suggestedName": "<new library name following your NX naming convention>",
        "suggestedTags": "<scope:x,type:y>",
        "exports": ["<export1>", "<export2>"],
        "consumers": <number>,
        "rationale": "<one sentence>",
        "estimatedCacheHitImprovement": "<e.g. +25% for these N consumers>"
      }
    ],
    "mergeTarget": "<library name to merge into, or null>",
    "migrationComplexity": "trivial" | "low" | "medium" | "high",
    "breakingChange": true | false
  },
  "implementationSteps": [
    "<step 1>",
    "<step 2>",
    "<step 3>"
  ],
  "doNotSplitIf": "<condition under which this recommendation should be ignored>"
}
```

---

## Example Input

```
LIBRARY NAME: shared-cache-service
TAGS: scope:shared,type:infrastructure
LINES OF CODE: 847
TOTAL EXPORTED SYMBOLS: 34
TOTAL DEPENDENTS: 28
CACHE HIT RATE (last 10 builds): 31%
COMMITS (last 90 days): 54

CONSUMER GROUPS:
Group 1: 22 projects use only: [InMemoryCacheService, CacheDecorator, CACHE_TTL_TOKEN]
Group 2: 6 projects use only: [RedisCacheService, RedisConnectionConfig, RedisHealthIndicator]

TOP 5 MOST CHANGED FILES:
1. redis-cache.service.ts — 38 commits
2. redis-connection.config.ts — 11 commits
3. in-memory-cache.service.ts — 3 commits
4. cache.decorator.ts — 1 commit
5. cache-ttl.token.ts — 1 commit

SIBLING LIBRARIES:
- shared-http-service: 12 dependents
- shared-logging-service: 31 dependents
```

## Example Output

```json
{
  "recommendation": "split",
  "confidence": 94,
  "primaryReason": "Redis code changes 38x in 90 days, forcing 22 projects that only use in-memory cache to rebuild unnecessarily every time.",
  "nxCacheImpact": "Redis churn (38 commits) invalidates cache for all 28 dependents, but 22 of them don't use Redis at all — they rebuild for zero benefit.",
  "proposedChange": {
    "type": "fission",
    "parts": [
      {
        "suggestedName": "shared-memory-cache-service",
        "suggestedTags": "scope:shared,type:infrastructure",
        "exports": ["InMemoryCacheService", "CacheDecorator", "CACHE_TTL_TOKEN"],
        "consumers": 22,
        "rationale": "Stable code (4 commits in 90 days) — separating it stops Redis churn from causing rebuilds.",
        "estimatedCacheHitImprovement": "+55-65% for these 22 consumers"
      },
      {
        "suggestedName": "shared-redis-cache-service",
        "suggestedTags": "scope:shared,type:infrastructure",
        "exports": ["RedisCacheService", "RedisConnectionConfig", "RedisHealthIndicator"],
        "consumers": 6,
        "rationale": "High-churn Redis code isolated — only 6 projects rebuild on every Redis change.",
        "estimatedCacheHitImprovement": "No improvement for these 6, but they were always rebuilding"
      }
    ],
    "mergeTarget": null,
    "migrationComplexity": "medium",
    "breakingChange": true
  },
  "implementationSteps": [
    "Create shared-memory-cache-service lib with nx generate",
    "Move InMemoryCacheService, CacheDecorator, CACHE_TTL_TOKEN to new lib",
    "Update 22 consumer imports via nx migrate or find-and-replace",
    "Update shared-cache-service to re-export from new lib temporarily (backwards compat)",
    "Remove re-exports in next sprint after all consumers updated",
    "Create shared-redis-cache-service and move Redis code"
  ],
  "doNotSplitIf": "A future feature requires InMemoryCacheService and RedisCacheService to share a common interface — validate this with the platform team first."
}
```

---

## Output Aggregation

Rank all libraries by: `confidence × estimated_consumers_affected`

Feed top 5 split candidates into Prompt 06 (Sonnet diagnosis) under `splitCandidates`.