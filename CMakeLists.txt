cmake_minimum_required(VERSION 3.30)
project(cpp_template VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CTest)
include(cmake/CPM.cmake)

# --- Analysis & Sanitizer Options ---
option(ENABLE_WARNINGS   "Enable strict compiler warnings on user code" ON)
option(ENABLE_ANALYZER   "Enable GCC static analyzer (-fanalyzer)" OFF)
option(ENABLE_CLANG_TIDY "Enable clang-tidy on user targets" OFF)
option(ENABLE_CPPCHECK   "Enable cppcheck on user targets" OFF)
option(ENABLE_SAN_ADDR   "Enable Address and UndefinedBehavior sanitizers" OFF)
option(ENABLE_SAN_THREAD "Enable Thread sanitizer" OFF)

# --- Dependency Options ---
set(STDEXEC_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(STDEXEC_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF) # Avoid GCC module scanning ICEs with deep templates

# --- CPM Dependencies (All configured as SYSTEM to silence warnings) ---
CPMAddPackage(
  NAME stdexec
  GITHUB_REPOSITORY NVIDIA/stdexec
  GIT_TAG main
  SYSTEM YES
)

# Strip GCC-only flags injected by stdexec that break clang-tidy
if(TARGET stdexec)
  get_target_property(_stdexec_opts stdexec INTERFACE_COMPILE_OPTIONS)
  if(_stdexec_opts)
    list(FILTER _stdexec_opts EXCLUDE REGEX "fconcepts-diagnostics-depth")
    list(FILTER _stdexec_opts EXCLUDE REGEX "fcoroutines")
    set_target_properties(stdexec PROPERTIES INTERFACE_COMPILE_OPTIONS "${_stdexec_opts}")
  endif()
endif()

CPMAddPackage(
  NAME nlohmann_json
  GITHUB_REPOSITORY nlohmann/json
  GIT_TAG v3.11.3
  SYSTEM YES
)

# --- Configure Static Analysis Commands (User Targets Only) ---
set(PROJECT_CLANG_TIDY "")
if(ENABLE_CLANG_TIDY)
  find_program(CLANG_TIDY_EXE NAMES clang-tidy)
  if(CLANG_TIDY_EXE)
    set(PROJECT_CLANG_TIDY
      ${CLANG_TIDY_EXE};
      -checks=-*,bugprone-*,clang-analyzer-*,cppcoreguidelines-*,performance-*,misc-*;
      --header-filter=^${CMAKE_CURRENT_SOURCE_DIR}/include/.*;
      --extra-arg=-Qunused-arguments;
      --extra-arg=-Wno-unknown-warning-option
    )
  else()
    message(WARNING "ENABLE_CLANG_TIDY is ON, but clang-tidy executable was not found.")
  endif()
endif()

set(PROJECT_CPPCHECK "")
if(ENABLE_CPPCHECK)
  find_program(CPPCHECK_EXE NAMES cppcheck)
  if(CPPCHECK_EXE)
    set(PROJECT_CPPCHECK
      ${CPPCHECK_EXE};
      --enable=warning,style,performance,portability;
      --inline-suppr;
      --suppress=*:*/_deps/*;
      --suppress=*:*/cache/*;
      --suppress=unmatchedSuppression
    )
  else()
    message(WARNING "ENABLE_CPPCHECK is ON, but cppcheck executable was not found.")
  endif()
endif()

# --- Warning Target (Applied solely to project sources) ---
add_library(project_warnings INTERFACE)
if(ENABLE_WARNINGS)
  target_compile_options(project_warnings INTERFACE
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wsign-conversion
    -Wshadow
    -Wnon-virtual-dtor
    -Wold-style-cast
    -Woverloaded-virtual
  )
endif()

# Only enable GCC's -fanalyzer if clang-tidy is NOT active (clang-tidy rejects -fanalyzer)
if(ENABLE_ANALYZER AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT ENABLE_CLANG_TIDY)
  target_compile_options(project_warnings INTERFACE -fanalyzer)
endif()

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
  PRIVATE
    project_warnings
)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  target_link_libraries(app_core PUBLIC stdc++exp)
endif()

# Attach sanitizers to app_core (propagated to consumers)
if(ENABLE_SAN_ADDR)
  target_compile_options(app_core PUBLIC -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(app_core PUBLIC -fsanitize=address,undefined)
endif()

if(ENABLE_SAN_THREAD)
  target_compile_options(app_core PUBLIC -fsanitize=thread -fno-omit-frame-pointer)
  target_link_options(app_core PUBLIC -fsanitize=thread)
endif()

# Attach linter tools strictly to app_core
if(PROJECT_CLANG_TIDY)
  set_target_properties(app_core PROPERTIES CXX_CLANG_TIDY "${PROJECT_CLANG_TIDY}")
endif()
if(PROJECT_CPPCHECK)
  set_target_properties(app_core PROPERTIES CXX_CPPCHECK "${PROJECT_CPPCHECK}")
endif()

# --- Main Executable Target ---
add_executable(${PROJECT_NAME} src/main.cpp)

target_link_libraries(${PROJECT_NAME}
  PRIVATE
    app_core
    project_warnings
)

if(PROJECT_CLANG_TIDY)
  set_target_properties(${PROJECT_NAME} PROPERTIES CXX_CLANG_TIDY "${PROJECT_CLANG_TIDY}")
endif()
if(PROJECT_CPPCHECK)
  set_target_properties(${PROJECT_NAME} PROPERTIES CXX_CPPCHECK "${PROJECT_CPPCHECK}")
endif()

# --- Testing Target ---
if(BUILD_TESTING)
  CPMAddPackage(
    NAME Catch2
    GITHUB_REPOSITORY catchorg/Catch2
    GIT_TAG v3.8.1
    SYSTEM YES
    OPTIONS
      "CATCH_ENABLE_WERROR OFF"
      "CATCH_BUILD_TESTING OFF"
  )

  # Silence warnings inside Catch2 library sources if built from source
  if(TARGET Catch2)
    target_compile_options(Catch2 PRIVATE -w)
  endif()
  if(TARGET Catch2WithMain)
    target_compile_options(Catch2WithMain PRIVATE -w)
  endif()

  add_executable(unit_tests 
    tests/example_test.cpp
    tests/cpp26_test.cpp
    tests/stdexec_test.cpp
  )

  target_link_libraries(unit_tests
    PRIVATE
      app_core
      Catch2::Catch2WithMain
  )

  # Only test files get this specific suppression for Catch2 macros, not app_core
  target_compile_options(unit_tests PRIVATE
    -Wno-conversion
    -Wno-sign-conversion
    -Wno-shadow
    -Wno-float-equal
  )

  list(APPEND CMAKE_MODULE_PATH "${Catch2_SOURCE_DIR}/extras")
  include(Catch)
  catch_discover_tests(unit_tests)
endif()

# --- Documentation ---
find_package(Doxygen QUIET)
if(DOXYGEN_FOUND)
  CPMAddPackage(
    NAME doxygen_awesome_css
    GITHUB_REPOSITORY jothepro/doxygen-awesome-css
    GIT_TAG v2.3.4
    DOWNLOAD_ONLY YES
  )

  # Output target
  set(DOXYGEN_GENERATE_HTML YES)
  set(DOXYGEN_GENERATE_LATEX NO)
  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/docs")

  # Full symbol extraction (vital for free functions & namespaces)
  set(DOXYGEN_EXTRACT_ALL YES)
  set(DOXYGEN_EXTRACT_STATIC YES)
  set(DOXYGEN_EXTRACT_LOCAL_CLASSES YES)
  set(DOXYGEN_EXTRACT_ANON_NSPACES YES)
  set(DOXYGEN_RECURSIVE YES)

  # Ensure C++ header extensions are parsed as C++
  set(DOXYGEN_EXTENSION_MAPPING "h=C++" "hpp=C++" "cpp=C++")
  set(DOXYGEN_FILE_PATTERNS "*.hpp" "*.h" "*.cpp")

  # Navigation & UI settings
  set(DOXYGEN_GENERATE_TREEVIEW YES) # Creates the expandable tree sidebar
  set(DOXYGEN_FULL_PATH_NAMES NO)
  set(DOXYGEN_PROJECT_NAME "Modern C++26 Template")

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
  endif()

  if(doxygen_awesome_css_ADDED)
    set(DOXYGEN_HTML_EXTRA_STYLESHEET 
      "${doxygen_awesome_css_SOURCE_DIR}/doxygen-awesome.css"
      "${doxygen_awesome_css_SOURCE_DIR}/doxygen-awesome-sidebar-only.css"
    )
  endif()

  doxygen_add_docs(docs 
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
    COMMENT "Generate HTML documentation"
  )
endif()
