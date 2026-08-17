#!/usr/bin/env bash
# Helper script to view visual differences between generated and baseline PDFs
# Usage: ./tests/view-diff.sh test-name
# Example: ./tests/view-diff.sh "test-colored-table"
#          ./tests/view-diff.sh "example"
#          ./tests/view-diff.sh "Fixture_test-colored-table"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <test-name>"
  echo ""
  echo "Available diffs:"
  ls tests/results/diff-*.pdf 2>/dev/null | sed 's|tests/results/diff-||; s|.pdf||' | while read name; do
    echo "  $name"
  done
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_NAME="$1"

# Try multiple patterns to find the diff file
DIFF_FILE=""
if [[ -f "$ROOT_DIR/tests/results/diff-${TEST_NAME}.pdf" ]]; then
  DIFF_FILE="$ROOT_DIR/tests/results/diff-${TEST_NAME}.pdf"
elif [[ -f "$ROOT_DIR/tests/results/diff-Fixture_${TEST_NAME}_.pdf" ]]; then
  DIFF_FILE="$ROOT_DIR/tests/results/diff-Fixture_${TEST_NAME}_.pdf"
elif [[ -f "$ROOT_DIR/tests/results/diff-Book_${TEST_NAME}_.pdf" ]]; then
  DIFF_FILE="$ROOT_DIR/tests/results/diff-Book_${TEST_NAME}_.pdf"
else
  # Search for partial match
  DIFF_FILE=$(find "$ROOT_DIR/tests/results" -name "diff-*${TEST_NAME}*.pdf" -type f | head -1)
fi

if [[ -z "$DIFF_FILE" || ! -f "$DIFF_FILE" ]]; then
  echo "❌ Diff not found for: $TEST_NAME"
  echo ""
  echo "Run the test suite first to generate diffs:"
  echo "  ./tests/test-suite.sh"
  exit 1
fi

echo "📄 Opening visual diff: $DIFF_FILE"
xdg-open "$DIFF_FILE" 2>/dev/null || open "$DIFF_FILE" 2>/dev/null || echo "Please open: $DIFF_FILE"
