# Prompt 07 — Sonnet 4.6: Migration Sequencer

## Purpose
Convert the structural diagnosis from Prompt 06 into an executable, week-by-week migration
plan that engineering teams can actually follow — respecting team boundaries, NX constraints,
Angular/NestJS compatibility, and financial services risk tolerance.

## Model
`claude-sonnet-4-6`

## When To Run
Once, after Prompt 06 completes. Feed it only the `remediationPlan` section of the Sonnet
diagnosis output — not the full response. This keeps token cost minimal.

## Token Target
Input: ~2,000–2,500 tokens. Output: ~2,000 tokens.

---

## The Prompt

```
You are a principal architect producing an executable migration plan for an NX monorepo
restructuring. This plan will be handed directly to engineering teams.

CONSTRAINTS — READ CAREFULLY:
- Financial services organization: risk tolerance is LOW
- Every change must be backwards-compatible or behind a feature flag
- NX Cloud cache configuration must not be disrupted during migration
- Angular libraries cannot change their public API (index.ts exports) without a deprecation cycle
- NestJS services must maintain zero downtime
- Teams own specific NX scopes — cross-team changes require coordination windows

INPUT: Remediation findings from structural diagnosis.
---
DIAGNOSIS SUMMARY:
Primary root cause: {{primary_root_cause}}
Top 3 immediate wins: {{immediate_wins_from_prompt_06}}
Top 3 structural fixes: {{structural_fixes_from_prompt_06}}
DDD corrections needed: {{ddd_corrections_from_prompt_06}}

TEAM TOPOLOGY:
{{#each teams}}
- Team: {{team_name}}
  Owns scopes: {{owned_scopes}}
  Size: {{engineers}} engineers
  Current sprint focus: {{current_focus}}
{{/each}}

TIMELINE CONSTRAINTS:
- Sprint length: {{sprint_length_weeks}} weeks
- Available engineers for migration work: {{available_engineers}}
- Release freeze windows: {{freeze_windows_or_none}}
- Target completion: {{target_weeks}} weeks from now

TECHNICAL ENVIRONMENT:
- NX version: {{nx_version}}
- Angular version: {{angular_version}}
- NestJS version: {{nestjs_version}}
- CI pipeline: {{ci_platform}}
- NX Cloud workspace: {{nx_cloud_workspace_id_or_unknown}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "migrationSummary": {
    "totalPhases": <number>,
    "estimatedDuration": "<e.g. 6 weeks>",
    "engineeringDaysRequired": <number>,
    "expectedBuildTimeReduction": "<percentage>",
    "highestRiskItem": "<the one thing most likely to cause problems>"
  },

  "phases": [
    {
      "phase": 1,
      "name": "<short descriptive name>",
      "goal": "<one sentence: what this phase achieves>",
      "duration": "<e.g. 3 days>",
      "owner": "<team name>",
      "dependsOnPhase": <phase number or null>,
      "steps": [
        {
          "stepNumber": 1,
          "action": "<exactly what to do>",
          "nxCommand": "<nx generate or nx move command if applicable, or null>",
          "filesAffected": ["<file or pattern>"],
          "safetyGate": "<how to verify this step succeeded>",
          "rollback": "<exact steps to undo if something breaks>",
          "estimatedTime": "<e.g. 2 hours>"
        }
      ],
      "successMetric": "<measurable definition of done for this phase>",
      "cacheImpactDuringMigration": "<will cache hit rate temporarily drop? by how much? for how long?>"
    }
  ],

  "parallelization": [
    {
      "phases": [<phase numbers>],
      "canRunInParallel": true | false,
      "condition": "<what must be true for parallel execution to be safe>",
      "riskIfParallel": "<what could go wrong>"
    }
  ],

  "weekByWeek": [
    {
      "week": 1,
      "phases": [<phase numbers active this week>],
      "focus": "<what engineering is doing this week>",
      "deliverable": "<what is merged/deployed by end of week>",
      "metric": "<what number should improve by end of week>"
    }
  ],

  "riskRegister": [
    {
      "risk": "<specific risk>",
      "probability": "low" | "medium" | "high",
      "impact": "low" | "medium" | "high",
      "mitigation": "<specific mitigation action>",
      "owner": "<team or role responsible>"
    }
  ],

  "nxSpecificGuidance": {
    "cachePreservation": "<how to keep NX Cloud cache valid during restructuring>",
    "moveLibraryApproach": "<nx move vs manual, and why>",
    "tagsToAdd": ["<new NX tags to add for better graph enforcement>"],
    "moduleBoundaryRules": "<what to add to .eslintrc for nx/enforce-module-boundaries>"
  },

  "successDefinition": {
    "cacheHitRateTarget": "<target %>",
    "buildTimeTarget": "<target minutes>",
    "violationCountTarget": 0,
    "measureAfterWeeks": <number>
  }
}
```

---

## NX-Specific Migration Patterns

Include these in your context when filling the template.

### Moving a library safely

```bash
# NEVER manually move files — always use nx move
# This updates all imports, project.json, tsconfig paths automatically
npx nx generate @nx/workspace:move \
  --project=old-lib-name \
  --destination=new/path/new-lib-name

# After move: verify
npx nx graph  # Check graph is intact
npx nx affected --base=main --dry-run  # Verify affect calculation
```

### Splitting a library safely (fission)

```bash
# Step 1: Create new lib
npx nx generate @nx/angular:library new-lib-name \
  --directory=libs/scope/new-lib-name \
  --tags="scope:x,type:y"

# Step 2: Move selected files (manually or with generate)
# Step 3: Update original lib's index.ts to re-export from new lib (temporary)
export { ThingFromNewLib } from '@scope/new-lib-name';

# Step 4: Update consumers over next sprint
# Step 5: Remove re-export from original lib
# Step 6: Verify graph and cache metrics
```

### Enforcing boundaries with ESLint

```json
// .eslintrc.json — nx/enforce-module-boundaries
{
  "rules": {
    "@nx/enforce-module-boundaries": [
      "error",
      {
        "depConstraints": [
          {
            "sourceTag": "type:feature",
            "onlyDependOnLibsWithTags": ["type:domain", "type:data-access", "type:util"]
          },
          {
            "sourceTag": "type:domain",
            "onlyDependOnLibsWithTags": ["type:util"]
          },
          {
            "sourceTag": "type:util",
            "onlyDependOnLibsWithTags": []
          }
        ]
      }
    ]
  }
}
```

Add missing constraints as part of the migration plan.
They make violations compile-time errors — future violations can't be accidentally introduced.

---

## Output Usage

Share the `weekByWeek` section with team leads.
Share the `phases` section with engineers doing the work.
Share the `riskRegister` with your architecture board.
Feed `successDefinition` into your monitoring dashboard.