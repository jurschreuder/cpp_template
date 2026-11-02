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
./run.sh -j 4

# Run only tests with 1 thread:
./run.sh test -j 1

# Pass flags through to ctest:
./run.sh test -j4 -V

# Run only the app binary
./run.sh app

# Start all over with clean cache
./run.sh --clean
# Or in one go
./run.sh --clean -j 8 test
```

# Interactive Development Shell
```sh
docker run --rm -it \
  -v "$(pwd)":/workspace \
  -v cpm_cache:/cache/cpm \
  -v ccache_data:/cache/ccache \
  cpp_template bash
```
Inside the shell:
```sh
# Configure build
cmake -S /workspace -B /build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON

# Compile everything
cmake --build /build

# Run tests
ctest --test-dir /build --output-on-failure

# Run the app
/build/cpp_template
```
