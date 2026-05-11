#include "config.hpp"

using namespace GUI;

Config::Config() : m_theme(Theme::System) {}

Theme GUI::Config::theme() const { return m_theme; }

auto Config::setTheme(const Theme theme) -> void { m_theme = theme; }
