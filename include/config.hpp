#ifndef CONFIG_HPP
#define CONFIG_HPP

namespace GUI {
enum class Theme { System, Light, Dark };

class Config {
public:
  Config();

  ~Config() = default;

  Theme theme() const;

  auto setTheme(const Theme theme) -> void;

private:
  Theme m_theme;
};
} // namespace GUI

#endif
