#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="/build"
JOBS="${BUILD_JOBS:-2}"
EXTRA_FLAGS="${CMAKE_EXTRA_FLAGS:-}"

MODE="${1:-test}"
shift || true

# Configure if not already configured, or update cache with any changed flags
cmake -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  ${EXTRA_FLAGS}

case "${MODE}" in
  build)
    ninja -C "${BUILD_DIR}" -j "${JOBS}"
    ;;
  test)
    ninja -C "${BUILD_DIR}" -j "${JOBS}" unit_tests
    ctest --test-dir "${BUILD_DIR}" --output-on-failure "$@"
    ;;
  app)
    ninja -C "${BUILD_DIR}" -j "${JOBS}" cpp_template
    "${BUILD_DIR}/cpp_template" "$@"
    ;;
  bash)
    exec bash
    ;;
  *)
    echo "Unknown command: ${MODE}"
    exit 1
    ;;
esac
