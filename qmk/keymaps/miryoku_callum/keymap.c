// SPDX-License-Identifier: GPL-2.0-or-later
// Half-layer design: https://github.com/callum-oakley/keymap
#include QMK_KEYBOARD_H
#include "split_util.h"
#include "tri_layer.h"

enum layers {
    BASE_MIRYOKU,
    BASE_CALLUM,
    NAV,
    LSYM,
    RSYM,
    FN,
    M_BUTTON,
    M_NAV,
    M_MOUSE,
    M_MEDIA,
    M_NUM,
    M_SYM,
    M_FUN,
};

#define LA_LSYM MO(LSYM)
#define LA_NAV  TL_LOWR
#define LA_RSYM TL_UPPR

// Linux application shortcuts. Change these to match your desktop/app bindings.
#define APP_SWAP LALT(KC_TAB)
#define APP_CLOSE LCTL(KC_W)
#define TAB_PREV LCTL(KC_PGUP)
#define TAB_NEXT LCTL(KC_PGDN)
#define APP_LOCK LGUI(KC_L)
#define WIN_SWAP LALT(KC_GRV)
#define REFRESH  LCTL(KC_R)
#define GO_BACK  LALT(KC_LEFT)
#define GO_FWD   LALT(KC_RGHT)

// The native 36-position layout fills omitted outer finger columns with KC_NO.
// Thumb arguments are ordered: left outer/middle/inner, right inner/middle/outer.
// Miryoku uses all six thumbs; Callum explicitly disables its two outer thumbs.
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
#include "miryoku_layers.h"
    // Same DHm tapping geometry as Miryoku, with plain, immediate alphas.
    [BASE_CALLUM] = LAYOUT_split_3x5_3(
        KC_Q,    KC_W,    KC_F,    KC_P,    KC_B,       KC_J,    KC_L,    KC_U,    KC_Y,    KC_QUOT,
        KC_A,    KC_R,    KC_S,    KC_T,    KC_G,       KC_M,    KC_N,    KC_E,    KC_I,    KC_O,
        KC_Z,    KC_X,    KC_C,    KC_D,    KC_V,       KC_K,    KC_H,    KC_COMM, KC_DOT,  KC_SLSH,
                          KC_NO,   LA_LSYM, LA_NAV,     KC_SPC,  LA_RSYM, KC_NO
    ),
    [NAV] = LAYOUT_split_3x5_3(
        APP_SWAP, APP_CLOSE, TAB_PREV, TAB_NEXT, APP_LOCK, _______, KC_BSPC, KC_UP,   KC_DEL,  KC_TAB,
        KC_LCTL, KC_LALT, KC_LGUI, KC_LSFT, KC_ESC,     KC_ESC,  KC_LEFT, KC_DOWN, KC_RGHT, KC_ENT,
        WIN_SWAP, REFRESH, GO_BACK, GO_FWD, KC_NO,      _______, KC_VOLD, KC_VOLU, KC_MPLY, _______,
                          KC_NO,   _______, _______,    _______, _______, KC_NO
    ),
    [LSYM] = LAYOUT_split_3x5_3(
        KC_1,    KC_2,    KC_3,    KC_4,    KC_5,       _______, _______, _______, _______, _______,
        KC_LCTL, KC_LALT, KC_LGUI, KC_LSFT, KC_ESC,     _______, _______, _______, _______, _______,
        KC_CAPS, KC_GRV,  KC_MINS, KC_EQL,  _______,    _______, _______, _______, _______, _______,
                          KC_NO,   _______, _______,    _______, _______, KC_NO
    ),
    [RSYM] = LAYOUT_split_3x5_3(
        _______, _______, _______, _______, _______,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,
        _______, _______, _______, _______, _______,    KC_ESC,  KC_RSFT, KC_RGUI, KC_RALT, KC_RCTL,
        _______, _______, _______, _______, _______,    _______, KC_LBRC, KC_RBRC, KC_SCLN, KC_BSLS,
                          KC_NO,   _______, _______,    _______, _______, KC_NO
    ),
    [FN] = LAYOUT_split_3x5_3(
        KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,      KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,
        KC_LCTL, KC_LALT, KC_LGUI, KC_LSFT, KC_ESC,     KC_ESC,  KC_RSFT, KC_RGUI, KC_RALT, KC_RCTL,
        KC_F11,  KC_F12,  KC_NO,   KC_NO,   KC_NO,      KC_NO,   KC_NO,   KC_NO,   KC_NO,   KC_NO,
                          KC_NO,   _______, _______,    _______, _______, KC_NO
    ),
};

void keyboard_post_init_user(void) {
    set_tri_layer_layers(NAV, RSYM, FN);

    // split_pre_init() has already latched the USB role and GP21 handedness;
    // quantum_init() has already loaded any old EEPROM default-layer state.
    // Only the USB master translates BOTH halves' matrix events into keycodes.
    // Override its default in RAM on every boot, never in EEPROM: moving USB
    // to the other physical half after a power cycle changes the whole layout:
    // LEFT = Miryoku DHm (36 keys), RIGHT = Callum DHm (34 keys).
    if (is_keyboard_master()) {
        default_layer_set((layer_state_t)1 << (is_keyboard_left() ? BASE_MIRYOKU : BASE_CALLUM));
    }
}

// Chordal Hold applies to finger mod-taps. Layer-taps (thumbs and the
// Miryoku Button-layer pinkies) may be held with keys on either hand.
bool get_chordal_hold(uint16_t tap_hold_keycode, keyrecord_t *tap_hold_record, uint16_t other_keycode, keyrecord_t *other_record) {
    if (IS_QK_LAYER_TAP(tap_hold_keycode)) {
        return true;
    }
    return get_chordal_hold_default(tap_hold_record, other_record);
}

// Physical hands, independent of which half is USB master. Thumb keys are
// exempt so a home-row modifier can chord with Space/Enter on either hand.
const char chordal_hold_layout[MATRIX_ROWS][MATRIX_COLS] PROGMEM =
    LAYOUT_split_3x5_3(
        'L', 'L', 'L', 'L', 'L',    'R', 'R', 'R', 'R', 'R',
        'L', 'L', 'L', 'L', 'L',    'R', 'R', 'R', 'R', 'R',
        'L', 'L', 'L', 'L', 'L',    'R', 'R', 'R', 'R', 'R',
                  '*', '*', '*',    '*', '*', '*'
    );
