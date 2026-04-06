# Prompt 00 — Haiku: Metric Extractor & Cross-Domain Stability Mapper

## Model: claude-haiku-4-5
## Runs: Once per monorepo, right after collector.sh
## Output: Feeds all subsequent prompts — save it carefully

---

## Architectural Context (read before sending)

This monorepo uses cross-domain dependencies **intentionally**.
Libs are shared across domain scopes for reuse — this replaced an
overloaded scope:shared pattern. Do NOT flag cross-domain dependencies
as violations. Treat them as designed behavior.

This monorepo also has many libs **intentionally**.
Libs were split from bloated originals to improve caching and maintainability.
Do NOT recommend consolidation. Analyze split quality instead.

---

## The Prompt

Copy everything below this line. Fill in the {{variables}}. Paste into gateway.

---

```
You are an NX monorepo structural analyst. Extract and compute metrics from the
raw data below. Output structured JSON only. No markdown. No preamble.

IMPORTANT ARCHITECTURAL CONTEXT:
- Cross-domain dependencies are INTENTIONAL in this monorepo (deliberate reuse pattern)
- High lib count is INTENTIONAL (libs were split to prevent bloat)
- Do NOT flag either of the above as problems
- Focus on: stability of shared libs, split quality, cache patterns

MONOREPO ID: {{monorepo-a or monorepo-b}}
NX SCOPE: {{@yourscope}}
DATE: {{today}}

---NX GRAPH (nodes + dependencies):
{{paste full nx-graph.json content here}}

---DOMAIN MAP (name|tags|path):
{{paste full domain-map.txt content here}}

---FILE CHURN (commit count | file path, last 90 days):
{{paste full file-churn.txt content here}}

---IMPORT FREQUENCY (import count | lib path):
{{paste full import-frequency.txt content here}}

---TAG SUMMARY (count | tag):
{{paste full tag-summary.txt content here}}

---

COMPUTE ALL OF THE FOLLOWING:

1. BASIC COUNTS
   Count apps and libs separately from graph nodes.
   List all unique scope: tags and type: tags found.

2. DEPENDENCY DEPTH
   For each lib: find its longest transitive dependency path (depth).
   Compute average depth and max depth across all libs.
   List the 5 deepest libs with their depth number.

3. CROSS-DOMAIN DEPENDENCY MAP
   For every dependency edge where source scope != target scope:
   - Record: from_project, from_tags, to_project, to_tags
   - This is intentional reuse — do not judge it
   - For each cross-domain lib (the TARGET being depended on):
     * Count how many different domain scopes depend on it
     * Map its commit velocity from file-churn data
     * Compute: blast_radius_score = domain_count × commit_velocity
   - Sort by blast_radius_score descending
   These are your highest-risk shared libs — not because sharing is wrong
   but because high-churn shared libs cause wide cache invalidation.

4. TOP OFFENDERS
   Rank all libs by this formula:
   impact_score = dependents × churn_commits_90d
   (higher = more build pressure this lib creates)
   Return top 7 with: project name, tags, dependents count,
   commits in 90 days, impact score, and one sentence on why it matters.

5. LIB CLUSTERS (split quality candidates)
   Find groups of libs that:
   a) Share the same scope AND similar type tags
   b) Heavily import from each other (tight post-split coupling)
   These may be splits that didn't achieve cache isolation.
   Return clusters of 2+ libs that are tightly interconnected post-split.

6. SUSPECT PAIRS (for phantom dependency detection)
   Find pairs of projects where:
   - One is type:data-access (Angular) and one is type:domain or type:infrastructure (NestJS)
   - They are in the same scope
   - They have NO declared NX dependency between them
   These need phantom dependency analysis in Prompt 04.

7. LEAF LIB PERCENTAGE
   Libs with zero dependents / total libs × 100.
   A very low leaf percentage means most libs are interconnected.

8. CACHE HIT RATE
   From NX Cloud data if available. Otherwise: "unavailable".

Respond ONLY in this exact JSON. No markdown. No preamble.

{
  "monorepoId": "{{monorepo-a or monorepo-b}}",
  "analyzedAt": "{{today}}",

  "basicCounts": {
    "appCount": <number>,
    "libCount": <number>,
    "scopeTags": ["<scope:x>", "<scope:y>"],
    "typeTags": ["<type:x>", "<type:y>"]
  },

  "depthMetrics": {
    "avgDependencyDepth": <number to 1 decimal>,
    "maxDependencyDepth": <number>,
    "deepestLibs": [
      { "project": "<n>", "depth": <number>, "tags": "<tags>" }
    ],
    "leafLibPercentage": <number to 1 decimal>
  },

  "crossDomainLibs": [
    {
      "project": "<lib being shared across domains>",
      "tags": "<its tags>",
      "dependentDomains": ["<scope:x>", "<scope:y>"],
      "domainCount": <number>,
      "commits90d": <number>,
      "blastRadiusScore": <number>,
      "interpretation": "<one sentence: stable and safe OR churning and risky>"
    }
  ],

  "topOffenders": [
    {
      "project": "<n>",
      "tags": "<tags>",
      "dependents": <number>,
      "commits90d": <number>,
      "impactScore": <number>,
      "whyItMatters": "<one sentence>"
    }
  ],

  "libClusters": [
    {
      "clusterName": "<descriptive name for this group>",
      "libs": ["<lib1>", "<lib2>", "<lib3>"],
      "sharedScope": "<scope:x>",
      "internalDependencies": <number of deps between them>,
      "concern": "<one sentence: are they still tightly coupled post-split?>"
    }
  ],

  "suspectPairs": [
    {
      "angularLib": "<data-access lib name>",
      "angularTags": "<tags>",
      "nestjsLib": "<domain or infrastructure lib name>",
      "nestjsTags": "<tags>",
      "sharedScope": "<scope:x>",
      "hasDeclaredDep": false
    }
  ],

  "cacheHitRate": <number or "unavailable">,
  "avgBuildTime": <number in minutes or "unavailable">,

  "dataQualityFlags": [
    "<note any gaps: e.g. NX Cloud unavailable, git log incomplete>"
  ],

  "readyForNextPrompts": true
}
```

---

## After You Get The Response

Save the full JSON response as:
`nx-analysis/monorepo-a/prompt00-output.json`

Then extract these sections to feed into subsequent prompts:
- `crossDomainLibs` → feed into Prompt 01
- `topOffenders` → feed into Prompt 02
- `libClusters` → feed into Prompt 03
- `suspectPairs` → feed into Prompt 04
- `basicCounts` + `depthMetrics` → feed into Prompt 06
