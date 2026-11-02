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
	docs)
    ninja -C "${BUILD_DIR}" -j "${JOBS}" docs
    echo "==> Copying documentation to host workspace..."
    rm -rf /workspace/build_docs
    cp -r "${BUILD_DIR}/docs/html" /workspace/build_docs
    
    # Hand ownership back to host user if HOST_UID was supplied
    if [[ -n "${HOST_UID:-}" ]]; then
      chown -R "${HOST_UID}:${HOST_GID:-${HOST_UID}}" /workspace/build_docs
    fi
    echo "==> Documentation ready at ./build_docs/index.html"
    ;;
  bash)
    exec bash
    ;;
  *)
    echo "Unknown command: ${MODE}"
    exit 1
    ;;
esac
