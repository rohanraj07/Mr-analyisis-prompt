# Prompt 08 — Sonnet 4.6: RFC / ADR Drafter

## Purpose
Generate a draft Architecture Decision Record for a novel pattern detected by Prompt 05.
The draft includes open questions for human decision-makers — it does not make the decision,
it structures it.

## Model
`claude-sonnet-4-6`

## When To Run
Only when Prompt 05 (Haiku RFC Detector) returns `requiresADR: true`.
Do NOT run this proactively — it's gated by the Haiku detector.

## Token Target
Input: ~1,500–2,000 tokens. Output: ~1,000–1,500 tokens.

---

## The Prompt

```
You are a principal architect drafting an Architecture Decision Record for a novel pattern
detected in a PR at a financial services organization using NX monorepo (Angular + NestJS),
structured with Domain-Driven Design.

YOUR ROLE:
- Draft the ADR structure so decision-makers have everything they need to decide quickly
- Surface open questions explicitly — do NOT make architectural decisions yourself
- Be concrete about consequences, especially negative ones (reviewers trust ADRs that admit tradeoffs)
- Write as if a senior engineer 6 months from now will read this when they don't understand why
  something was built a certain way

ORGANIZATION CONTEXT:
- Angular + NestJS in NX monorepo
- DDD structure with scope: and type: tags
- Financial services — security, compliance, and auditability matter
- Akamai WAF in front of Angular apps
- Kubernetes deployment for NestJS services
- NX Cloud for distributed caching

EXISTING ADRS (for context and numbering — do not duplicate these decisions):
{{#each existing_adrs}}
ADR-{{number}}: {{title}} [{{status}}]
{{/each}}

NEXT ADR NUMBER: {{next_adr_number}}

INPUT: PR data that triggered this RFC.
---
PR TITLE: {{pr_title}}
PR DESCRIPTION: {{pr_description}}
PATTERN TYPE DETECTED: {{pattern_type}}
NOVELTY ASSESSMENT: {{novelty_from_haiku_prompt}}
WHO SHOULD DECIDE: {{decision_maker}}

KEY CODE FROM PR (relevant sections only — keep under 30 lines):
{{relevant_code_snippet}}

HAIKU DETECTION REASON:
{{haiku_reason}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "adr": {
    "number": "ADR-{{next_adr_number}}",
    "title": "<clear, specific title — not generic>",
    "date": "<today's date>",
    "status": "proposed",
    "decider": "{{decision_maker}}",

    "context": {
      "problem": "<2-3 sentences: what specific problem this pattern solves>",
      "trigger": "<what in this PR made this decision necessary now>",
      "constraints": ["<technical constraint>", "<org constraint>", "<compliance constraint if relevant>"]
    },

    "decisionOptions": [
      {
        "option": "A",
        "description": "<what option A is>",
        "pros": ["<pro 1>", "<pro 2>"],
        "cons": ["<con 1>", "<con 2>"],
        "nxCacheImpact": "<how this option affects NX caching>",
        "effortEstimate": "<implementation effort>"
      },
      {
        "option": "B",
        "description": "<what option B is>",
        "pros": ["<pro 1>", "<pro 2>"],
        "cons": ["<con 1>", "<con 2>"],
        "nxCacheImpact": "<how this option affects NX caching>",
        "effortEstimate": "<implementation effort>"
      }
    ],

    "proposedDecision": {
      "choice": "A" | "B" | "undecided",
      "rationale": "<why this option if a choice is proposed, or why undecided>",
      "confidence": "high" | "medium" | "low"
    },

    "consequences": {
      "positive": [
        "<consequence 1>",
        "<consequence 2>"
      ],
      "negative": [
        "<tradeoff 1 — be honest>",
        "<tradeoff 2>"
      ],
      "neutral": [
        "<thing that changes but is neither good nor bad>"
      ]
    },

    "openQuestions": [
      {
        "question": "<specific question that needs a human decision>",
        "neededFrom": "<who can answer this>",
        "blocksImplementation": true | false
      }
    ],

    "implementationGuidance": {
      "affectedNxScopes": ["<scope names>"],
      "newLibrariesRequired": ["<lib name: description>"],
      "eslintRulesToAdd": ["<rule>"],
      "breakingChanges": true | false,
      "migrationRequired": true | false,
      "exampleUsage": "<short code example of the correct pattern, max 15 lines>"
    },

    "reviewers": ["<role or team who should review this ADR before approval>"]
  }
}
```

---

## Example: WebSocket ADR Draft

### Input
```
PR TITLE: feat(auth): implement WebSocket session invalidation
PATTERN TYPE: technology-adoption
NOVELTY: First use of WebSocket — establishes patterns for real-time features
WHO SHOULD DECIDE: principal-architect
```

### Output (abbreviated)
```json
{
  "adr": {
    "number": "ADR-008",
    "title": "WebSocket Gateway Pattern for Real-Time Server-Push Events",
    "status": "proposed",
    "decider": "principal-architect",
    "context": {
      "problem": "Session invalidation currently requires clients to poll for status. This adds latency and unnecessary load. A server-push mechanism is needed.",
      "trigger": "PR #2891 introduced Socket.io for session invalidation, establishing a pattern others will follow for real-time features.",
      "constraints": [
        "Akamai WAF must be configured to allow WebSocket upgrade requests",
        "Kubernetes ingress requires sticky sessions or Redis pub/sub for multi-pod WebSocket",
        "All real-time events must be auditable for compliance"
      ]
    },
    "decisionOptions": [
      {
        "option": "A",
        "description": "Socket.io with NestJS @WebSocketGateway and Redis adapter for multi-pod support",
        "pros": ["Bidirectional communication", "Auto-reconnect built in", "Room/namespace support"],
        "cons": ["Requires Redis pub/sub setup", "Akamai config change needed", "More complex than SSE"],
        "nxCacheImpact": "New shared-websocket-gateway lib adds to critical path for all auth consumers",
        "effortEstimate": "3-5 days including infrastructure"
      },
      {
        "option": "B",
        "description": "Server-Sent Events (SSE) via NestJS — unidirectional, simpler, HTTP-based",
        "pros": ["No Akamai config change", "Works through existing proxies", "HTTP/2 multiplexing"],
        "cons": ["Unidirectional only", "No built-in reconnect in older browsers", "Less ecosystem support"],
        "nxCacheImpact": "Smaller shared lib, lower fan-out risk",
        "effortEstimate": "1-2 days"
      }
    ],
    "openQuestions": [
      {
        "question": "Has Akamai WAF been configured to allow WebSocket upgrade? Who owns that config?",
        "neededFrom": "Infrastructure/Platform team",
        "blocksImplementation": true
      },
      {
        "question": "Do we need bidirectional communication now, or only server-push? This determines if SSE is sufficient.",
        "neededFrom": "Product owner + auth team lead",
        "blocksImplementation": true
      }
    ]
  }
}
```

---

## Post-Draft Workflow

```
1. Draft generated → save as ADR-XXX-draft.json
2. Convert to markdown for Confluence/GitHub using your template
3. Route to `decider` and `reviewers`
4. Once approved: update status to "accepted"
5. Add eslint rules from `implementationGuidance.eslintRulesToAdd`
6. Create any libraries from `implementationGuidance.newLibrariesRequired`
```