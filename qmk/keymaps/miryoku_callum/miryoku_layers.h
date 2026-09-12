// Copyright 2022 Manna Harbour
// SPDX-License-Identifier: GPL-2.0-or-later
// Adapted from Miryoku Babel's generated QMK layer tables (retrieved 2026-09-14):
// https://github.com/manna-harbour/miryoku_qmk/blob/miryoku/users/manna-harbour_miryoku/miryoku_babel/miryoku_layer_alternatives.h
// Initializer fragment included inside keymaps[]. Native 36-key thumb ordering.
// Omit upstream tap dances/base switches/locks and lighting/output selection.
// Linux clipboard chords; Auto Shift is deliberately disabled (see readme.md).

#define M_REDO LCTL(LSFT(KC_Z))
#define M_PASTE LCTL(KC_V)
#define M_COPY LCTL(KC_C)
#define M_CUT LCTL(KC_X)
#define M_UNDO LCTL(KC_Z)

    [BASE_MIRYOKU] = LAYOUT_split_3x5_3(
        KC_Q, KC_W, KC_F, KC_P, KC_B, KC_J, KC_L, KC_U, KC_Y, KC_QUOT,
        LGUI_T(KC_A), LALT_T(KC_R), LCTL_T(KC_S), LSFT_T(KC_T), KC_G, KC_M, LSFT_T(KC_N), LCTL_T(KC_E), LALT_T(KC_I), LGUI_T(KC_O),
        LT(M_BUTTON, KC_Z), ALGR_T(KC_X), KC_C, KC_D, KC_V, KC_K, KC_H, KC_COMM, ALGR_T(KC_DOT), LT(M_BUTTON, KC_SLSH),
                            LT(M_MEDIA,KC_ESC), LT(M_NAV,KC_SPC), LT(M_MOUSE,KC_TAB), LT(M_SYM,KC_ENT), LT(M_NUM,KC_BSPC), LT(M_FUN,KC_DEL)
    ),
    [M_BUTTON] = LAYOUT_split_3x5_3(
        M_UNDO, M_CUT, M_COPY, M_PASTE, M_REDO, M_REDO, M_PASTE, M_COPY, M_CUT, M_UNDO,
        KC_LGUI, KC_LALT, KC_LCTL, KC_LSFT, KC_NO, KC_NO, KC_LSFT, KC_LCTL, KC_LALT, KC_LGUI,
        M_UNDO, M_CUT, M_COPY, M_PASTE, M_REDO, M_REDO, M_PASTE, M_COPY, M_CUT, M_UNDO,
                            MS_BTN3, MS_BTN1, MS_BTN2, MS_BTN2, MS_BTN1, MS_BTN3
    ),
    [M_NAV] = LAYOUT_split_3x5_3(
        KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, M_REDO, M_PASTE, M_COPY, M_CUT, M_UNDO,
        KC_LGUI, KC_LALT, KC_LCTL, KC_LSFT, KC_NO, CW_TOGG, KC_LEFT, KC_DOWN, KC_UP, KC_RGHT,
        KC_NO, KC_ALGR, KC_NO, KC_NO, KC_NO, KC_INS, KC_HOME, KC_PGDN, KC_PGUP, KC_END,
                            KC_NO, KC_NO, KC_NO, KC_ENT, KC_BSPC, KC_DEL
    ),
    [M_MOUSE] = LAYOUT_split_3x5_3(
        KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, M_REDO, M_PASTE, M_COPY, M_CUT, M_UNDO,
        KC_LGUI, KC_LALT, KC_LCTL, KC_LSFT, KC_NO, KC_NO, MS_LEFT, MS_DOWN, MS_UP, MS_RGHT,
        KC_NO, KC_ALGR, KC_NO, KC_NO, KC_NO, KC_NO, MS_WHLL, MS_WHLD, MS_WHLU, MS_WHLR,
                            KC_NO, KC_NO, KC_NO, MS_BTN2, MS_BTN1, MS_BTN3
    ),
    [M_MEDIA] = LAYOUT_split_3x5_3(
        KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
        KC_LGUI, KC_LALT, KC_LCTL, KC_LSFT, KC_NO, KC_NO, KC_MPRV, KC_VOLD, KC_VOLU, KC_MNXT,
        KC_NO, KC_ALGR, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
                            KC_NO, KC_NO, KC_NO, KC_MSTP, KC_MPLY, KC_MUTE
    ),
    [M_NUM] = LAYOUT_split_3x5_3(
        KC_LBRC, KC_7, KC_8, KC_9, KC_RBRC, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
        KC_SCLN, KC_4, KC_5, KC_6, KC_EQL, KC_NO, KC_LSFT, KC_LCTL, KC_LALT, KC_LGUI,
        KC_GRV, KC_1, KC_2, KC_3, KC_BSLS, KC_NO, KC_NO, KC_NO, KC_ALGR, KC_NO,
                            KC_DOT, KC_0, KC_MINS, KC_NO, KC_NO, KC_NO
    ),
    [M_SYM] = LAYOUT_split_3x5_3(
        KC_LCBR, KC_AMPR, KC_ASTR, KC_LPRN, KC_RCBR, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
        KC_COLN, KC_DLR, KC_PERC, KC_CIRC, KC_PLUS, KC_NO, KC_LSFT, KC_LCTL, KC_LALT, KC_LGUI,
        KC_TILD, KC_EXLM, KC_AT, KC_HASH, KC_PIPE, KC_NO, KC_NO, KC_NO, KC_ALGR, KC_NO,
                            KC_LPRN, KC_RPRN, KC_UNDS, KC_NO, KC_NO, KC_NO
    ),
    [M_FUN] = LAYOUT_split_3x5_3(
        KC_F12, KC_F7, KC_F8, KC_F9, KC_PSCR, KC_NO, KC_NO, KC_NO, KC_NO, KC_NO,
        KC_F11, KC_F4, KC_F5, KC_F6, KC_SCRL, KC_NO, KC_LSFT, KC_LCTL, KC_LALT, KC_LGUI,
        KC_F10, KC_F1, KC_F2, KC_F3, KC_PAUS, KC_NO, KC_NO, KC_NO, KC_ALGR, KC_NO,
                            KC_APP, KC_SPC, KC_TAB, KC_NO, KC_NO, KC_NO
    ),
