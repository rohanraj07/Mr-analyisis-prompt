# Prompt 07 — Sonnet: Migration Sequencer

## Model: claude-sonnet-4-6
## Input: top3Actions section from Prompt 06 output
## Runs: After Prompt 06. Optional — run if judges ask "how would you fix this?"

---

## What This Produces

A week-by-week execution plan for the top 3 actions from Prompt 06.
Safe. Sequenced. Respects your team structure and financial services risk tolerance.

---

## The Prompt

Copy everything below. Fill in the {{variables}}. Paste into gateway.

---

```
You are a principal architect producing an executable migration plan for
an NX monorepo in a financial services organization (Angular + NestJS, DDD).

LOCKED ARCHITECTURAL DECISIONS — do not contradict these:
1. Cross-domain dependencies are intentional — do not remove them
2. High lib count from splitting is intentional — do not consolidate
3. All changes must be backwards-compatible or behind feature flags
4. NX Cloud cache configuration must not break during migration
5. Angular lib public APIs (index.ts exports) need deprecation period before removal
6. NestJS services cannot have downtime

INPUT: Top 3 actions from Prompt 06 diagnosis.
---
TOP 3 ACTIONS:
{{paste top3Actions array from final-diagnosis.json}}

TEAM CONTEXT:
Teams and their NX scope ownership:
{{list your teams and which scope:x tags they own}}

Sprint length: {{your sprint length}}
Engineers available for this work: {{number}}
Release freeze windows: {{any freeze dates or "none"}}

TECHNICAL CONTEXT:
NX version: {{run: npx nx --version}}
Angular version: {{check package.json}}
NestJS version: {{check package.json}}
---

For each action, produce a safe execution plan.

SEQUENCING RULES:
- Order steps so no step requires a broken intermediate state
- Identify which actions can run in parallel safely
- Flag when cross-team coordination is required
- Add a safety gate after each step before proceeding

NX-SPECIFIC GUIDANCE TO APPLY:
- Always use `nx generate @nx/workspace:move` to move libs (never manual file moves)
- After any lib move: run `nx graph` to verify graph integrity before merging
- Use `nx affected --dry-run` to validate blast radius before and after each change
- Add missing nx/enforce-module-boundaries eslint rules as part of each action
  (prevents the same issue from creeping back)

Respond ONLY in this exact JSON. No markdown outside JSON.

{
  "migrationSummary": {
    "totalWeeks": <number>,
    "totalEngineeringDays": <number>,
    "expectedBuildTimeReduction": "<from Prompt 06 projectedOutcome>",
    "biggestRisk": "<the one thing most likely to cause problems>"
  },

  "phases": [
    {
      "phase": 1,
      "action": "<which of the top 3 actions this phase addresses>",
      "name": "<short name>",
      "owner": "<team name>",
      "duration": "<e.g. 3 days>",
      "canParallelizeWith": <phase number or null>,
      "steps": [
        {
          "step": 1,
          "what": "<exactly what to do>",
          "command": "<nx command if applicable, or null>",
          "safetyGate": "<run this to verify step succeeded before proceeding>",
          "rollback": "<how to undo if something breaks>"
        }
      ],
      "doneWhen": "<measurable definition of done>",
      "cacheImpactDuringMigration": "<will hit rate temporarily drop? how much? how long?>"
    }
  ],

  "weekByWeek": [
    {
      "week": 1,
      "phases": [<phase numbers>],
      "engineeringFocus": "<what the team is doing>",
      "mergedBy": "<what is in main branch by end of week>",
      "metricToWatch": "<what number should improve>"
    }
  ],

  "eslintRulesToAdd": [
    {
      "rule": "<rule configuration>",
      "prevents": "<what architectural mistake this prevents from recurring>"
    }
  ],

  "riskRegister": [
    {
      "risk": "<specific risk>",
      "probability": "low|medium|high",
      "mitigation": "<specific mitigation step>"
    }
  ]
}
```

---

## After You Get The Response

Save as: `nx-analysis/migration-plan.json`

Share `weekByWeek` with team leads.
Share `phases[n].steps` with engineers doing the work.
Share `eslintRulesToAdd` with your platform team — these prevent recurrence.
