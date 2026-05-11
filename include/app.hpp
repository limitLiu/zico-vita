#ifndef APP_HPP
#define APP_HPP

#include "config.hpp"
#include "zico_nes.h"

#include <borealis.hpp>

namespace GUI {
class App {
public:
  App();

  ~App();

  auto setup(const std::string &title) -> void;

  auto mainActivity() -> void;

  auto run() -> void;

private:
  ZicoNes *m_nes;
  Config m_config;
};
} // namespace GUI

#endif
