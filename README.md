C++ 26 Template
===

Makes a dev container with persistent cache.

Has CPM as a package manager.

Catch2 for testing.

Includes NVIDIA/stdexec for threading.

And nlohmann/json as an example other library.


# Build the docker
```sh
docker build -t cpp_template .
```

# Run things
```sh
Usage: ./run.sh [OPTIONS] [COMMAND]

Commands:
  test              Configure, build, and run Catch2 test suite (default)
  app               Build and run the main application executable
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
```

# Clean build cache, run all static analysers, and run tests (on 8 cores)
```sh
./run.sh -c --all-static test -j 8
```

# Just test
```sh
./run.sh test -j 8
```

# Just run
```sh
./run.sh app -j 8
```
