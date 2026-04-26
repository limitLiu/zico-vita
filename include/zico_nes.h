#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum ZicoNesButton {
    ZICO_NES_BUTTON_A = 0,
    ZICO_NES_BUTTON_B = 1,
    ZICO_NES_BUTTON_SELECT = 2,
    ZICO_NES_BUTTON_START = 3,
    ZICO_NES_BUTTON_UP = 4,
    ZICO_NES_BUTTON_DOWN = 5,
    ZICO_NES_BUTTON_LEFT = 6,
    ZICO_NES_BUTTON_RIGHT = 7,
};

enum {
    ZICO_NES_SCREEN_WIDTH = 256,
    ZICO_NES_SCREEN_HEIGHT = 240,
};

typedef struct ZicoNes ZicoNes;

ZicoNes* zico_nes_create(void);
void zico_nes_destroy(ZicoNes* nes);

bool zico_nes_load_rom(ZicoNes* nes, const uint8_t* data, size_t len);
void zico_nes_step_frame(ZicoNes* nes);

const uint32_t* zico_nes_framebuffer(const ZicoNes* nes);
void zico_nes_set_button(ZicoNes* nes, uint32_t player, uint32_t button, bool pressed);

#ifdef __cplusplus
}
#endif
