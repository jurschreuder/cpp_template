cmake_minimum_required(VERSION 3.30)
project(cpp_template VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
include(CTest)
include(cmake/CPM.cmake)

# NVIDIA/stdexec (C++ execution framework P2300)
# Disables stdexec's own internal tests and examples to speed up configuration
set(STDEXEC_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(STDEXEC_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

CPMAddPackage(
  NAME stdexec
  GITHUB_REPOSITORY NVIDIA/stdexec
  GIT_TAG main # Pin to a commit hash or stable tag if strict reproducibility is needed
)

# JSON parser
CPMAddPackage(
  NAME nlohmann_json
  GITHUB_REPOSITORY nlohmann/json
  GIT_TAG v3.11.3
)

# --- Core Library Target ---
add_library(app_core)

target_sources(app_core
  PRIVATE
    src/example.cpp
)

target_include_directories(app_core
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(app_core PUBLIC cxx_std_26)

target_link_libraries(app_core
  PUBLIC
    STDEXEC::stdexec
    nlohmann_json::nlohmann_json
)

# --- Executable Target ---
add_executable(${PROJECT_NAME} src/main.cpp)

target_link_libraries(${PROJECT_NAME}
  PRIVATE
    app_core
)

# --- Testing Target ---
if(BUILD_TESTING)
  CPMAddPackage(
    NAME Catch2
    GITHUB_REPOSITORY catchorg/Catch2
    GIT_TAG v3.8.1
  )

  add_executable(unit_tests tests/example_test.cpp)

  target_link_libraries(unit_tests
    PRIVATE
      app_core
      Catch2::Catch2WithMain
  )

  list(APPEND CMAKE_MODULE_PATH "${Catch2_SOURCE_DIR}/extras")
  include(Catch)
  catch_discover_tests(unit_tests)
endif()

# --- Documentation ---
find_package(Doxygen QUIET)
if(DOXYGEN_FOUND)
  set(DOXYGEN_EXTRACT_ALL YES)
  set(DOXYGEN_GENERATE_LATEX NO)
  doxygen_add_docs(docs include src COMMENT "Generate documentation")
endif()

