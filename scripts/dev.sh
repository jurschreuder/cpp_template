#!/usr/bin/env bash
set -euo pipefail

# Default to 2 parallel jobs if not set (keeps RAM usage safe)
BUILD_JOBS="${BUILD_JOBS:-2}"
TARGET_ACTION="${1:-all}"

# Configure
cmake -S /workspace -B /build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DBUILD_TESTING=ON

case "${TARGET_ACTION}" in
  test)
    # Build only the test target and run ctest
    cmake --build /build --target unit_tests --parallel "${BUILD_JOBS}"
    exec ctest --test-dir /build --output-on-failure "${@:2}"
    ;;
  build)
    # Build everything without running
    exec cmake --build /build --parallel "${BUILD_JOBS}"
    ;;
  app)
    # Build and run only the binary
    cmake --build /build --target cpp_template --parallel "${BUILD_JOBS}"
    exec /build/cpp_template
    ;;
  all|*)
    # Default: build everything, run tests, run app
    cmake --build /build --parallel "${BUILD_JOBS}"
    ctest --test-dir /build --output-on-failure
    exec /build/cpp_template
    ;;
esac
