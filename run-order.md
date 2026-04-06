# Exact Run Order — Step By Step

No automation. No SDK. No pasting code.
You run shell commands. You paste file contents into your gen gateway chat.
One repo at a time.

---

## Before You Start

You need:
- Access to your gen gateway (internal AI chat)
- Haiku model available in your gateway (for Prompts 00-04)
- Sonnet model available in your gateway (for Prompt 06)
- Terminal access to each monorepo

You do NOT need:
- Anthropic API key
- Any npm packages
- Any new tooling

---

## REPO 1 — Full Run (do this first, fully complete before touching Repo 2)

---

### STEP 1 — Run collector (terminal, ~3 min)

```bash
# cd into your slow monorepo root first
cd /path/to/slow-monorepo

# Run the collector
# Replace @yourscope with your actual NX scope prefix
bash /path/to/nx-prompts-v2/scripts/collector.sh monorepo-a @yourscope
```

This creates `./nx-analysis/monorepo-a/` with 5 files:
- `nx-graph.json`
- `domain-map.txt`
- `file-churn.txt`
- `import-frequency.txt`
- `tag-summary.txt`

---

### STEP 2 — Run Prompt 00 (gen gateway, Haiku)

Open your gen gateway. Select Haiku model.

Open Prompt 00 from: `prompts/00-haiku-metric-extractor.md`

Fill in the variables at the top:
```
MONOREPO_ID   → monorepo-a
NX_SCOPE      → @yourscope
TODAY'S DATE  → today
```

Then paste the contents of these files into the marked sections:
```
nx-graph.json          → paste under "NX GRAPH JSON" section
domain-map.txt         → paste under "DOMAIN MAP" section
file-churn.txt         → paste under "FILE CHURN" section
import-frequency.txt   → paste under "IMPORT FREQUENCY" section
tag-summary.txt        → paste under "TAG SUMMARY" section
```

Send to Haiku.

**Save the JSON response** to a file called:
`nx-analysis/monorepo-a/prompt00-output.json`

---

### STEP 3 — Run Prompt 01 (gen gateway, Haiku)

Open Prompt 01 from: `prompts/01-haiku-crossdomain-stability.md`

From your `prompt00-output.json`, copy the `crossDomainLibs` array.
Paste it into the marked section in Prompt 01.

Send to Haiku.

**Save the JSON response** to:
`nx-analysis/monorepo-a/prompt01-output.json`

---

### STEP 4 — Run Prompt 02 (gen gateway, Haiku)

Open Prompt 02 from: `prompts/02-haiku-cache-antipattern.md`

From your `prompt00-output.json`, copy the `topOffenders` array
(these are the libs with highest churn × dependents).

For each lib in topOffenders:
- Find its source files in your codebase
- Paste the content of its `index.ts` and key service files
  into the prompt template

Send to Haiku. One call per lib, or batch up to 3 libs per call.

**Save responses** to:
`nx-analysis/monorepo-a/prompt02-output.json`

---

### STEP 5 — Run Prompt 03 (gen gateway, Haiku)

Open Prompt 03 from: `prompts/03-haiku-split-quality.md`

From your `prompt00-output.json`, copy the `libClusters` array
(these are groups of libs that were split from a common origin
and are still heavily interconnected).

Paste into the marked section in Prompt 03.

Send to Haiku.

**Save the JSON response** to:
`nx-analysis/monorepo-a/prompt03-output.json`

---

### STEP 6 — Run Prompt 04 (gen gateway, Haiku)

Open Prompt 04 from: `prompts/04-haiku-phantom-dependency.md`

From your `prompt00-output.json`, copy the `suspectPairs` array
(Angular data-access libs paired with NestJS domain libs
in the same scope with no declared NX dependency).

Paste into the marked section in Prompt 04.

Send to Haiku.

**Save the JSON response** to:
`nx-analysis/monorepo-a/prompt04-output.json`

---

### STEP 7 — Save Repo 1 Complete

You now have for Repo 1:
```
nx-analysis/monorepo-a/
  prompt00-output.json   ← structural metrics + cross-domain map
  prompt01-output.json   ← cross-domain stability findings
  prompt02-output.json   ← cache anti-pattern findings
  prompt03-output.json   ← split quality findings
  prompt04-output.json   ← phantom dependency findings
```

---

## REPO 2 — Run (after Repo 1 is fully complete)

Repeat STEPS 1-6 exactly, but:
- Use `monorepo-b` everywhere instead of `monorepo-a`
- Use your fast monorepo path
- Save everything under `nx-analysis/monorepo-b/`

For Repo 2, Prompts 01-04 will likely find fewer issues.
That contrast is the story.

---

## FINAL STEP — Sonnet Diagnosis

Only run this after BOTH repos have all 5 output files.

Open Prompt 06 from: `prompts/06-sonnet-structural-diagnosis.md`

Open your gen gateway. Select Sonnet model.

Build the input by pulling from both repos' findings:

```
From monorepo-a/prompt00-output.json  → structuralMetrics section
From monorepo-b/prompt00-output.json  → structuralMetrics section
From monorepo-a/prompt01-output.json  → top 5 stability findings
From monorepo-a/prompt02-output.json  → high impact cache issues only
From monorepo-a/prompt03-output.json  → split quality issues only
From monorepo-a/prompt04-output.json  → critical phantom deps only
```

Paste all of the above into Prompt 06's template sections.

Send to Sonnet. This is your live demo moment — let it stream.

**Save the response** to:
`nx-analysis/final-diagnosis.json`

---

## File You Share With Judges

`final-diagnosis.json` contains:
- Why Repo 1 is slower (specific, named root cause)
- Why Repo 2 is faster (structural principles)
- Top 3 actions to fix Repo 1
- Projected build time improvement

---

## Time Estimate

```
Repo 1 collector:    5 min  (terminal)
Repo 1 Prompt 00:    3 min  (gateway)
Repo 1 Prompts 01-04: 10 min (gateway, 4 calls)
Repo 2 collector:    5 min  (terminal)
Repo 2 Prompt 00:    3 min  (gateway)
Repo 2 Prompts 01-04: 10 min (gateway, but fewer findings)
Final Sonnet call:   2 min  (gateway, streams live)
─────────────────────────────
Total:               ~40 min
```

Do the first 30 minutes the night before the hackathon.
Run only the final Sonnet call live during the demo.
