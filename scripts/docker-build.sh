#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  scripts/docker-build.sh <input.md> [output.pdf]

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

INPUT_ABS="$(realpath "$1")"
if [[ ! -f "$INPUT_ABS" ]]; then
  echo "Input markdown file not found: $INPUT_ABS" >&2
  exit 1
fi

if [[ $# -ge 2 ]]; then
  OUTPUT_ABS="$(realpath -m "$2")"
else
  OUTPUT_ABS="$ROOT_DIR/dist/$(basename "${INPUT_ABS%.*}").pdf"
fi

mkdir -p "$(dirname "$OUTPUT_ABS")"

case "$INPUT_ABS" in
  "$ROOT_DIR"/*) ;;
  *)
    echo "Input markdown must be inside project: $ROOT_DIR" >&2
    exit 1
    ;;
esac

case "$OUTPUT_ABS" in
  "$ROOT_DIR"/*) ;;
  *)
    echo "Output PDF must be inside project: $ROOT_DIR" >&2
    exit 1
    ;;
esac

INPUT_IN_CONTAINER="/workspace/${INPUT_ABS#"$ROOT_DIR"/}"
OUTPUT_IN_CONTAINER="/workspace/${OUTPUT_ABS#"$ROOT_DIR"/}"

IMAGE_NAME="${IMAGE_NAME:-daggerheart-publish:latest}"

docker build -f "$ROOT_DIR/docker/Dockerfile" -t "$IMAGE_NAME" "$ROOT_DIR"

docker run --rm \
  -v "$ROOT_DIR:/workspace" \
  "$IMAGE_NAME" \
  /workspace/scripts/build.sh "$INPUT_IN_CONTAINER" "$OUTPUT_IN_CONTAINER"

echo "PDF generated via Docker: $OUTPUT_ABS"
