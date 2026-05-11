#include "app.hpp"

#include <borealis.hpp>
#include <cstdlib>

auto main() -> int {
  GUI::App app;
  app.setup("Zico Vita");
  app.run();
  return EXIT_SUCCESS;
}
