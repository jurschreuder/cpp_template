#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat << 'EOF'
Usage: ./run.sh [OPTIONS] [COMMAND]

Commands:
  test              Configure, build, and run Catch2 test suite (default)
  app               Build and run the main application executable
	docs              Build HTML documentation with Doxygen
  build             Build targets only without execution
  bash              Open an interactive shell inside the container

Options:
  -j <N>            Number of parallel build jobs (default: 2 or $BUILD_JOBS)
  -c, --clean       Wipe /build directory inside the container before running

Static Analysis & Sanitizers:
  --tidy            Run clang-tidy during compilation
  --cppcheck        Run cppcheck during compilation
  --analyzer        Enable GCC static analyzer (-fanalyzer)
  --all-static      Enable clang-tidy, cppcheck, and -fanalyzer together
  --asan            Enable AddressSanitizer & UndefinedBehaviorSanitizer
  --tsan            Enable ThreadSanitizer (data-race detection)

General:
  -h, --help        Show this help message and exit

Examples:
  ./run.sh -c test                    # Clean build and run tests
  ./run.sh --tidy -j 4 build          # Build with clang-tidy on 4 cores
  ./run.sh --asan test                # Run tests instrumented with ASan/UBSan
  ./run.sh --all-static -c build      # Clean build running all static analyzers
EOF
}

JOBS="${BUILD_JOBS:-2}"
CLEAN=false

# CMake feature toggles
ENABLE_CLANG_TIDY=OFF
ENABLE_CPPCHECK=OFF
ENABLE_ANALYZER=OFF
ENABLE_SAN_ADDR=OFF
ENABLE_SAN_THREAD=OFF

ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -j)
      JOBS="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN=true
      shift
      ;;
    --tidy)
      ENABLE_CLANG_TIDY=ON
      shift
      ;;
    --cppcheck)
      ENABLE_CPPCHECK=ON
      shift
      ;;
    --analyzer)
      ENABLE_ANALYZER=ON
      shift
      ;;
    --all-static)
      ENABLE_CLANG_TIDY=ON
      ENABLE_CPPCHECK=ON
      ENABLE_ANALYZER=ON
      shift
      ;;
    --asan)
      ENABLE_SAN_ADDR=ON
      shift
      ;;
    --tsan)
      ENABLE_SAN_THREAD=ON
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

# Wipe /build and reset cache permissions if clean build requested
if [[ "${CLEAN}" == true ]]; then
  echo "==> Cleaning /build and fixing /cache permissions..."
  docker run --rm \
    -v "$(pwd)":/workspace \
    -v cpm_cache:/cache/cpm \
    -v ccache_data:/cache/ccache \
    cpp_template bash -c "rm -rf /build && chmod -R a+rwX /cache"
fi

# Run container with injected CMake options
docker run --rm -it \
	-e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  -e BUILD_JOBS="${JOBS}" \
  -e CMAKE_EXTRA_FLAGS="-DENABLE_CLANG_TIDY=${ENABLE_CLANG_TIDY} -DENABLE_CPPCHECK=${ENABLE_CPPCHECK} -DENABLE_ANALYZER=${ENABLE_ANALYZER} -DENABLE_SAN_ADDR=${ENABLE_SAN_ADDR} -DENABLE_SAN_THREAD=${ENABLE_SAN_THREAD}" \
  -v "$(pwd)":/workspace \
  -v cpm_cache:/cache/cpm \
  -v ccache_data:/cache/ccache \
  cpp_template bash scripts/dev.sh ${ARGS[@]+"${ARGS[@]}"}
