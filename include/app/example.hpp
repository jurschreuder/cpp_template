#pragma once

#include <cstddef>
#include <string_view>

/**
 * @file example.hpp
 * @brief Core example declarations for the application.
 */

namespace app {

  /**
   * @brief Processes an incoming message and computes a diagnostic offset.
   *
   * Demonstrates basic string view handling, default arguments, and returns
   * a signed pointer difference type (`std::ptrdiff_t`).
   *
   * @param msg The message string to evaluate. Defaults to `"hey"`.
   * @return std::ptrdiff_t The computed offset or sentinel value (e.g., 42).
   *
   * @note This function is thread-safe and performs no dynamic allocations.
   */
  std::ptrdiff_t test(std::string_view msg = "hey");
}
