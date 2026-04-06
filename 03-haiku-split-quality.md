# Prompt 03 — Haiku: Split Quality Analyzer

## Model: claude-haiku-4-5
## Input: libClusters array from Prompt 00 output
## Purpose: Assess whether lib splits achieved real cache isolation or just naming overhead

---

## The Core Question

This monorepo split libs intentionally to fight bloat and improve caching.
That was the right decision. But splits can go wrong in a specific way:

```
GOOD SPLIT (achieved cache isolation):
  original-lib → lib-a + lib-b
  lib-a and lib-b are independent
  changing lib-a does NOT rebuild lib-b's consumers
  → cache benefit realized

BAD SPLIT (just naming overhead):
  original-lib → lib-a + lib-b + lib-c
  lib-a imports from lib-b imports from lib-c
  they're still tightly coupled
  changing lib-c still triggers rebuild of lib-a's consumers
  → no cache benefit, just more complexity
```

This prompt identifies bad splits — not to re-consolidate them,
but to redraw the boundaries at better seams.

The fix is always: **redraw the split, not undo it.**

---

## The Prompt

Copy everything below. Fill in the {{variables}}. Paste into gateway.

---

```
You are analyzing the quality of library splits in an NX monorepo.

ARCHITECTURAL CONTEXT:
- Libs were deliberately split from bloated originals to improve caching
- High lib count is CORRECT and INTENTIONAL
- Do NOT recommend consolidating or merging libs — that goes against the architectural direction
- Your job: assess whether splits were drawn at the RIGHT SEAMS
- If a split was drawn poorly: recommend REDRAWING it, not reversing it

WHY SPLIT SEAMS MATTER FOR NX CACHING:
NX caches at the lib level. If lib-a and lib-b are tightly coupled post-split
(lib-a imports lib-b or vice versa), then changing lib-b still causes lib-a
to rebuild — exactly what the split was supposed to prevent.

A good split seam separates: stable contracts from volatile implementations,
or separates two genuinely independent feature areas.

A bad split seam is drawn along: naming/folder conventions rather than
change frequency or dependency direction.

WHAT TO LOOK FOR IN EACH CLUSTER:
1. Do the libs in this cluster import from each other heavily?
   (circular or chain dependencies post-split = bad seam)
2. Do they all change together? (commit correlation = bad seam)
3. Do they all get consumed together by the same set of apps?
   (if yes: the split didn't reduce blast radius)
4. Is there a clear stable/volatile boundary that was missed?
   (the RIGHT seam was nearby but not where the split was drawn)

INPUT: Lib clusters identified by Prompt 00.
---
LIB CLUSTERS:
{{paste libClusters array from prompt00-output.json here}}
---

For each cluster, assess split quality and recommend action.

RECOMMENDATION OPTIONS:
- GOOD_SPLIT: seams are correct, cache isolation is achieved
- REDRAW_SEAM: split exists but boundary is wrong — describe the better seam
- EXTRACT_CONTRACTS: stable type contracts are mixed with volatile impl —
  extract types into a separate contracts lib that rarely changes
- CLARIFY_BOUNDARIES: libs are the right shape but ownership/responsibility
  is unclear causing everyone to touch everything — needs governance not restructure

Respond ONLY in this exact JSON array. No markdown. No preamble.

[
  {
    "clusterName": "<from input>",
    "libs": ["<lib1>", "<lib2>"],
    "splitQuality": "good|poor|mixed",
    "recommendation": "GOOD_SPLIT|REDRAW_SEAM|EXTRACT_CONTRACTS|CLARIFY_BOUNDARIES",
    "finding": "<two sentences: what's wrong with the current seam if not good>",
    "betterSeam": "<one sentence: where should the boundary actually be drawn, or null if good>",
    "cacheImpact": "<one sentence: what cache benefit would the better seam deliver>",
    "concreteAction": "<one sentence: exactly what to move where>",
    "effort": "days|weeks|none",
    "risk": "low|medium|high"
  }
]
```

---

## After You Get The Response

Save as: `nx-analysis/monorepo-a/prompt03-output.json`

For Prompt 06 (Sonnet), extract only:
- Items where `splitQuality` is `"poor"`
- Include: `clusterName`, `finding`, `betterSeam`, `cacheImpact`

Leave `"good"` and `"mixed"` splits out of the Sonnet payload.
