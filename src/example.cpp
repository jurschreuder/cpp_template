#include "app/example.hpp"

#include <cstddef>
#include <print>

namespace app {

  std::ptrdiff_t test(std::string_view msg){
    std::println("Example: {}", msg);
    return 42;
  }

}
