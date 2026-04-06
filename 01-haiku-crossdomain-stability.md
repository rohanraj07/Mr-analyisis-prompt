# Prompt 01 — Haiku: Cross-Domain Stability Analyzer

## Model: claude-haiku-4-5
## Input: crossDomainLibs array from Prompt 00 output
## Purpose: Determine if each cross-domain shared lib is stable enough for its role

---

## What This Prompt Does NOT Do

- Does NOT flag cross-domain dependencies as violations
- Does NOT recommend removing cross-domain sharing
- Does NOT treat high lib count as a problem

## What This Prompt DOES Do

Cross-domain sharing is intentional and correct in this monorepo.
But a lib shared across 4 domains that changes 50x in 90 days
invalidates builds in all 4 domains on every commit — regardless
of NX Cloud configuration.

This prompt asks: **is each shared lib stable enough to carry that responsibility?**

If not stable: WHY is it churning? That's the actionable finding.

---

## The Prompt

Copy everything below. Fill in the {{variables}}. Paste into gateway.

---

```
You are analyzing cross-domain library stability in an NX monorepo.

ARCHITECTURAL CONTEXT:
Cross-domain dependencies are INTENTIONAL in this codebase — do not question them.
Libs are shared across domain scopes deliberately for reuse.
Your job is to assess whether each shared lib is STABLE ENOUGH for its role.

A shared lib that changes frequently causes cache invalidation across ALL domains
that depend on it. This is the primary driver of slow builds in large NX monorepos —
not the cross-domain pattern itself, but instability in the libs at its center.

STABILITY THRESHOLDS:
- GREEN  (stable):    < 10 commits / 90 days for a widely shared lib
- YELLOW (watch):     10-25 commits / 90 days
- RED    (unstable):  > 25 commits / 90 days AND depended on by 3+ domains

BLAST RADIUS:
The real cost of a commit to lib X =
  (number of domains depending on X) × (downstream apps per domain)
A lib with blast_radius_score > 50 needs scrutiny regardless of commit count.

INPUT: Cross-domain libs identified by Prompt 00.
---
CROSS DOMAIN LIBS:
{{paste crossDomainLibs array from prompt00-output.json here}}
---

For each lib, assess:
1. Is it stable enough for its sharing role? (green/yellow/red)
2. If yellow or red: what is likely causing the churn?
   Possible root causes:
   - Mixed responsibilities (doing too much — split candidate)
   - Acting as an integration layer (changes cascade from multiple teams)
   - Contains configuration that changes per environment
   - Business logic that should be in a feature lib not a domain lib
   - Shared types mixed with shared implementations (should be two separate libs)
3. What is the specific recommendation?
   Options:
   - STABLE: no action needed, this shared lib is working correctly
   - EXTRACT_CONTRACTS: separate the stable type contracts from the
     changing implementation into two libs — consumers of contracts
     stop rebuilding when implementation changes
   - CLARIFY_OWNERSHIP: lib has no clear owner so everyone touches it —
     assign ownership, set contribution guidelines
   - SPLIT_BY_STABILITY: lib has stable parts and volatile parts mixed —
     extract the stable exports into a separate lib
   - INVESTIGATE: churn source unclear from metrics alone

Respond ONLY in this exact JSON array. No markdown. No preamble.

[
  {
    "project": "<lib name>",
    "tags": "<tags>",
    "dependentDomains": ["<scope:x>", "<scope:y>"],
    "domainCount": <number>,
    "commits90d": <number>,
    "blastRadiusScore": <number>,
    "stabilityRating": "green" | "yellow" | "red",
    "churnRootCause": "<one sentence: why is this lib changing so often, or null if stable>",
    "recommendation": "STABLE" | "EXTRACT_CONTRACTS" | "CLARIFY_OWNERSHIP" | "SPLIT_BY_STABILITY" | "INVESTIGATE",
    "recommendationDetail": "<one sentence: exactly what to do>",
    "estimatedBuildImpact": "<e.g. reducing churn here saves X domains from rebuilding, or null if stable>",
    "effort": "days" | "weeks" | "none"
  }
]
```

---

## After You Get The Response

Save as: `nx-analysis/monorepo-a/prompt01-output.json`

For Prompt 06 (Sonnet), extract only:
- Items where `stabilityRating` is `"red"`
- Items where `blastRadiusScore` > 30

These are your critical findings. Leave green and yellow out of the Sonnet payload.
