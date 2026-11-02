#include <catch2/catch_test_macros.hpp>
#include "app/example.hpp"

#include <iostream>
#include <sstream>

TEST_CASE("app::test example", "[ptrdiff]") {

    auto result = app::test("Are you testing me?");
    REQUIRE(result == 42);
}
