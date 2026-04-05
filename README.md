# NX Monorepo Analysis Prompts

> A layered Gen AI strategy for diagnosing build performance issues, structural pathologies, and DDD violations in large NX monorepos (Angular + NestJS).

---

## The Problem This Solves

You have two NX monorepos. Both use NX Cloud caching. Both follow DDD. One has more apps but builds faster. Nobody knows why — because no tool has ever been able to **reason** about the full graph holistically.

This prompt library gives you that reasoning, efficiently.

---

## Core Architecture Principle

```
Layer 1: Collect    → deterministic CLI commands (free, fast, exact)
Layer 2: Compute    → algorithms (free, repeatable, structured)
Layer 3: Reason     → AI (expensive — use sparingly, on filtered signals only)
Layer 4: Act        → deterministic output (reports, migration plans)
```

**AI never sees raw data. It only sees pre-filtered, pre-computed signals.**

This keeps token costs under $0.15 per full analysis session.

---

## Model Strategy

| Model | Use For | Why |
|---|---|---|
| **Haiku** | Classification, scoring, pattern detection | Fast, cheap, high volume |
| **Sonnet 4.6** | Synthesis, architectural reasoning, planning | One call per session |

**Rule: Haiku does the triage. Sonnet does the verdict.**

---

## File Structure

```
prompts/
  01-haiku-domain-classifier.md       → Classify DDD violation per dependency edge
  02-haiku-cache-antipattern.md       → Detect cache-busting patterns per file
  03-haiku-library-boundary.md        → Recommend lib splits/merges
  04-haiku-phantom-dependency.md      → Find implicit coupling between projects
  05-haiku-rfc-detector.md            → Detect if PR needs an ADR
  06-sonnet-structural-diagnosis.md   → Full monorepo diagnosis (one call)
  07-sonnet-migration-sequencer.md    → Safe migration plan generator
  08-sonnet-rfc-drafter.md            → Draft ADR for novel patterns

scripts/
  collector-commands.sh               → All CLI commands to run before AI analysis
  token-budget.md                     → Cost breakdown per use case
```

---

## How To Run End To End

### Step 1: Collect (run on both monorepos)

```bash
bash scripts/collector-commands.sh
```

Outputs: `nx-graph.json`, `file-churn.txt`, `import-frequency.txt`, `all-project-configs.txt`

### Step 2: Compute metrics manually or with a script

From the collected data, compute these values for each monorepo:
- Average dependency depth
- Cross-domain violation count
- Shared lib fan-out
- Cache hit rate per project
- High-churn libs in critical path

### Step 3: Run Haiku prompts (bulk, pre-demo)

For each flagged item (violation, low-cache lib, split candidate):
- Fill in the `{{variables}}` in the relevant Haiku prompt
- Run against `claude-haiku-4-5` 
- Collect all JSON responses into `findings.json`

### Step 4: Run Sonnet once (live during demo)

- Aggregate all Haiku findings into the Sonnet input template
- Run `06-sonnet-structural-diagnosis.md` against `claude-sonnet-4-6`
- This is your live demo moment — stream the response

### Step 5: If migration plan needed

- Feed the `remediationPlan` section of Sonnet output into `07-sonnet-migration-sequencer.md`
- Run once more against `claude-sonnet-4-6`

---

## Token Budget Summary

```
Haiku pre-analysis (all prompts combined):   ~65K tokens   ≈ $0.04
Sonnet structural diagnosis (1 call):        ~4K tokens    ≈ $0.06
Sonnet migration sequencer (1 call):         ~3K tokens    ≈ $0.05

Total per full session:                                    < $0.15
```

---

## Key Insight: Why This Works

Your two monorepos are your biggest asset. You don't need external benchmarks or invented best practices.

The faster monorepo **already contains the answer**. These prompts extract it.

The structural diff between them — dependency depth, cross-domain violations, shared lib fan-out — explains the build time gap. AI's job is to **explain the diff in architectural terms** and produce a sequenced remediation plan.

That's a story no vendor, no blog post, no conference talk can tell. Because it's yours.

---

## DDD Tag Conventions Assumed

These prompts assume your NX projects are tagged following this convention:

```
scope:<domain>   → e.g. scope:retirement, scope:planning, scope:auth, scope:shared
type:<layer>     → e.g. type:feature, type:domain, type:data-access, type:ui, type:util, type:infrastructure
```

If your tags differ, update the `DOMAIN STRUCTURE` section in prompt `01-haiku-domain-classifier.md`.



Good question. Here's the exact order, step by step.

---

## The Complete Run Order

```
REPO 1 (slower one first — that's where the findings are)
│
├── STEP 1: Collect        → run the shell script
├── STEP 2: Compute        → manual metric calculation (no AI)
├── STEP 3: Haiku x4       → classify flagged items
└── STEP 4: Save findings  → aggregate into one JSON

REPO 2 (faster one — just collect + compute, no Haiku needed)
│
├── STEP 1: Collect        → run the shell script
└── STEP 2: Compute        → metric calculation only

FINAL STEP: Sonnet once   → feed both repos' metrics in
```

---

## Repo 1 — Detailed Steps

### Step 1: Run the Collector

```bash
cd /path/to/slow-monorepo
bash scripts/collector-commands.sh monorepo-a @yourscope
```

This produces in `./nx-analysis-output/monorepo-a/`:
- `nx-graph.json`
- `file-churn.txt`
- `import-frequency.txt`
- `all-project-configs.txt`
- `domain-map.txt`

---

### Step 2: Compute Metrics (No AI — just read the files)

Open `nx-graph.json` and `domain-map.txt` and calculate these numbers manually or with a quick script. You need these values to fill the Sonnet prompt later.

```
From nx-graph.json:
  → Count total apps (projects with type: "app")
  → Count total libs (projects with type: "lib")
  → For each lib, count how many projects depend on it (fan-out)
  → Find scope:shared libs specifically — average their fan-out

From file-churn.txt:
  → Identify top 10 most changed files
  → Map each file back to its NX project (use domain-map.txt)
  → Flag any project with >20 commits/90 days that has >10 dependents

From NX Cloud (last 10 builds):
  → Cache hit rate per project
  → Average build time overall

Write down these 8 numbers for Repo 1:
  avg_depth, max_depth, cross_domain_violations,
  shared_lib_fanout, high_churn_in_critical_path,
  leaf_lib_pct, cache_hit_rate, avg_build_time
```

---

### Step 3: Run Haiku Prompts (In This Order)

**Prompt 01 first — domain violations**

From `domain-map.txt`, find every dependency where `scope:X` depends on `scope:Y` and X ≠ Y. For each one, fill the prompt template and run against Haiku.

```
For each cross-domain edge:
  Fill: from_project, from_tags, to_project, to_tags
  Run:  Prompt 01 against claude-haiku-4-5
  Save: response to violations.json
```

Only run on cross-domain edges — not every edge. Your algorithm pre-filters.

---

**Prompt 02 second — cache anti-patterns**

From NX Cloud data, find projects with cache hit rate below 70%. For each one, open its source files and run the prompt.

```
For each low-cache-hit project:
  Prioritize these files: index.ts, *.config.ts, environment*.ts
  Fill: project_name, cache_hit_rate, file_path, file_content
  Run:  Prompt 02 against claude-haiku-4-5
  Save: response to cache-antipatterns.json
```

---

**Prompt 03 third — library boundaries**

From `import-frequency.txt`, find libs where many projects import only a few of their exports. For each candidate, run the prompt.

```
For each lib where >50% consumers use <30% of exports:
  Fill: library_name, tags, loc, total_exports, total_dependents,
        consumer groups, commit velocity, cache hit rate
  Run:  Prompt 03 against claude-haiku-4-5
  Save: response to split-candidates.json
```

---

**Prompt 04 fourth — phantom dependencies**

From `all-project-configs.txt`, find Angular data-access libs and NestJS infrastructure libs in the same domain scope with no declared dependency between them. Compare their exported types.

```
For each suspicious pair (same scope, different layer, no NX link):
  Extract exported interfaces from both projects' index.ts files
  Fill: project_a_name, project_a_tags, project_a_exported_types,
        project_b_name, project_b_tags, project_b_exported_types
  Run:  Prompt 04 against claude-haiku-4-5
  Save: response to phantom-deps.json
```

**Prompt 05 is separate — only run it on PRs, not during this analysis.**

---

### Step 4: Aggregate Repo 1 Findings

Combine everything into one summary object:

```json
{
  "monorepoA": {
    "metrics": { ...your 8 computed numbers... },
    "topOffenders": [ ...top 5 from violations + cache issues... ],
    "criticalViolations": [ ...from violations.json where severity=critical... ],
    "cacheAntipatterns": [ ...from cache-antipatterns.json where impact=high... ],
    "splitCandidates": [ ...from split-candidates.json where recommendation=split... ],
    "phantomDeps": [ ...from phantom-deps.json where severity=critical or major... ]
  }
}
```

Keep only critical and major findings. Leave minor ones out of the Sonnet call.

---

## Repo 2 — Detailed Steps

Much simpler. You only need the metrics for comparison — no Haiku needed.

### Step 1: Run the Collector

```bash
cd /path/to/fast-monorepo
bash scripts/collector-commands.sh monorepo-b @yourscope
```

### Step 2: Compute the Same 8 Metrics

Same calculation as Repo 1. You just need the numbers — no Haiku classification needed for Repo 2 because Sonnet only needs the metric diff, not a full analysis of the fast repo.

```json
{
  "monorepoB": {
    "metrics": { ...your 8 computed numbers... }
  }
}
```

---

## Final Step: Run Sonnet Once

Now combine both:

```json
{
  "monorepoA": { ...full findings from Repo 1... },
  "monorepoB": { ...metrics only from Repo 2... }
}
```

Fill Prompt 06 with this combined payload and run against `claude-sonnet-4-6`. This is your one expensive call and your live demo moment.

If the diagnosis recommends structural changes, then feed the `remediationPlan` section into Prompt 07 for the migration plan.

---

## Summary Timeline

```
Day 1 (prep work, before hackathon)
  90 min  → Run collector on both repos
  60 min  → Compute metrics manually
  60 min  → Run Haiku prompts on Repo 1 findings
  30 min  → Aggregate into final JSON

Hackathon demo
  Live    → Run Prompt 06 (Sonnet) with real data streaming
  Live    → Run Prompt 07 (Sonnet) if judges want the migration plan
```

The Haiku work is all done the night before. The only thing that runs live is Sonnet — which is your wow moment.