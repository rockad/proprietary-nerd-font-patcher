#!/usr/bin/env bash
set -euo pipefail

# Proprietary Nerd Font Patcher Runner
# Patches Consolas, SF Mono, Berkeley Mono, and other proprietary fonts with Nerd Fonts glyphs using Docker.
# Supported targets: standard | mono | all (default: all)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="nerdfonts/patcher:latest"
TARGET="${1:-all}"

# Ensure required directories exist
mkdir -p "$SCRIPT_DIR/in" "$SCRIPT_DIR/out/standard" "$SCRIPT_DIR/out/mono"

# Check prerequisites
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker is not installed or not in PATH." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon is not running or current user lacks access." >&2
  exit 1
fi

# Check for input font files
FONT_COUNT=$(find "$SCRIPT_DIR/in" -maxdepth 1 \( -iname '*.ttf' -o -iname '*.otf' \) | wc -l)
if [ "$FONT_COUNT" -eq 0 ]; then
  echo "Error: No .ttf or .otf source fonts found in $SCRIPT_DIR/in" >&2
  echo "Please place .ttf or .otf font files (e.g. Consolas, SF Mono, Berkeley Mono) into $SCRIPT_DIR/in/ before patching." >&2
  exit 1
fi

NPROC=$(nproc 2>/dev/null || echo 2)

patch_variant() {
  local variant_title="$1"
  local out_subdir="$2"
  shift 2
  local patch_flags=("$@")

  local start_time
  start_time=$(date +%s)

  echo "============================================================"
  echo "Starting build: $variant_title"
  echo "Output directory: $SCRIPT_DIR/out/$out_subdir"
  echo "Docker image    : $IMAGE_NAME"
  echo "Parallel jobs   : $NPROC"
  echo "Patch flags     : ${patch_flags[*]}"
  echo "============================================================"

  # Execute docker container to patch fonts
  docker run --rm \
    -e "PN=$NPROC" \
    -v "$SCRIPT_DIR/in":/in:Z \
    -v "$SCRIPT_DIR/out/$out_subdir":/out:Z \
    "$IMAGE_NAME" \
    "${patch_flags[@]}"

  # Ensure user ownership and read/write permissions
  chmod -R u+rw "$SCRIPT_DIR/out/$out_subdir" 2>/dev/null || true

  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - start_time))

  echo "------------------------------------------------------------"
  echo "Finished $variant_title in ${elapsed}s."
  echo "Generated font files in $SCRIPT_DIR/out/$out_subdir/:"
  ls -lh "$SCRIPT_DIR/out/$out_subdir"/*.ttf 2>/dev/null || echo "No .ttf generated"
  echo "============================================================"
}

case "$TARGET" in
  standard)
    patch_variant "Standard (2-cell proportional icons)" "standard" --careful --complete
    ;;
  mono)
    patch_variant "Mono (1-cell strict monospaced icons)" "mono" --careful --complete --mono
    ;;
  all)
    echo "============================================================"
    echo "Starting full build: Standard and Mono variants"
    echo "============================================================"
    TOTAL_START=$(date +%s)
    patch_variant "Standard (2-cell proportional icons)" "standard" --careful --complete
    echo ""
    patch_variant "Mono (1-cell strict monospaced icons)" "mono" --careful --complete --mono
    TOTAL_END=$(date +%s)
    TOTAL_ELAPSED=$((TOTAL_END - TOTAL_START))
    echo "============================================================"
    echo "All variants completed successfully in ${TOTAL_ELAPSED}s."
    echo "============================================================"
    ;;
  *)
    echo "Usage: $0 [standard|mono|all]" >&2
    echo "  standard : Build Consolas Nerd Font (proportional 2-cell icons, recommended for modern terminals)" >&2
    echo "  mono     : Build Consolas Nerd Font Mono (strict single-cell icons for legacy environments)" >&2
    echo "  all      : Build both variants (default)" >&2
    exit 1
    ;;
esac
