#include <catch2/catch_test_macros.hpp>
#include "app/example.hpp"

#include <iostream>
#include <sstream>

TEST_CASE("app::test outputs expected message to stdout", "[example]") {
    std::ostringstream buffer;
    auto* old_buf = std::cout.rdbuf(buffer.rdbuf());

    app::test("world");

    std::cout.rdbuf(old_buf);

    REQUIRE(buffer.str() == "Example: world\n");
}
