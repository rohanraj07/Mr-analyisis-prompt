# Prompt 02 — Haiku: Cache Anti-Pattern Detector

## Model: claude-haiku-4-5
## Input: topOffenders array from Prompt 00 + actual source file content
## Purpose: Find code patterns inside high-impact libs that defeat NX caching

---

## What This Prompt Does

Cache anti-patterns are always wrong — regardless of architectural decisions.
A timestamp embedded at build time breaks NX cache on every run.
This prompt finds those patterns in your highest-impact libs.

Run once per high-impact lib (topOffenders from Prompt 00).
Prioritize libs with high impactScore — these cause the most rebuild pain.

---

## How To Prepare The Input

From `prompt00-output.json`, take the `topOffenders` array.
For each lib (start with the top 3-5 by impactScore):

1. Find the lib's source directory in your monorepo
2. Open these files (in priority order):
   - `src/index.ts` (barrel file — most common cache buster)
   - `src/lib/*.config.ts` (config files)
   - `src/lib/*.service.ts` (NestJS) or `src/lib/*.service.ts` (Angular)
   - `environment*.ts` files if present
3. Paste the content into the prompt below

You can batch up to 3 libs in one prompt call to save time.

---

## The Prompt

Copy everything below. Fill in the {{variables}}. Paste into gateway.

---

```
You are an NX build cache expert analyzing source files for patterns that
prevent NX Cloud from caching build outputs correctly.

ARCHITECTURAL CONTEXT:
- This monorepo deliberately uses cross-domain dependencies for reuse
- It has many libs from deliberate anti-bloat splitting
- Both of those are correct decisions — do not comment on them
- Focus ONLY on code patterns that defeat the NX content-hash cache

HOW NX CACHING WORKS:
NX caches task outputs based on: input file hashes + task config hash.
If any input changes → task reruns → cache miss.
Cache busters are patterns where the BUILD OUTPUT changes
without the SOURCE FILES changing — or where trivial changes cause wide invalidation.

ANTI-PATTERNS TO DETECT:

1. TIMESTAMP
   Date.now(), new Date(), BUILD_TIME embedded in source at build time.
   Every build produces different output → 0% cache hit rate.

2. RANDOM
   Math.random(), uuid() called at module initialization level.
   Same problem — different output every build.

3. ENV_LEAK
   process.env.SOME_VAR embedded in build output (not runtime-resolved).
   Cache miss whenever env changes between CI runs.

4. GIT_INFO
   Git commit hash, branch name, or dirty flag embedded at build time.
   Every commit = new build output = cache miss.

5. BARREL_TRAP
   index.ts re-exports everything including rarely-used heavy modules.
   Any change to any exported module forces all consumers to rebuild —
   even if they only import 1 of 30 exports.
   Look for: export * from './heavy-rarely-changed-module'
   mixed with: export * from './stable-frequently-imported-module'

6. DYNAMIC_IMPORT
   import() with paths constructed from variables at module level.
   NX cannot statically analyze dependencies → conservative rebuild.

7. SIDE_EFFECT_IMPORT
   Module-level code that calls external APIs, reads files, or
   writes to global state at import time.

INPUT: Source files from high-impact libs.
---
LIB 1: {{lib_name}}
TAGS: {{tags}}
IMPACT SCORE: {{from prompt00 topOffenders}}
DEPENDENTS: {{number}}

FILE: {{file_path e.g. src/index.ts}}
CONTENT:
{{paste file content here — keep under 200 lines per file}}

FILE: {{file_path e.g. src/lib/service.ts}}
CONTENT:
{{paste file content here}}

---
LIB 2 (if batching): {{lib_name}}
[same structure]
---

Respond ONLY in this exact JSON. No markdown. No preamble.

{
  "libs": [
    {
      "project": "<lib name>",
      "hasAntiPattern": true | false,
      "patterns": [
        {
          "type": "TIMESTAMP|RANDOM|ENV_LEAK|GIT_INFO|BARREL_TRAP|DYNAMIC_IMPORT|SIDE_EFFECT_IMPORT",
          "file": "<filename>",
          "locationHint": "<approximate line or code snippet showing the problem>",
          "impact": "high|medium|low",
          "explanation": "<one sentence: why this causes cache misses>",
          "fix": "<one sentence: exact change to make>",
          "fixExample": "<optional: 1-3 line code snippet showing the fix>"
        }
      ],
      "overallCacheImpact": "high|medium|low|none",
      "estimatedHitRateImprovement": "<e.g. +40-60% if fixed, or null if uncertain>",
      "quickestWin": "<which pattern to fix first for maximum cache improvement>"
    }
  ]
}
```

---

## After You Get The Response

Save as: `nx-analysis/monorepo-a/prompt02-output.json`

For Prompt 06 (Sonnet), extract only:
- Libs where `overallCacheImpact` is `"high"`
- Include only the `quickestWin` field per lib — not full pattern detail

Keep Sonnet input minimal.
