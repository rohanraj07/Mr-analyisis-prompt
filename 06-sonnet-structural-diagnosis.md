# Prompt 06 — Sonnet: Structural Diagnosis

## Model: claude-sonnet-4-6
## Runs: ONCE. After both repos have completed Prompts 00-04.
## This is your live demo moment — let it stream in front of judges.

---

## Architectural Context For This Prompt

Two decisions are locked in as correct. Sonnet must not question them:

1. Cross-domain dependencies — intentional reuse pattern, not violations
2. High lib count — result of deliberate anti-bloat splitting, not sprawl

The analysis question is:
**Why does Monorepo B (more apps) build faster than Monorepo A (fewer apps)?**

Given the architectural decisions above, the answer will be found in:
- Stability of cross-domain shared libs (churn × blast radius)
- Quality of lib splits (did splits achieve cache isolation?)
- Cache anti-patterns in high-impact libs
- Implicit contracts breaking NX's dependency awareness

---

## How To Build The Input

Pull ONLY these fields from each repo's output files.
Do not paste full JSON files — keep Sonnet's input under 4,000 tokens.

**From monorepo-a/prompt00-output.json:**
- `basicCounts`
- `depthMetrics`
- `cacheHitRate`
- `avgBuildTime`
- Top 5 from `crossDomainLibs` (sorted by blastRadiusScore)

**From monorepo-b/prompt00-output.json:**
- Same fields as above (for comparison)

**From monorepo-a/prompt01-output.json:**
- Only items where `stabilityRating` = `"red"`

**From monorepo-a/prompt02-output.json:**
- Only items where `overallCacheImpact` = `"high"`
- Only the `quickestWin` field per item

**From monorepo-a/prompt03-output.json:**
- Only items where `splitQuality` = `"poor"`
- Fields: `clusterName`, `finding`, `betterSeam`, `cacheImpact`

**From monorepo-a/prompt04-output.json:**
- Only items where `phantomCouplingDetected` = `true` AND severity = `critical` or `major`
- Fields: `angularLib`, `nestjsLib`, `couplingType`, `divergenceRisk`

---

## The Prompt

Copy everything below. Fill in from your collected outputs. Paste into gateway.

---

```
You are a principal architect specializing in NX monorepo performance,
Angular + NestJS at enterprise scale, and Domain-Driven Design.

LOCKED ARCHITECTURAL DECISIONS — DO NOT QUESTION THESE:
1. Cross-domain dependencies are intentional reuse patterns in both monorepos.
   They replaced an overloaded scope:shared pattern. They are correct.
2. High lib count is the result of deliberate anti-bloat splitting.
   Consolidation is not on the table. Splitting was the right direction.

YOUR TASK:
Both monorepos use Angular + NestJS, NX 20 with NX Cloud, DDD structure.
Monorepo B has MORE apps than Monorepo A but builds FASTER.
Explain why. Give the top 3 actions to fix Monorepo A.

All data below is pre-computed. You are reasoning over signals, not raw data.
Be specific. Name actual libraries where possible. Prioritize ruthlessly.

===================================================
MONOREPO A — SLOWER
===================================================

BASIC METRICS:
Apps: {{appCount_a}} | Libs: {{libCount_a}}
Avg dependency depth: {{avgDepth_a}} | Max: {{maxDepth_a}}
Leaf lib percentage: {{leafPct_a}}%
Cache hit rate: {{cacheHitRate_a}}
Avg build time: {{avgBuildTime_a}} min

TOP CROSS-DOMAIN LIBS BY BLAST RADIUS:
{{paste top 5 crossDomainLibs from prompt00 here — just the key fields}}

UNSTABLE CROSS-DOMAIN LIBS (red rating from Prompt 01):
{{paste red-rated items from prompt01-output.json}}

HIGH-IMPACT CACHE ANTI-PATTERNS (from Prompt 02):
{{paste high-impact items — quickestWin field only}}

POOR SPLIT QUALITY (from Prompt 03):
{{paste poor-quality clusters — finding + betterSeam fields}}

PHANTOM DEPENDENCIES (from Prompt 04):
{{paste critical/major phantom deps — couplingType + divergenceRisk}}

===================================================
MONOREPO B — FASTER
===================================================

BASIC METRICS:
Apps: {{appCount_b}} | Libs: {{libCount_b}}
Avg dependency depth: {{avgDepth_b}} | Max: {{maxDepth_b}}
Leaf lib percentage: {{leafPct_b}}%
Cache hit rate: {{cacheHitRate_b}}
Avg build time: {{avgBuildTime_b}} min

TOP CROSS-DOMAIN LIBS BY BLAST RADIUS:
{{paste top 5 crossDomainLibs from monorepo-b prompt00}}

UNSTABLE CROSS-DOMAIN LIBS:
{{paste red-rated from monorepo-b prompt01 — likely fewer}}

===================================================
TASK
===================================================

1. Explain WHY Monorepo B builds faster despite having more apps.
   Anchor your explanation in the specific metric differences above.

2. Identify the ROOT CAUSE of Monorepo A's build performance issues.
   Given that cross-domain sharing and high lib count are both intentional,
   what specifically is going wrong?

3. Give me the TOP 3 ACTIONS for Monorepo A.
   Ranked by: (estimated impact × feasibility) ÷ risk.
   Not ranked by impact alone — risk matters in financial services.
   Name specific libraries in each recommendation.

4. ONE NUMBER: if we implement all 3 top actions, what % build time
   reduction should we expect in Monorepo A?

Respond ONLY in this exact JSON. No markdown outside JSON.

{
  "executiveSummary": "<3 sentences: what is wrong, why B is faster, what to do first>",

  "rootCause": {
    "primaryFactor": "<the single biggest reason A is slower — name the specific pattern or lib>",
    "secondaryFactors": ["<factor 2>", "<factor 3>"],
    "whyCrossdomainIsNotTheVillain": "<one sentence confirming cross-domain sharing is working as intended>",
    "actualCacheDefeater": "<the specific thing — lib name, pattern, or structural issue — defeating NX Cloud>"
  },

  "whyBIsFaster": {
    "keyMetricDifferences": [
      {
        "metric": "<metric name>",
        "monorepoA": "<value>",
        "monorepoB": "<value>",
        "buildImpact": "<one sentence: why this difference explains the speed gap>"
      }
    ],
    "structuralPrincipleBreaking": "<one principle Monorepo A violates that Monorepo B gets right>"
  },

  "top3Actions": [
    {
      "rank": 1,
      "action": "<specific action — what exactly to do>",
      "targetLib": "<specific library name>",
      "whyThisFirst": "<one sentence: why this has highest impact/feasibility ratio>",
      "estimatedImpact": "<cache hit rate or build time improvement>",
      "effort": "hours|days|weeks",
      "risk": "low|medium|high",
      "howToVerify": "<how you know it worked after implementing>",
      "nxCommand": "<nx generate or nx move command if applicable, or null>"
    }
  ],

  "projectedOutcome": {
    "buildTimeReduction": "<estimated % if all 3 actions implemented>",
    "cacheHitRateImprovement": "<estimated %>",
    "confidenceLevel": <0-100>,
    "biggestAssumption": "<the one assumption this projection depends on most>",
    "timeToSeeResults": "<e.g. visible after week 1, full benefit after week 3>"
  },

  "quickWins": [
    "<something that can be fixed in under a day with immediate cache benefit>"
  ],

  "warningFlags": [
    "<anything that will get worse before it gets better during remediation>"
  ]
}
```

---

## After You Get The Response

Save as: `nx-analysis/final-diagnosis.json`

Share `executiveSummary` + `top3Actions` + `projectedOutcome` with judges.
Share `top3Actions` with your engineering team immediately after the hackathon.
