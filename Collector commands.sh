#!/bin/bash

# ============================================================
# NX Monorepo Collector Script
# Run from the ROOT of each monorepo separately
# Outputs structured files for AI analysis pipeline
# ============================================================

set -e

MONOREPO_NAME=${1:-"monorepo-a"}
OUTPUT_DIR="./nx-analysis-output/${MONOREPO_NAME}"
mkdir -p "$OUTPUT_DIR"

echo "============================================"
echo " NX Monorepo Collector"
echo " Monorepo: $MONOREPO_NAME"
echo " Output:   $OUTPUT_DIR"
echo "============================================"

# ------------------------------------------------------------
# COLLECT 1: Full project graph (nodes + edges)
# ------------------------------------------------------------
echo "[1/6] Exporting NX project graph..."
npx nx graph --json > "$OUTPUT_DIR/nx-graph.json"
echo "      ✓ nx-graph.json"

# ------------------------------------------------------------
# COLLECT 2: All project.json configs (tags, targets, deps)
# ------------------------------------------------------------
echo "[2/6] Collecting project configs..."
find . -name "project.json" \
  -not -path "*/node_modules/*" \
  -not -path "*/.nx/*" \
  | while read f; do
      echo "=== $f ==="
      cat "$f"
      echo ""
    done > "$OUTPUT_DIR/all-project-configs.txt"
echo "      ✓ all-project-configs.txt"

# ------------------------------------------------------------
# COLLECT 3: File churn - commit velocity per file (90 days)
# ------------------------------------------------------------
echo "[3/6] Computing file churn (last 90 days)..."
git log \
  --since="90 days ago" \
  --name-only \
  --pretty=format: \
  | grep -v '^$' \
  | grep -E '\.(ts|html|scss|json)$' \
  | sort \
  | uniq -c \
  | sort -rn \
  > "$OUTPUT_DIR/file-churn.txt"
echo "      ✓ file-churn.txt"

# ------------------------------------------------------------
# COLLECT 4: Import frequency across monorepo
# Replace @your-scope with your actual NX scope prefix
# e.g. @myorg, @fidelity, @acme
# ------------------------------------------------------------
echo "[4/6] Analyzing import patterns..."
SCOPE_PREFIX=${2:-"@your-scope"}

grep -r "from '${SCOPE_PREFIX}/" \
  --include="*.ts" \
  -h \
  . \
  | grep -v "node_modules" \
  | grep -v "\.spec\.ts" \
  | sed "s/.*from '\(${SCOPE_PREFIX}\/[^']*\)'.*/\1/" \
  | sort \
  | uniq -c \
  | sort -rn \
  > "$OUTPUT_DIR/import-frequency.txt"
echo "      ✓ import-frequency.txt"

# ------------------------------------------------------------
# COLLECT 5: NX tags per project (domain map)
# ------------------------------------------------------------
echo "[5/6] Building domain map from NX tags..."
find . -name "project.json" \
  -not -path "*/node_modules/*" \
  -not -path "*/.nx/*" \
  | while read f; do
      PROJECT=$(cat "$f" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','unknown'))" 2>/dev/null || echo "unknown")
      TAGS=$(cat "$f" | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d.get('tags',[])))" 2>/dev/null || echo "")
      echo "${PROJECT}|${TAGS}"
    done > "$OUTPUT_DIR/domain-map.txt"
echo "      ✓ domain-map.txt"

# ------------------------------------------------------------
# COLLECT 6: NX affected dry-run (shows critical path)
# Run against main/master to see what a typical change touches
# ------------------------------------------------------------
echo "[6/6] Sampling affected project spread..."
npx nx affected:apps --dry-run 2>/dev/null \
  > "$OUTPUT_DIR/affected-sample.txt" || \
  echo "affected dry-run skipped (no base ref)" \
  > "$OUTPUT_DIR/affected-sample.txt"
echo "      ✓ affected-sample.txt"

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
echo ""
echo "============================================"
echo " Collection complete for: $MONOREPO_NAME"
echo " Files saved to: $OUTPUT_DIR"
echo "============================================"
echo ""
echo " Next steps:"
echo " 1. Run this script on your SECOND monorepo:"
echo "    bash collector-commands.sh monorepo-b @your-scope"
echo ""
echo " 2. Compute structural metrics from collected files"
echo " 3. Run Haiku prompts on flagged items"
echo " 4. Run Sonnet once with aggregated findings"
echo ""
echo " Files to feed into AI pipeline:"
ls -lh "$OUTPUT_DIR/"