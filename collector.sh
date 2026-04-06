#!/bin/bash

# ============================================================
# NX Monorepo Collector
# Run from the ROOT of each monorepo separately.
# Produces 5 files that feed into the AI prompt pipeline.
#
# Usage:
#   bash collector.sh <monorepo-id> <nx-scope-prefix>
#
# Example:
#   bash collector.sh monorepo-a @fidelity
#
# Outputs to: ./nx-analysis/<monorepo-id>/
# ============================================================

set -e

MONOREPO_ID=${1:-"monorepo-a"}
NX_SCOPE=${2:-"@your-scope"}
OUTPUT_DIR="./nx-analysis/${MONOREPO_ID}"

mkdir -p "$OUTPUT_DIR"

echo ""
echo "=================================================="
echo "  NX Monorepo Collector"
echo "  Repo ID : $MONOREPO_ID"
echo "  Scope   : $NX_SCOPE"
echo "  Output  : $OUTPUT_DIR"
echo "=================================================="
echo ""

# ----------------------------------------------------------
# FILE 1: NX project graph
# ----------------------------------------------------------
echo "[1/5] Generating NX project graph..."
npx nx graph --json > "$OUTPUT_DIR/nx-graph.json"
PROJECT_COUNT=$(cat "$OUTPUT_DIR/nx-graph.json" | python3 -c "import sys,json; g=json.load(sys.stdin); print(len(g['graph']['nodes']))" 2>/dev/null || echo "unknown")
echo "      ✓ nx-graph.json ($PROJECT_COUNT projects)"

# ----------------------------------------------------------
# FILE 2: Domain map — project name, tags, path
# ----------------------------------------------------------
echo "[2/5] Building domain map from project.json files..."
find . -name "project.json" \
  -not -path "*/node_modules/*" \
  -not -path "*/.nx/*" \
  -not -path "*/dist/*" \
  | while read f; do
      NAME=$(python3 -c "import sys,json; d=json.load(open('$f')); print(d.get('name',''))" 2>/dev/null)
      TAGS=$(python3 -c "import sys,json; d=json.load(open('$f')); print(','.join(d.get('tags',[])))" 2>/dev/null)
      DIR=$(dirname "$f")
      if [ -n "$NAME" ]; then
        echo "${NAME}|${TAGS}|${DIR}"
      fi
    done > "$OUTPUT_DIR/domain-map.txt"

LIB_COUNT=$(wc -l < "$OUTPUT_DIR/domain-map.txt")
echo "      ✓ domain-map.txt ($LIB_COUNT entries)"

# ----------------------------------------------------------
# FILE 3: File churn — how often each file changes (90 days)
# ----------------------------------------------------------
echo "[3/5] Computing file churn (last 90 days)..."
git log \
  --since="90 days ago" \
  --name-only \
  --pretty=format: \
  | grep -v '^$' \
  | grep -E '\.(ts|html|scss)$' \
  | grep -v '\.spec\.ts$' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -150 \
  > "$OUTPUT_DIR/file-churn.txt"

CHURN_COUNT=$(wc -l < "$OUTPUT_DIR/file-churn.txt")
echo "      ✓ file-churn.txt ($CHURN_COUNT files with changes)"

# ----------------------------------------------------------
# FILE 4: Import frequency — which libs are imported most
# ----------------------------------------------------------
echo "[4/5] Analyzing import patterns..."
grep -r "from '${NX_SCOPE}/" \
  --include="*.ts" \
  -h \
  . \
  2>/dev/null \
  | grep -v "node_modules" \
  | grep -v "\.spec\.ts" \
  | sed "s/.*from '\(${NX_SCOPE}\/[^']*\)'.*/\1/" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -100 \
  > "$OUTPUT_DIR/import-frequency.txt"

IMPORT_COUNT=$(wc -l < "$OUTPUT_DIR/import-frequency.txt")
echo "      ✓ import-frequency.txt ($IMPORT_COUNT unique imports)"

# ----------------------------------------------------------
# FILE 5: NX tag summary — unique tags used across all libs
# ----------------------------------------------------------
echo "[5/5] Extracting NX tag taxonomy..."
cat "$OUTPUT_DIR/domain-map.txt" \
  | cut -d'|' -f2 \
  | tr ',' '\n' \
  | grep -v '^$' \
  | sort \
  | uniq -c \
  | sort -rn \
  > "$OUTPUT_DIR/tag-summary.txt"

TAG_COUNT=$(wc -l < "$OUTPUT_DIR/tag-summary.txt")
echo "      ✓ tag-summary.txt ($TAG_COUNT unique tags)"

# ----------------------------------------------------------
# Summary
# ----------------------------------------------------------
echo ""
echo "=================================================="
echo "  Collection complete"
echo "=================================================="
echo ""
echo "  Files ready for AI pipeline:"
echo ""
ls -lh "$OUTPUT_DIR/"
echo ""
echo "  Next: paste these files into Prompt 00"
echo "  See: scripts/run-order.md for exact instructions"
echo ""
