# Token Budget — v2

Updated to reflect corrected architectural framing.
Prompt 01 is now cross-domain stability analyzer (not violation classifier).
Prompt 03 is now split quality analyzer (no consolidation recommendations).

---

## Per-Prompt Cost Estimate

### Haiku Prompts (claude-haiku-4-5)

| Prompt | Purpose | Calls | Tokens/Call | Cost |
|--------|---------|-------|-------------|------|
| 00 | Metric extractor | 1 per repo | ~5,000 input, ~2,000 output | ~$0.012 |
| 01 | Cross-domain stability | 1 per repo | ~1,500 input, ~1,000 output | ~$0.005 |
| 02 | Cache anti-patterns | 3-5 per repo | ~2,000 input, ~800 output | ~$0.012 |
| 03 | Split quality | 1 per repo | ~1,500 input, ~1,000 output | ~$0.005 |
| 04 | Phantom deps | 1-2 per repo | ~2,000 input, ~800 output | ~$0.007 |
| **Haiku total (both repos)** | | | | **~$0.08** |

### Sonnet Prompts (claude-sonnet-4-6)

| Prompt | Purpose | Calls | Tokens/Call | Cost |
|--------|---------|-------|-------------|------|
| 06 | Structural diagnosis | 1 total | ~3,500 input, ~2,000 output | ~$0.08 |
| 07 | Migration plan | 1 total (optional) | ~2,500 input, ~2,000 output | ~$0.07 |
| **Sonnet total** | | | | **~$0.08–0.15** |

---

## Total Session Cost

```
Both repos Haiku analysis:    ~$0.08
Sonnet diagnosis (live demo): ~$0.08
Sonnet migration (optional):  ~$0.07
─────────────────────────────────────
Total:                        ~$0.15–0.23
```

---

## Why Prompt 00 Costs More Than Others

Prompt 00 receives the raw nx-graph.json which can be large.
To keep it manageable:
- The collector script limits domain-map to 150 entries
- Import frequency is capped at top 100
- File churn is capped at top 150 files

If your nx-graph.json is very large (200+ projects), you may hit
Haiku's context window. In that case: ask your gateway to trim the
graph JSON to just `nodes` and `dependencies` fields before sending.

---

## Prompts That Run Once vs Per-Lib

```
Run ONCE per repo:
  Prompt 00 — always
  Prompt 01 — always (processes crossDomainLibs array in one call)
  Prompt 03 — always (processes libClusters array in one call)
  Prompt 04 — always (processes suspectPairs array in one call)

Run PER LIB (batched up to 3 per call):
  Prompt 02 — for each high-impact lib needing cache analysis
              (only needs actual source code, so must be per-lib)

Run ONCE TOTAL (after both repos):
  Prompt 06 — the live demo Sonnet call
  Prompt 07 — optional, if judges ask about remediation
```

---

## Pricing Reference

| Model | Input per 1M tokens | Output per 1M tokens |
|-------|--------------------|--------------------|
| claude-haiku-4-5 | $0.80 | $4.00 |
| claude-sonnet-4-6 | $3.00 | $15.00 |

Verify current pricing at https://anthropic.com/pricing
