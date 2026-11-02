#!/usr/bin/env bash
set -euo pipefail

JOBS="${BUILD_JOBS:-2}"
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j) JOBS="$2"; shift 2 ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done

docker run --rm -it \
  -e BUILD_JOBS="${JOBS}" \
  -v "$(pwd)":/workspace \
  -v cpm_cache:/cache/cpm \
  -v ccache_data:/cache/ccache \
  cpp_template bash scripts/dev.sh ${ARGS[@]+"${ARGS[@]}"}
