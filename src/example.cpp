#include "app/example.hpp"

#include <print>

namespace app {

  void test(std::string_view msg){
    std::println("Example: {}", msg);
  }

}
