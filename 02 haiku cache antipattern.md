# Prompt 02 — Haiku: Cache Anti-Pattern Detector

## Purpose
Detect code patterns inside a source file that prevent NX from caching build outputs correctly.
Run on every file belonging to a project with cache hit rate below your threshold (recommended: 70%).

## Model
`claude-haiku-4-5`

## When To Run
1. Get cache hit rates from NX Cloud API (last 10 builds)
2. Flag all projects with hit rate < 70%
3. For each flagged project, run this prompt on its source files
   - Prioritize: `index.ts` (barrel files), `*.config.ts`, `environment*.ts`, service files
   - Skip: `*.spec.ts` files (test files don't affect build cache)

## Input Required
- `project_name` — NX project name
- `cache_hit_rate` — percentage from NX Cloud (e.g. 23)
- `file_path` — relative path to the file
- `file_content` — full content of the file (keep files under 300 lines for token efficiency)

---

## The Prompt

```
You are an NX build cache expert. You detect code patterns that prevent NX from caching
build outputs correctly, causing unnecessary rebuilds in Angular and NestJS projects.

NX CACHE MECHANICS:
- NX caches based on: input file hashes + task configuration hash
- If any input changes, the entire task reruns and cache is invalidated
- Cache busters: anything that changes the OUTPUT of a build without changing INPUT files
- Angular-specific: anything embedded at build time via environment files or build plugins
- NestJS-specific: anything that changes module metadata at compile time

KNOWN CACHE-BUSTING ANTI-PATTERNS:
1. TIMESTAMP     - Date.now(), new Date(), BUILD_TIME embedded at build time
2. RANDOM        - Math.random(), crypto.randomUUID() called at module initialization
3. ENV_LEAK      - process.env variables embedded in build output (not runtime-resolved)
4. FILE_HASH     - Reading file contents and embedding hash at build time
5. GIT_INFO      - Embedding git commit SHA, branch name, or dirty flag at build time
6. BARREL_TRAP   - index.ts re-exports EVERYTHING including heavy unused modules,
                   causing all consumers to rebuild when any export changes
7. DYNAMIC_IMPORT - import() paths constructed from variables (breaks static analysis)
8. GLOB_IMPORT   - require.context or dynamic glob patterns at module level
9. SIDE_EFFECT   - Module-level code with side effects that touch the filesystem or network
10. VERSION_EMBED - Embedding package.json version at build time without NX input config

INPUT: File to analyze.
---
PROJECT: {{project_name}}
CACHE HIT RATE (last 10 builds): {{cache_hit_rate}}%
FILE PATH: {{file_path}}
FILE TYPE: {{angular-component | angular-service | nestjs-service | nestjs-module | barrel | config | environment | other}}

FILE CONTENT:
{{file_content}}
---

Respond ONLY in this exact JSON. No markdown. No explanation outside the JSON object.

{
  "hasAntiPattern": true | false,
  "patterns": [
    {
      "type": "<pattern name from list above>",
      "lineNumber": <integer or null>,
      "snippet": "<exact problematic code, max 100 chars>",
      "impact": "high" | "medium" | "low",
      "explanation": "<one sentence: why this busts the cache>",
      "fix": "<one sentence: exactly what to change>",
      "fixExample": "<optional: short code snippet showing the fix>"
    }
  ],
  "overallCacheImpact": "high" | "medium" | "low" | "none",
  "estimatedHitRateImprovement": "<e.g. +30-50% if this is fixed, or null if uncertain>"
}
```

---

## Example Input

```
PROJECT: auth-service
CACHE HIT RATE (last 10 builds): 18%
FILE PATH: libs/auth/src/lib/auth.config.ts
FILE TYPE: config

FILE CONTENT:
export const AUTH_CONFIG = {
  version: '1.0.0',
  buildTime: new Date().toISOString(),
  commitHash: process.env.GIT_COMMIT || 'local',
  features: {
    mfa: true,
    oauth: false
  }
};
```

## Example Output

```json
{
  "hasAntiPattern": true,
  "patterns": [
    {
      "type": "TIMESTAMP",
      "lineNumber": 3,
      "snippet": "buildTime: new Date().toISOString()",
      "impact": "high",
      "explanation": "new Date() is evaluated at build time, generating a different value on every build and invalidating NX cache every run.",
      "fix": "Remove buildTime from build-time config; inject it at runtime via an API endpoint or Angular APP_INITIALIZER.",
      "fixExample": "// Remove from config. At runtime: inject HttpClient and call /api/build-info"
    },
    {
      "type": "GIT_INFO",
      "lineNumber": 4,
      "snippet": "commitHash: process.env.GIT_COMMIT || 'local'",
      "impact": "high",
      "explanation": "Embedding GIT_COMMIT at build time means every commit produces a unique build output, defeating NX's content-based caching.",
      "fix": "If you need the commit hash, expose it via a runtime environment variable resolved by the server, not embedded at build time.",
      "fixExample": "// In NestJS: return { commitHash: process.env.GIT_COMMIT } from a /health endpoint"
    }
  ],
  "overallCacheImpact": "high",
  "estimatedHitRateImprovement": "+60-80% — these two patterns alone explain the 18% hit rate"
}
```

---

## Barrel File Special Case

Barrel files (`index.ts`) need extra scrutiny. Run this check first:

```typescript
// Red flag: re-exporting everything from a deeply nested path
export * from './internal/heavy-module';
export * from './internal/rarely-used-utils';

// Better: explicit named exports only
export { AuthService } from './internal/auth.service';
export { AuthGuard } from './internal/auth.guard';
```

If a barrel file has more than 20 `export *` statements, flag it automatically
as a BARREL_TRAP without needing AI — it's always a problem at that scale.

---

## Output Aggregation

After all files are processed, group by project:

```json
{
  "projectName": "auth-service",
  "currentCacheHitRate": 18,
  "patternsFound": 3,
  "highImpactCount": 2,
  "estimatedImprovedRate": "75-85%",
  "files": [...]
}
```

Feed only `high` impact findings per project into Prompt 06 (Sonnet diagnosis).