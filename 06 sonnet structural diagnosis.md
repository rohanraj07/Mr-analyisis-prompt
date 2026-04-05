# Prompt 06 — Sonnet 4.6: Monorepo Structural Diagnosis

## Purpose
The one expensive AI call per session. Receives pre-filtered, pre-computed signals
from all Haiku prompts and produces a ranked architectural diagnosis explaining
why one monorepo is faster than the other — with a concrete remediation plan.

## Model
`claude-sonnet-4-6`

## When To Run
ONCE per analysis session. Only after:
- All collector scripts have run on both monorepos
- Structural metrics have been computed (algorithm layer)
- Haiku prompts 01–04 have classified all flagged items
- All findings aggregated into the input template below

## Token Target
Keep total input under 4,000 tokens. The template below is designed for ~2,500–3,500 tokens.
If you have more than 10 violations in any category, include only the top 5 by severity/impact.

---

## The Prompt

```
You are a principal architect specializing in NX monorepo performance and Domain-Driven Design
with expertise in Angular and NestJS at enterprise scale.

You have been given pre-analyzed structural data from TWO monorepos at the same organization.
Both use:
- Angular (frontend) + NestJS (backend)
- NX 20 with NX Cloud distributed caching
- Domain-Driven Design with NX tags (scope:x, type:y)
- Same CI/CD pipeline

CRITICAL CONTEXT: Monorepo B has more applications than Monorepo A but builds significantly
faster. All metrics below are pre-computed by deterministic analysis — you are not being asked
to process raw data. You are being asked to REASON about the pre-computed signals and produce
an actionable diagnosis.

Be direct. Be specific. Prioritize ruthlessly.
The output of this analysis will be presented to engineering leadership.

===================================================
MONOREPO A — SLOWER ({{app_count_a}} apps, {{lib_count_a}} libs)
===================================================

STRUCTURAL METRICS:
- Average dependency depth:              {{avg_depth_a}}
- Maximum dependency depth:              {{max_depth_a}}
- Cross-domain DDD violations:           {{violations_a}} ({{critical_a}} critical, {{major_a}} major)
- Shared lib average fan-out:            {{fanout_a}} dependents per scope:shared lib
- High-churn libs in critical path:      {{churn_critical_a}}
- Leaf lib percentage:                   {{leaf_pct_a}}%
- NX Cloud overall cache hit rate:       {{cache_hit_rate_a}}%
- Average build time (last 10 runs):     {{avg_build_time_a}} minutes

TOP OFFENDING LIBRARIES (pre-ranked by impact score):
{{#each top_offenders_a}}
{{index}}. {{name}}
   Tags: {{tags}}
   Dependents: {{dependents}} | Commits/90d: {{commits}} | Cache hit rate: {{cache_hit_rate}}%
   Classification: {{haiku_classification}}
{{/each}}

CRITICAL DDD VIOLATIONS:
{{#each critical_violations}}
- {{from}} → {{to}}
  Rule broken: {{rule_broken}}
  Fix: {{fix}}
{{/each}}

CACHE ANTI-PATTERNS FOUND:
{{#each cache_antipatterns}}
- {{project}}: {{pattern_type}} in {{file}} (impact: {{impact}})
{{/each}}

LIBRARY SPLIT CANDIDATES:
{{#each split_candidates}}
- {{name}}: {{primary_reason}} | Estimated improvement: {{estimated_improvement}}
{{/each}}

PHANTOM DEPENDENCIES DETECTED:
{{#each phantom_deps}}
- {{project_a}} ↔ {{project_b}}: {{coupling_type}} ({{severity}})
{{/each}}

===================================================
MONOREPO B — FASTER ({{app_count_b}} apps, {{lib_count_b}} libs)
===================================================

STRUCTURAL METRICS:
- Average dependency depth:              {{avg_depth_b}}
- Maximum dependency depth:              {{max_depth_b}}
- Cross-domain DDD violations:           {{violations_b}}
- Shared lib average fan-out:            {{fanout_b}}
- High-churn libs in critical path:      {{churn_critical_b}}
- Leaf lib percentage:                   {{leaf_pct_b}}%
- NX Cloud overall cache hit rate:       {{cache_hit_rate_b}}%
- Average build time (last 10 runs):     {{avg_build_time_b}} minutes

===================================================
TASK
===================================================

1. Explain WHY Monorepo B is faster despite having more apps.
2. Identify the ROOT CAUSE of Monorepo A's build performance issues.
3. Produce a remediation plan — 3 immediate wins and 3 structural fixes.
   Prioritize by: (impact × feasibility) / risk. Not just impact alone.
4. Give me one number: if we implement the top 3 recommendations, what % build
   time reduction should we expect in Monorepo A?

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "executiveSummary": "<3 sentences maximum: what's wrong, why B is faster, what to do>",

  "rootCause": {
    "primaryFactor": "<the single biggest structural reason monorepo A is slower>",
    "secondaryFactors": [
      "<factor 2>",
      "<factor 3>"
    ],
    "dddMisuse": "<how DDD structure is being misused in monorepo A specifically>",
    "cacheDefeater": "<the specific pattern or library defeating NX Cloud caching>"
  },

  "whyBIsFaster": {
    "keyDifferences": [
      {
        "metric": "<metric name>",
        "monorepoA": "<value>",
        "monorepoB": "<value>",
        "buildImpact": "<why this difference matters for build time>"
      }
    ],
    "architecturalPrinciple": "<one principle monorepo B gets right that A violates>"
  },

  "remediationPlan": {
    "immediateWins": [
      {
        "rank": 1,
        "action": "<specific action — name the library or file>",
        "target": "<specific library, file, or pattern>",
        "estimatedImpact": "<build time or cache hit % improvement>",
        "effort": "hours" | "days",
        "risk": "low" | "medium",
        "howToVerify": "<how you know this worked after implementing>"
      }
    ],
    "structuralFixes": [
      {
        "rank": 1,
        "action": "<specific refactor>",
        "affectedProjects": ["<project names>"],
        "migrationSequence": ["<step 1>", "<step 2>", "<step 3>"],
        "effort": "days" | "weeks",
        "risk": "low" | "medium" | "high",
        "prerequisite": "<what must be done before this>"
      }
    ],
    "dddCorrections": [
      {
        "violation": "<specific violation from input>",
        "currentPattern": "<what exists now>",
        "correctPattern": "<what it should be>",
        "downstreamImpact": "<what else changes when you fix this>"
      }
    ]
  },

  "projectedOutcome": {
    "cacheHitRateImprovement": "<estimated % improvement>",
    "buildTimeReduction": "<estimated % reduction>",
    "confidenceLevel": <0-100>,
    "keyAssumption": "<the one assumption this projection depends on most>",
    "timeToSeeImpact": "<how long after implementation before metrics improve>"
  },

  "warningFlags": [
    "<anything that looks like it will get worse before it gets better>",
    "<any risk not obvious from the metrics>"
  ]
}
```

---

## How To Fill The Template Efficiently

### Metric computation cheat sheet

```
avg_dependency_depth:
  For each node in nx-graph.json, BFS to find longest path to a leaf.
  Average across all non-app nodes.

fanout:
  For scope:shared libs only.
  Count how many projects list them as a dependency.
  Average across all scope:shared libs.

high_churn_in_critical_path:
  Critical path = libs that appear as transitive dependencies of >40% of apps.
  High churn = >20 commits in 90 days.
  Count of libs meeting both criteria.

leaf_pct:
  Leaf lib = lib with 0 dependents (nothing imports it) or imports only externals.
  leaf_pct = (leaf libs / total libs) × 100

cache_hit_rate:
  From NX Cloud API. Average across all projects. Last 10 runs.
```

### Top offenders ranking formula

```
impact_score = dependents × (1 - cache_hit_rate) × log(commits_90d + 1)

Sort descending. Take top 5.
```

---

## Example Minimal Input (What Good Input Looks Like)

```json
{
  "monorepoA": {
    "apps": 12, "libs": 89,
    "avgDepth": 5.8, "maxDepth": 9,
    "violations": 23, "criticalViolations": 4,
    "sharedFanOut": 31, "churnInCriticalPath": 7,
    "leafPct": 18, "cacheHitRate": 41,
    "avgBuildTime": 14.2
  },
  "monorepoB": {
    "apps": 17, "libs": 124,
    "avgDepth": 3.1, "maxDepth": 5,
    "violations": 3, "criticalViolations": 0,
    "sharedFanOut": 9, "churnInCriticalPath": 1,
    "leafPct": 47, "cacheHitRate": 83,
    "avgBuildTime": 5.8
  }
}
```

Notice: feeding two objects with 10 fields each instead of two full graph JSONs.
That's the point of the layered architecture.