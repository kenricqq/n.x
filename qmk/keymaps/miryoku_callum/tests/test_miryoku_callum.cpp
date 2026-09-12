// SPDX-License-Identifier: GPL-2.0-or-later
#include "test_common.hpp"
#include "mouse_report_util.hpp"

extern "C" {
#include "keymap_introspection.h"
#include "eeconfig.h"
}

using testing::InSequence;
using testing::_;

// Hardware is mocked; keymap, native layout macro, layers, key processing and
// generated USB keyboard reports are real QMK code.
static bool usb_master = true;
static bool physical_left = true;
extern "C" bool is_keyboard_master(void) { return usb_master; }
extern "C" bool is_keyboard_left(void) { return physical_left; }

enum { MIRYOKU, CALLUM, NAV, LSYM, RSYM, FN, M_BUTTON, M_NAV, M_MOUSE, M_MEDIA, M_NUM, M_SYM, M_FUN, LAYER_COUNT };

class MiryokuCallum : public TestFixture, public testing::WithParamInterface<bool> {
   protected:
    void SetUp() override {
        usb_master = true;
        physical_left = GetParam();
        // Deliberately seed the wrong persisted base; boot must override it.
        eeconfig_update_default_layer(physical_left ? 2 : 1);
        default_layer_set(eeconfig_read_default_layer());
        keyboard_post_init_user();
        for (uint8_t layer = 0; layer < LAYER_COUNT; ++layer)
            for (uint8_t row = 0; row < MATRIX_ROWS; ++row)
                for (uint8_t col = 0; col < MATRIX_COLS; ++col)
                    add_key(KeymapKey{layer, col, row, keycode_at_keymap_location_raw(layer, row, col)});
    }

    KeymapKey key(uint8_t row, uint8_t col) { return KeymapKey{0, col, row, KC_NO}; }
    void press(uint8_t row, uint8_t col) { key(row, col).press(); run_one_scan_loop(); }
    void release(uint8_t row, uint8_t col) { key(row, col).release(); run_one_scan_loop(); }
    void expect_tap(TestDriver &driver, uint8_t row, uint8_t col, uint8_t code) {
        InSequence sequence;
        EXPECT_REPORT(driver, (code));
        EXPECT_EMPTY_REPORT(driver);
        tap_key(key(row, col));
        VERIFY_AND_CLEAR(driver);
    }
};

TEST_P(MiryokuCallum, BootSelectsWholeKeyboardWithoutPersisting) {
    TestDriver driver;
    EXPECT_EQ(default_layer_state, physical_left ? 1u : 2u);
    EXPECT_EQ(eeconfig_read_default_layer(), physical_left ? 2u : 1u);
    const uint8_t colemak[] = {
        KC_Q, KC_W, KC_F, KC_P, KC_B, KC_J, KC_L, KC_U, KC_Y, KC_QUOT,
        KC_A, KC_R, KC_S, KC_T, KC_G, KC_M, KC_N, KC_E, KC_I, KC_O,
        KC_Z, KC_X, KC_C, KC_D, KC_V, KC_K, KC_H, KC_COMM, KC_DOT, KC_SLSH,
    };
    const auto *expected = colemak;
    for (uint8_t row = 0; row < 3; ++row) {
        for (uint8_t col = 0; col < 5; ++col) {
            expect_tap(driver, row, col + 1, expected[row * 10 + col]);
            expect_tap(driver, row + 4, 5 - col, expected[row * 10 + col + 5]);
        }
    }
    if (!physical_left) expect_tap(driver, 7, 5, KC_SPC);
    const auto selected = default_layer_state;
    usb_master = false;
    physical_left = !physical_left;
    keyboard_post_init_user();
    EXPECT_EQ(default_layer_state, selected); // Slave never selects an alpha base.
    usb_master = true;
}

TEST_P(MiryokuCallum, AlphaLatencyIsKeyDownForCallumAndReleaseForMiryoku) {
    TestDriver driver;
    if (physical_left) {
        EXPECT_NO_REPORT(driver);
        press(1, 1); // Miryoku A/GUI waits for the tap decision.
        idle_for(20);
        VERIFY_AND_CLEAR(driver);
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_A));
        EXPECT_EMPTY_REPORT(driver);
        release(1, 1); // Reports now, without waiting for 150ms.
        VERIFY_AND_CLEAR(driver);
    } else {
        EXPECT_REPORT(driver, (KC_A));
        press(1, 1); // Callum reports A on key-down in this scan.
        VERIFY_AND_CLEAR(driver);
        EXPECT_NO_REPORT(driver);
        idle_for(20);
        VERIFY_AND_CLEAR(driver);
        EXPECT_EMPTY_REPORT(driver);
        release(1, 1);
        VERIFY_AND_CLEAR(driver);
    }
}

TEST_P(MiryokuCallum, OppositeHandHeldControlAndShift) {
    physical_left = false;
    keyboard_post_init_user();
    TestDriver driver;
    press(7, 4); // RSYM
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_RCTL));
        EXPECT_REPORT(driver, (KC_RCTL, KC_C));
        EXPECT_REPORT(driver, (KC_RCTL));
        EXPECT_EMPTY_REPORT(driver);
        press(5, 1);
        tap_key(key(2, 3));
        // Release the layer before its modifier: QMK must release the held Ctrl.
        release(7, 4);
        release(5, 1);
        VERIFY_AND_CLEAR(driver);
    }
    press(7, 4);
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_RSFT));
        EXPECT_REPORT(driver, (KC_RSFT, KC_A));
        EXPECT_REPORT(driver, (KC_RSFT));
        EXPECT_EMPTY_REPORT(driver);
        press(5, 4);
        tap_key(key(1, 1));
        release(5, 4);
        release(7, 4);
        VERIFY_AND_CLEAR(driver);
    }
    press(3, 4); // LSYM leaves all right-hand alphas available.
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_LCTL));
        EXPECT_REPORT(driver, (KC_LCTL, KC_J));
        EXPECT_REPORT(driver, (KC_LCTL));
        EXPECT_EMPTY_REPORT(driver);
        press(1, 1);
        tap_key(key(4, 5));
        release(1, 1);
        release(3, 4);
        VERIFY_AND_CLEAR(driver);
    }
    EXPECT_EQ(get_mods(), 0);
}

TEST_P(MiryokuCallum, NumbersAndHalfLayerComposition) {
    physical_left = false;
    keyboard_post_init_user();
    TestDriver driver;
    press(3, 4);
    for (uint8_t i = 0; i < 5; ++i) expect_tap(driver, 0, i + 1, KC_1 + i);
    press(7, 4);
    for (uint8_t i = 0; i < 5; ++i) expect_tap(driver, 4, 5 - i, KC_6 + i);
    EXPECT_TRUE(layer_state_is(LSYM));
    EXPECT_TRUE(layer_state_is(RSYM));
    EXPECT_FALSE(layer_state_is(FN));
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_REPORT(driver, (KC_LSFT, KC_7));
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_EMPTY_REPORT(driver);
        press(1, 4);
        tap_key(key(4, 4));
        release(1, 4);
        VERIFY_AND_CLEAR(driver);
    }
    release(3, 4);
    release(7, 4);
    // Reverse the order: the higher RSYM must remain transparent on the left.
    press(7, 4);
    press(3, 4);
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_RSFT));
        EXPECT_REPORT(driver, (KC_RSFT, KC_1));
        EXPECT_REPORT(driver, (KC_RSFT));
        EXPECT_EMPTY_REPORT(driver);
        press(5, 4);
        tap_key(key(0, 1));
        release(5, 4);
        VERIFY_AND_CLEAR(driver);
    }
    release(7, 4);
    release(3, 4);
    EXPECT_EQ(layer_state, 0u);
}

TEST_P(MiryokuCallum, NavigationAndFunctionLayerAllThumbOrders) {
    physical_left = false;
    keyboard_post_init_user();
    TestDriver driver;
    press(3, 5);
    expect_tap(driver, 4, 4, KC_BSPC);
    expect_tap(driver, 4, 3, KC_UP);
    expect_tap(driver, 4, 2, KC_DEL);
    expect_tap(driver, 4, 1, KC_TAB);
    const uint8_t home[] = {KC_ESC, KC_LEFT, KC_DOWN, KC_RGHT, KC_ENT};
    for (uint8_t i = 0; i < 5; ++i) expect_tap(driver, 5, 5 - i, home[i]);
    release(3, 5);

    for (bool nav_first : {false, true}) {
        for (bool nav_released_first : {false, true}) {
            press(nav_first ? 3 : 7, nav_first ? 5 : 4);
            press(nav_first ? 7 : 3, nav_first ? 4 : 5);
            EXPECT_TRUE(layer_state_is(FN));
            press(3, 4); // LSYM must not hide the higher FN layer.
            for (uint8_t i = 0; i < 5; ++i) {
                expect_tap(driver, 0, i + 1, KC_F1 + i);
                expect_tap(driver, 4, 5 - i, KC_F6 + i);
            }
            expect_tap(driver, 2, 1, KC_F11);
            expect_tap(driver, 2, 2, KC_F12);
            release(3, 4);
            release(nav_released_first ? 3 : 7, nav_released_first ? 5 : 4);
            EXPECT_FALSE(layer_state_is(FN));
            release(nav_released_first ? 7 : 3, nav_released_first ? 4 : 5);
            EXPECT_EQ(layer_state, 0u);
        }
    }
}

TEST_P(MiryokuCallum, DisabledPhysicalPositionsNeverSendReports) {
    TestDriver driver;
    EXPECT_NO_REPORT(driver);
    for (uint8_t layer = 0; layer < LAYER_COUNT; ++layer) {
        layer_state_set((layer_state_t)1 << layer);
        for (uint8_t row : {0, 1, 2, 4, 5, 6}) {
            EXPECT_EQ(keycode_at_keymap_location_raw(layer, row, 0), KC_NO);
            tap_key(key(row, 0));
        }
        for (uint8_t row : {3, 7}) {
            if (layer >= CALLUM && layer <= FN) {
                EXPECT_EQ(keycode_at_keymap_location_raw(layer, row, 3), KC_NO);
                tap_key(key(row, 3));
            }
        }
        // v4 also has optional inner extension positions outside our layout.
        for (uint8_t row = 0; row < 8; ++row)
            EXPECT_EQ(keycode_at_keymap_location_raw(layer, row, 6), KC_NO);
    }
    layer_clear();
    VERIFY_AND_CLEAR(driver);
}

INSTANTIATE_TEST_SUITE_P(UsbHalf, MiryokuCallum, testing::Bool());

#include "test_miryoku.inc"
