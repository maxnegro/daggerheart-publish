#!/usr/bin/env bash
# B1.1 golden behavior check for H1 pipeline.
# Verifies current LaTeX command pattern for 3 H1 cases:
# - default H1
# - custom color H1
# - background H1 (bg is valid only for H1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$ROOT_DIR/tests/results"

mkdir -p "$RESULTS_DIR"

TMP_BOOK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_BOOK_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_BOOK_DIR/chapters" "$TMP_BOOK_DIR/assets"

cat > "$TMP_BOOK_DIR/book.md" <<'BOOK'
---
title: B1.1 Golden H1
subtitle: Golden behavior snapshot
author: Test Suite
designer: Test System
documentclass: daggerheart
lang: italian
toc: false
---
BOOK

cp "$ROOT_DIR/tests/golden/b1-h1-cases.md" "$TMP_BOOK_DIR/chapters/01-b1-h1-cases.md"
cp "$ROOT_DIR/tests/golden/assets/section-header.png" "$TMP_BOOK_DIR/assets/section-header.png"

OUT_PDF="$RESULTS_DIR/golden-b1-h1.pdf"
OUT_TEX="$RESULTS_DIR/golden-b1-h1.tex"

KEEP_TEX=1 "$ROOT_DIR/scripts/build.sh" "$TMP_BOOK_DIR" "$OUT_PDF" >/dev/null

if [[ ! -f "$OUT_TEX" ]]; then
  echo "ERROR: expected LaTeX output not found: $OUT_TEX" >&2
  exit 1
fi

fail() {
  echo "B1.1 FAIL: $1" >&2
  exit 1
}

# Case 1: H1 with custom color should emit setsectioncolor and color reset toggles.
grep -Fq "\\setsectioncolor{dg-red}{dg-red}" "$OUT_TEX" || fail "missing setsectioncolor for red H1"
grep -Fq "\\global\\dgresetsectioncoloronnextsectionfalse" "$OUT_TEX" || fail "missing color reset disable toggle"
grep -Fq "\\global\\dgresetsectioncoloronnextsectiontrue" "$OUT_TEX" || fail "missing color reset re-enable toggle"

# Case 2: H1 with bg should emit sectionwithbg pipeline commands.
grep -Fq "\\setsectioncolor{dg-purple}{dg-purple}" "$OUT_TEX" || fail "missing setsectioncolor for purple H1 bg"
grep -Fq "\\setdghsectionbgheight{150pt}" "$OUT_TEX" || fail "missing default bg height command"
grep -Fq "\\setdghsectionbgraise{-18pt}" "$OUT_TEX" || fail "missing default bg raise command"
grep -Fq "\\resetdghsectionbgfadeoffset" "$OUT_TEX" || fail "missing default bg fade reset command"
grep -Fq "\\sectionwithbg{assets/section-header.png}{" "$OUT_TEX" || fail "missing sectionwithbg command with expected asset"

# Case 3: default H1 should NOT inject setsectioncolor for default title.
# We assert exact count 2 (red + purple only).
setsectioncolor_count="$(grep -Fo "\\setsectioncolor{" "$OUT_TEX" | wc -l | tr -d ' ')"
[[ "$setsectioncolor_count" == "2" ]] || fail "unexpected setsectioncolor count: $setsectioncolor_count (expected 2)"

# Ensure all three H1 titles are present in generated sections.
grep -Fq "\\section{Titolo con" "$OUT_TEX" || fail "missing section title for custom color H1"
grep -Fq "\\sectionwithbg{assets/section-header.png}{Titolo con bg" "$OUT_TEX" || fail "missing sectionwithbg title"
grep -Fq "\\section{Titolo default con" "$OUT_TEX" || fail "missing section title for default H1"

echo "B1.1 PASS: golden H1 LaTeX behavior is stable"
