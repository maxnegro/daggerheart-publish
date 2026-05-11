#!/usr/bin/env bash
# Test suite for daggerheart-publish
# Usage: ./tests/test-suite.sh [--baseline] [--verbose]
# 
# --baseline: Generate baseline PDFs (do this before making changes)
# --verbose: Show detailed compilation output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BASELINE_MODE=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline)
      BASELINE_MODE=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

RESULTS_DIR="$ROOT_DIR/tests/results"
BASELINE_DIR="$ROOT_DIR/tests/baseline"
FIXTURES_DIR="$ROOT_DIR/tests/fixtures"
BOOKS_DIR="$ROOT_DIR/books"

mkdir -p "$RESULTS_DIR"
mkdir -p "$BASELINE_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# Log file
LOGFILE="$RESULTS_DIR/test-results.log"
> "$LOGFILE"

log_line() {
  echo -e "$1" | tee -a "$LOGFILE"
}

log_test_start() {
  local name="$1"
  TOTAL=$((TOTAL + 1))
  log_line "[$(printf '%2d' $TOTAL)] Testing: $name"
}

log_test_pass() {
  local name="$1"
  PASSED=$((PASSED + 1))
  log_line "  ${GREEN}✓ PASS${NC}: $name"
}

log_test_fail() {
  local name="$1"
  local reason="$2"
  FAILED=$((FAILED + 1))
  log_line "  ${RED}✗ FAIL${NC}: $name"
  log_line "    Reason: $reason"
}

log_test_warning() {
  local name="$1"
  local msg="$2"
  WARNINGS=$((WARNINGS + 1))
  log_line "  ${YELLOW}⚠ WARNING${NC}: $name"
  log_line "    Message: $msg"
}

compile_book() {
  local book_path="$1"
  local output_pdf="$2"
  local temp_log="$RESULTS_DIR/compile-$$.log"

  if [[ $VERBOSE -eq 1 ]]; then
    if "$ROOT_DIR/scripts/build.sh" "$book_path" "$output_pdf" 2>&1 | tee -a "$temp_log"; then
      return 0
    else
      return 1
    fi
  else
    if "$ROOT_DIR/scripts/build.sh" "$book_path" "$output_pdf" >"$temp_log" 2>&1; then
      return 0
    else
      cat "$temp_log" >> "$LOGFILE"
      return 1
    fi
  fi
}

validate_pdf_exists() {
  local pdf="$1"
  if [[ -f "$pdf" && -s "$pdf" ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Test: Books compilation
# ============================================================================

log_line ""
log_line "====== BOOK COMPILATION TESTS ======"

for book_dir in "$BOOKS_DIR"/*; do
  if [[ -d "$book_dir" && -f "$book_dir/book.md" ]]; then
    book_name="$(basename "$book_dir")"
    output_pdf="$RESULTS_DIR/${book_name}.pdf"
    
    log_test_start "Book: $book_name"
    
    if compile_book "$book_dir" "$output_pdf"; then
      if validate_pdf_exists "$output_pdf"; then
        log_test_pass "Book: $book_name"
        
        # If in baseline mode, copy to baseline
        if [[ $BASELINE_MODE -eq 1 ]]; then
          cp "$output_pdf" "$BASELINE_DIR/${book_name}.pdf"
          log_line "    Baseline saved: $BASELINE_DIR/${book_name}.pdf"
        fi
      else
        log_test_fail "Book: $book_name" "PDF generated but is invalid or empty"
      fi
    else
      log_test_fail "Book: $book_name" "Compilation failed"
    fi
  fi
done

# ============================================================================
# Test: Fixture compilation (critical cases)
# ============================================================================

log_line ""
log_line "====== FIXTURE COMPILATION TESTS ======"

for fixture_file in "$FIXTURES_DIR"/*.md; do
  if [[ -f "$fixture_file" ]]; then
    fixture_name="$(basename "$fixture_file" .md)"
    fixture_dir="$RESULTS_DIR/fixture-$fixture_name"
    output_pdf="$fixture_dir/$fixture_name.pdf"
    
    mkdir -p "$fixture_dir"

    # Fixture-specific assets
    if [[ "$fixture_name" == "test-framecoverpage" ]]; then
      mkdir -p "$fixture_dir/assets"
      cp "$ROOT_DIR/books/test-frame-cover/assets/cover-library.png" "$fixture_dir/assets/cover-library.png"
    fi
    
    # Create minimal book.md wrapper
    cat > "$fixture_dir/book.md" <<'EOF'
---
title: Test Fixture
subtitle: Fixture Validation
author: Test Suite
designer: Test System
documentclass: daggerheart
lang: italian
toc: false
---
EOF
    
    cp "$fixture_file" "$fixture_dir/chapter.md"
    
    # Create chapters directory
    mkdir -p "$fixture_dir/chapters"
    mv "$fixture_dir/chapter.md" "$fixture_dir/chapters/01-test.md"
    
    log_test_start "Fixture: $fixture_name"
    
    if compile_book "$fixture_dir" "$output_pdf"; then
      if validate_pdf_exists "$output_pdf"; then
        log_test_pass "Fixture: $fixture_name"
        
        if [[ $BASELINE_MODE -eq 1 ]]; then
          cp "$output_pdf" "$BASELINE_DIR/fixture-${fixture_name}.pdf"
          log_line "    Baseline saved: $BASELINE_DIR/fixture-${fixture_name}.pdf"
        fi
      else
        log_test_fail "Fixture: $fixture_name" "PDF generated but is invalid or empty"
      fi
    else
      log_test_fail "Fixture: $fixture_name" "Compilation failed"
    fi
  fi
done

# ============================================================================
# Test: LaTeX intermediate validation (when KEEP_TEX=1)
# ============================================================================

log_line ""
log_line "====== LATEX VALIDATION TESTS ======"
log_line "To enable LaTeX validation, compile with KEEP_TEX=1"
log_line "Example: KEEP_TEX=1 make build"

# ============================================================================
# Summary
# ============================================================================

log_line ""
log_line "====== TEST SUMMARY ======"
log_line "Total tests:  $TOTAL"
log_line "Passed:       ${GREEN}$PASSED${NC}"
log_line "Failed:       $(if [[ $FAILED -eq 0 ]]; then echo "${GREEN}$FAILED${NC}"; else echo "${RED}$FAILED${NC}"; fi)"
log_line "Warnings:     $(if [[ $WARNINGS -eq 0 ]]; then echo "$WARNINGS"; else echo "${YELLOW}$WARNINGS${NC}"; fi)"
log_line ""

if [[ $BASELINE_MODE -eq 1 ]]; then
  log_line "Baseline PDFs generated in: $BASELINE_DIR"
  log_line "Next time, run without --baseline to test against baseline."
fi

log_line ""
log_line "Full log saved to: $LOGFILE"

# Exit code
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}$FAILED test(s) failed!${NC}"
  exit 1
fi
