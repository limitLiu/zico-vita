#include "app.hpp"

namespace GUI {
App::App() {
  m_nes = zico_nes_create();
  if (!brls::Application::init() || m_nes == nullptr) {
    return;
  }
  brls::Logger::info("App constructor called");
}

App::~App() {
  zico_nes_destroy(m_nes);
  brls::Logger::info("App destructor called");
}

auto App::setup(const std::string &title) -> void {
  brls::Logger::setLogLevel(brls::LogLevel::LOG_INFO);
  brls::Platform::APP_LOCALE_DEFAULT = brls::LOCALE_AUTO;
  brls::Application::createWindow(title);

#if __vita__
  if (m_config.theme() == Theme::System) {
    brls::Application::getPlatform()->setThemeVariant(brls::ThemeVariant::LIGHT);
  }
#else
  switch (m_config.theme()) {
  case Theme::Light:
    brls::Application::getPlatform()->setThemeVariant(brls::ThemeVariant::LIGHT);
  case Theme::Dark:
    brls::Application::getPlatform()->setThemeVariant(brls::ThemeVariant::DARK);
  default:
    break;
  }
#endif
  brls::Application::setGlobalQuit(false);
  mainActivity();
}

auto App::mainActivity() -> void {
  auto *label1 = new brls::Label();
  label1->setText("Zico Vita");
  label1->setFontSize(32.0f);
  label1->setMarginTop(10.0f);

  auto *label2 = new brls::Label();
  label2->setText("Borealis GXM host");

  auto *box = new brls::Box();
  box->addView(label1);
  box->addView(label2);
  box->setAxis(brls::Axis::COLUMN);
  box->setGrow(1.0f);
  box->setBackgroundColor(nvgRGBA(255, 125, 0, 255));
  box->setJustifyContent(brls::JustifyContent::CENTER);
  box->setAlignItems(brls::AlignItems::CENTER);

  auto *frame = new brls::AppletFrame(box);
  frame->setHeaderVisibility(brls::Visibility::GONE);
  frame->setFooterVisibility(brls::Visibility::VISIBLE);
  brls::Application::pushActivity(new brls::Activity(frame));
}

auto App::run() -> void {
  while (brls::Application::mainLoop()) {
    zico_nes_step_frame(m_nes);
  }
}
} // namespace GUI
