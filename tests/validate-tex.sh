#!/usr/bin/env bash
# LaTeX Validation Script
# Analyzes generated .tex files to verify correct RawBlock injection and structure
# Usage: ./tests/validate-tex.sh <tex-file>

set -euo pipefail

TEX_FILE="${1:-}"

if [[ -z "$TEX_FILE" || ! -f "$TEX_FILE" ]]; then
  echo "Usage: $0 <path-to-file.tex>" >&2
  exit 1
fi

RESULTS_DIR="$(mktemp -d)"
trap "rm -rf $RESULTS_DIR" EXIT

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILURES=0
WARNINGS=0

check_spurious_braces() {
  local count=$(grep -o '}{}' "$TEX_FILE" | wc -l)
  if [[ $count -gt 0 ]]; then
    echo -e "${RED}✗ FAIL${NC}: Found $count occurrences of spurious }{}}"
    FAILURES=$((FAILURES + 1))
  else
    echo -e "${GREEN}✓ PASS${NC}: No spurious }}} found"
  fi
}

check_section_color_order() {
  # Extract all lines with \setsectioncolor or \section{
  grep -n '\\setsectioncolor\|\\dghsection\|\\section{' "$TEX_FILE" | head -20 > "$RESULTS_DIR/section-commands.txt"
  
  if [[ -s "$RESULTS_DIR/section-commands.txt" ]]; then
    echo -e "${YELLOW}ℹ${NC} Section commands found:"
    cat "$RESULTS_DIR/section-commands.txt" | sed 's/^/  /'
    
    # Check if \setsectioncolor appears before \dghsection (or \section)
    local last_color_line=0
    local last_section_line=0
    
    while IFS= read -r line; do
      line_num="${line%%:*}"
      if [[ "$line" =~ \\setsectioncolor ]]; then
        last_color_line=$line_num
      elif [[ "$line" =~ \\dghsection|\\section ]]; then
        last_section_line=$line_num
      fi
    done < "$RESULTS_DIR/section-commands.txt"
    
    if [[ $last_color_line -gt 0 && $last_section_line -gt 0 ]]; then
      if [[ $last_color_line -lt $last_section_line ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Color set before section (line $last_color_line < $last_section_line)"
      else
        echo -e "${YELLOW}⚠ WARNING${NC}: Unexpected order: section before color"
        WARNINGS=$((WARNINGS + 1))
      fi
    fi
  fi
}

check_multicols_balance() {
  local open_count=$(grep -o '\\begin{multicols}' "$TEX_FILE" | wc -l)
  local close_count=$(grep -o '\\end{multicols}' "$TEX_FILE" | wc -l)
  
  if [[ $open_count -eq $close_count ]]; then
    echo -e "${GREEN}✓ PASS${NC}: Multicols balanced ($open_count open, $close_count close)"
  else
    echo -e "${RED}✗ FAIL${NC}: Multicols unbalanced ($open_count open, $close_count close)"
    FAILURES=$((FAILURES + 1))
  fi
}

check_begin_end_balance() {
  # Count all \begin{...} and \end{...}
  local begin_lines=$(grep -E '\\begin\{[a-zA-Z]+\}' "$TEX_FILE" | wc -l)
  local end_lines=$(grep -E '\\end\{[a-zA-Z]+\}' "$TEX_FILE" | wc -l)
  
  if [[ $begin_lines -eq $end_lines ]]; then
    echo -e "${GREEN}✓ PASS${NC}: Begin/end balanced ($begin_lines pairs)"
  else
    echo -e "${YELLOW}⚠ WARNING${NC}: Begin/end might be unbalanced ($begin_lines begin, $end_lines end)"
    WARNINGS=$((WARNINGS + 1))
  fi
}

check_raw_block_order() {
  # Look for patterns of RawBlock injections that depend on order
  # E.g., \setsectioncolor ... \newpage ... \section
  
  local found_issues=0
  
  # Extract a region around each \setsectioncolor
  grep -n '\\setsectioncolor' "$TEX_FILE" | while IFS= read -r line; do
    line_num="${line%%:*}"
    
    # Check next 5 lines for section command
    sed -n "${line_num},$((line_num + 5))p" "$TEX_FILE" | tail -n +2 | {
      if grep -q '\\dghsection\|\\section{'; then
        return 0  # Good order
      else
        echo -e "${YELLOW}⚠ WARNING${NC}: No section command within 5 lines of \setsectioncolor at line $line_num"
        WARNINGS=$((WARNINGS + 1))
      fi
    }
  done
}

check_colorlet_consistency() {
  # Verify that all color definitions are consistent
  local dup_colors=$(grep '\\colorlet' "$TEX_FILE" | cut -d'{' -f2 | cut -d'}' -f1 | sort | uniq -d)
  
  if [[ -z "$dup_colors" ]]; then
    echo -e "${GREEN}✓ PASS${NC}: No duplicate color definitions"
  else
    echo -e "${YELLOW}⚠ WARNING${NC}: Potentially duplicate color definitions:"
    echo "$dup_colors" | sed 's/^/  /'
    WARNINGS=$((WARNINGS + 1))
  fi
}

# ============================================================================
# Main validation
# ============================================================================

echo ""
echo "===== LaTeX Validation: $(basename "$TEX_FILE") ====="
echo ""

check_spurious_braces
echo ""

check_multicols_balance
echo ""

check_begin_end_balance
echo ""

check_section_color_order
echo ""

check_raw_block_order
echo ""

check_colorlet_consistency
echo ""

# Summary
echo "===== Summary ====="
if [[ $FAILURES -eq 0 ]]; then
  if [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}"
  else
    echo -e "${YELLOW}$WARNINGS warning(s) found${NC}"
  fi
  exit 0
else
  echo -e "${RED}$FAILURES failure(s) found${NC}"
  exit 1
fi
