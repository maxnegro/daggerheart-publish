#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/build.sh <input.md> [output.pdf]

Environment variables:
  ASSETS_DIR     Path to local assets directory containing fonts/photos (default: ./assets)
  KEEP_WORKDIR   Set to 1 to keep temporary build directory
  KEEP_TEX       Set to 1 to keep generated .tex alongside the output PDF
  ENABLE_TOC     Set to 0 to disable automatic table of contents
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

INPUT_MD="$(realpath "$1")"
if [[ ! -f "$INPUT_MD" ]]; then
  echo "Input markdown file not found: $INPUT_MD" >&2
  exit 1
fi

if [[ $# -ge 2 ]]; then
  OUTPUT_PDF="$(realpath -m "$2")"
else
  INPUT_BASENAME="$(basename "$INPUT_MD")"
  OUTPUT_PDF="$ROOT_DIR/dist/${INPUT_BASENAME%.*}.pdf"
fi

mkdir -p "$(dirname "$OUTPUT_PDF")"

CLASS_FILE="$ROOT_DIR/templates/daggerheart.cls"
ASSETS_DIR="${ASSETS_DIR:-$ROOT_DIR/assets}"
ASSETS_DIR="$(realpath "$ASSETS_DIR")"

if [[ ! -f "$CLASS_FILE" ]]; then
  echo "Could not find local class file: $CLASS_FILE" >&2
  exit 1
fi

if [[ ! -d "$ASSETS_DIR/fonts" ]]; then
  echo "Could not find fonts directory in assets directory: $ASSETS_DIR" >&2
  exit 1
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is required but was not found in PATH." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORKDIR"
  else
    echo "Temporary build directory kept at: $WORKDIR"
  fi
}
trap cleanup EXIT

cp "$CLASS_FILE" "$WORKDIR/daggerheart.cls"
cp -R "$ASSETS_DIR/fonts" "$WORKDIR/"

if [[ -d "$ASSETS_DIR/photos" ]]; then
  cp -R "$ASSETS_DIR/photos" "$WORKDIR/"
  mkdir -p "$WORKDIR/assets"
  cp -R "$ASSETS_DIR/photos" "$WORKDIR/assets/"
fi

if [[ ! -f "$WORKDIR/fonts/LeagueSpartan-Extrabold.ttf" && -f "$WORKDIR/fonts/LeagueSpartan-ExtraBold.ttf" ]]; then
  cp "$WORKDIR/fonts/LeagueSpartan-ExtraBold.ttf" "$WORKDIR/fonts/LeagueSpartan-Extrabold.ttf"
fi

RESOURCE_PATH="$(dirname "$INPUT_MD"):$ASSETS_DIR:$ASSETS_DIR/photos:$ROOT_DIR"

PANDOC_ARGS=(
  --standalone
  --from markdown+fenced_divs+bracketed_spans
  --pdf-engine=xelatex
  --resource-path "$RESOURCE_PATH"
  --template "$ROOT_DIR/templates/daggerheart.latex"
  --lua-filter "$ROOT_DIR/filters/daggerheart.lua"
  -V documentclass=daggerheart
)

# Legge il valore di toc: solo dal blocco frontmatter YAML (tra i --- iniziali)
TOC_FRONTMATTER="$(awk '/^---/{if(p==0){p=1;next}else{exit}} p && /^[[:space:]]*toc:[[:space:]]*/{print $2}' "$INPUT_MD")"
INPUT_FOR_PANDOC="$INPUT_MD"
if [[ "${ENABLE_TOC:-1}" == "1" && "$TOC_FRONTMATTER" != "false" ]]; then
  PANDOC_ARGS+=(--toc)
fi

if [[ "${KEEP_TEX:-0}" == "1" ]]; then
  TEX_PATH="${OUTPUT_PDF%.pdf}.tex"
  (
    cd "$WORKDIR"
    pandoc "$INPUT_MD" "${PANDOC_ARGS[@]}" -t latex -o "$TEX_PATH"
  )
fi

(
  cd "$WORKDIR"
  pandoc "$INPUT_MD" "${PANDOC_ARGS[@]}" -o "$OUTPUT_PDF"
)

echo "PDF generated: $OUTPUT_PDF"
