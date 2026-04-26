#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/docker-build.sh <book-dir> [output.pdf]

Environment variables:
  IMAGE_NAME   Docker image tag (default: daggerheart-publish:latest)
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

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but was not found in PATH." >&2
  exit 1
fi

BOOK_DIR_ABS="$(realpath "$1")"
if [[ ! -d "$BOOK_DIR_ABS" ]]; then
  echo "Book directory not found: $BOOK_DIR_ABS" >&2
  exit 1
fi

if [[ ! -f "$BOOK_DIR_ABS/book.md" ]]; then
  echo "Missing book definition file: $BOOK_DIR_ABS/book.md" >&2
  exit 1
fi

if [[ ! -d "$BOOK_DIR_ABS/chapters" ]]; then
  echo "Missing chapters directory: $BOOK_DIR_ABS/chapters" >&2
  exit 1
fi

if [[ $# -ge 2 ]]; then
  OUTPUT_ABS="$(realpath -m "$2")"
else
  OUTPUT_ABS="$ROOT_DIR/dist/$(basename "$BOOK_DIR_ABS").pdf"
fi

mkdir -p "$(dirname "$OUTPUT_ABS")"
OUTPUT_DIR_ABS="$(dirname "$OUTPUT_ABS")"
OUTPUT_FILE="$(basename "$OUTPUT_ABS")"

BOOK_DIR_IN_CONTAINER="/workspace/book"
OUTPUT_IN_CONTAINER="/workspace/out/$OUTPUT_FILE"

IMAGE_NAME="${IMAGE_NAME:-daggerheart-publish:latest}"

docker build -f "$ROOT_DIR/docker/Dockerfile" -t "$IMAGE_NAME" "$ROOT_DIR"

docker run --rm \
  -v "$ROOT_DIR:/workspace/project" \
  -v "$BOOK_DIR_ABS:$BOOK_DIR_IN_CONTAINER:ro" \
  -v "$OUTPUT_DIR_ABS:/workspace/out" \
  "$IMAGE_NAME" \
  /workspace/project/scripts/build.sh "$BOOK_DIR_IN_CONTAINER" "$OUTPUT_IN_CONTAINER"

echo "PDF generated via Docker: $OUTPUT_ABS"
