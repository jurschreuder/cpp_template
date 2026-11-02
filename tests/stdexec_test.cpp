#include <catch2/catch_test_macros.hpp>
#include <stdexec/execution.hpp>

#include <string>
#include <tuple>

TEST_CASE("P2300: stdexec reference implementation by Nvidia", "[stdexec]") {
    namespace ex = stdexec;

    auto work = ex::just(std::string("stdexec"))
              | ex::then([](std::string s) { return s + " works!"; });

    auto [output] = ex::sync_wait(work).value();
    REQUIRE(output == "stdexec works!");
}
