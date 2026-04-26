#include "zico_nes.h"

#include <borealis.hpp>
#include <cstdlib>

namespace {
brls::View *create_main_view() {
  auto *label = new brls::Label();
  label->setText("Zico Vita\nBorealis GXM host\nZig NES core ABI loaded");
  label->setFontSize(32.0f);
  label->setMarginTop(10.0f);
  label->setHorizontalAlign(brls::HorizontalAlign::CENTER);
  label->setVerticalAlign(brls::VerticalAlign::CENTER);
  label->setGrow(1.0f);
  label->setBackgroundColor(nvgRGBA(255, 155, 0, 255));

  auto *frame = new brls::AppletFrame(label);
  frame->setTitle("Zico Vita");
  frame->setFooterVisibility(brls::Visibility::GONE);
  return frame;
}
} // namespace

int main() {
  brls::Logger::setLogLevel(brls::LogLevel::LOG_INFO);
  brls::Platform::APP_LOCALE_DEFAULT = brls::LOCALE_AUTO;

  if (!brls::Application::init()) {
    return EXIT_FAILURE;
  }

  brls::Application::createWindow("Zico Vita");
  brls::Application::getPlatform()->setThemeVariant(brls::ThemeVariant::DARK);
  brls::Application::setGlobalQuit(false);

  ZicoNes *nes = zico_nes_create();
  if (nes == nullptr) {
    return EXIT_FAILURE;
  }

  brls::Application::pushActivity(new brls::Activity(create_main_view()));

  while (brls::Application::mainLoop()) {
    zico_nes_step_frame(nes);
  }

  zico_nes_destroy(nes);
  return EXIT_SUCCESS;
}
