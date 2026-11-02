#!/usr/bin/env bash
set -euo pipefail

JOBS="${BUILD_JOBS:-2}"
CLEAN=false
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j) JOBS="$2"; shift 2 ;;
		-c|--clean) CLEAN=true; shift ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done

# If --clean is requested, remove the build directory first
if [[ "${CLEAN}" == true ]]; then
  echo "==> Cleaning /build directory..."
  docker run --rm \
    -v "$(pwd)":/workspace \
    -v cpm_cache:/cache/cpm \
    -v ccache_data:/cache/ccache \
    cpp_template rm -rf /build
fi

docker run --rm -it \
  -e BUILD_JOBS="${JOBS}" \
  -v "$(pwd)":/workspace \
  -v cpm_cache:/cache/cpm \
  -v ccache_data:/cache/ccache \
  cpp_template bash scripts/dev.sh ${ARGS[@]+"${ARGS[@]}"}
