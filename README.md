# NX Monorepo Analysis Prompts — v2

> Updated with correct architectural context for this specific monorepo setup.

---

## Architectural Decisions Baked Into These Prompts

These two decisions are treated as **correct and intentional** throughout all prompts.
No prompt will flag either of these as a problem.

**Decision 1: Cross-domain dependencies are intentional**
Libraries are shared across domain scopes deliberately for reuse.
This replaced an overloaded scope:shared pattern. It works.
The analysis looks at STABILITY of cross-domain libs, not their existence.

**Decision 2: Many libs are intentional**
Libs were split from bloated originals to improve maintainability and caching.
The analysis asks whether splits were drawn at the RIGHT seams — not whether to consolidate.

---

## What The Analysis Actually Looks For

```
REAL PROBLEMS (what these prompts find):
  ✦ High-churn libs at the center of cross-domain dependency graphs
  ✦ Split libs that are still tightly coupled (split didn't help caching)
  ✦ Code patterns that defeat NX Cloud cache hits
  ✦ Implicit type coupling with no declared NX dependency
  ✦ Libs with unclear responsibility boundaries post-split

NOT PROBLEMS (these prompts ignore):
  ✗ Cross-domain dependencies (intentional reuse pattern)
  ✗ High lib count (result of deliberate anti-bloat splitting)
  ✗ Consolidation / merge recommendations (against architectural direction)
```

---

## The Core Hypothesis

Both monorepos use the same patterns. One is faster. Why?

```
Fast monorepo:
  Cross-domain shared libs → LOW churn → cache stays valid → fast

Slow monorepo:
  Cross-domain shared libs → HIGH churn → cache invalidates widely → slow
```

The difference is not the pattern. It is the **stability of libs at the center
of the cross-domain dependency graph.**

A lib shared across 5 domains that changes 3x/week invalidates builds in all 5 domains
on every commit. Even perfect NX Cloud configuration cannot save you from this.

---

## Files In This Repo

```
prompts/
  00-haiku-metric-extractor.md        → structural metrics + cross-domain stability map
  01-haiku-crossdomain-stability.md   → is each cross-domain lib stable enough?
  02-haiku-cache-antipattern.md       → code patterns defeating NX cache
  03-haiku-split-quality.md           → were lib splits drawn at the right seams?
  04-haiku-phantom-dependency.md      → implicit coupling with no NX declaration
  06-sonnet-structural-diagnosis.md   → full diagnosis comparing both monorepos
  07-sonnet-migration-sequencer.md    → safe remediation plan

scripts/
  collector.sh                        → run this first on each monorepo
  run-order.md                        → exact step by step run instructions
  token-budget.md                     → cost reference
```

---

## Models

| Prompt | Model | Why |
|--------|-------|-----|
| 00–04 | claude-haiku-4-5 | Fast, cheap, high volume triage |
| 06–07 | claude-sonnet-4-6 | Deep reasoning, once per session |

---

## Quick Start

```
1. Run collector.sh on Repo 1
2. Paste output into Prompt 00 → save metrics JSON
3. Run Prompts 01-04 using metrics JSON as input
4. Repeat steps 1-3 for Repo 2
5. Run Prompt 06 with both repos' findings
```

Full step-by-step in scripts/run-order.md
