// SPDX-License-Identifier: GPL-2.0-or-later
// Included after the shared fixture in test_miryoku_callum.cpp.
class Miryoku : public MiryokuCallum {};

TEST_P(Miryoku, AllSixThumbsTapAndHoldWithoutCallumLayers) {
    TestDriver driver;
    const uint8_t rows[] = {3, 3, 3, 7, 7, 7};
    const uint8_t cols[] = {3, 4, 5, 5, 4, 3};
    const uint8_t taps[] = {KC_ESC, KC_SPC, KC_TAB, KC_ENT, KC_BSPC, KC_DEL};
    const uint8_t layers[] = {M_MEDIA, M_NAV, M_MOUSE, M_SYM, M_NUM, M_FUN};
    for (uint8_t i = 0; i < 6; ++i) {
        expect_tap(driver, rows[i], cols[i], taps[i]);
        EXPECT_NO_REPORT(driver);
        press(rows[i], cols[i]);
        idle_for(TAPPING_TERM + 1);
        EXPECT_EQ(layer_state, (layer_state_t)1 << layers[i]);
        release(rows[i], cols[i]);
        EXPECT_EQ(layer_state, 0u);
        VERIFY_AND_CLEAR(driver);
    }
}

TEST_P(Miryoku, HomeRowThresholdAndQuickTapZero) {
    TestDriver driver;
    expect_tap(driver, 1, 3, KC_S);
    EXPECT_NO_REPORT(driver);
    press(1, 3); // Immediate repeat press must be able to become Ctrl.
    idle_for(TAPPING_TERM - 10);
    EXPECT_EQ(get_mods(), 0);
    VERIFY_AND_CLEAR(driver);
    EXPECT_REPORT(driver, (KC_LCTL));
    idle_for(20);
    EXPECT_EQ(get_mods(), MOD_BIT(KC_LCTL));
    VERIFY_AND_CLEAR(driver);
    EXPECT_EMPTY_REPORT(driver);
    release(1, 3);
    VERIFY_AND_CLEAR(driver);
}

TEST_P(Miryoku, SameHandRollTypesLettersWithoutModifiers) {
    TestDriver driver;
    std::vector<report_keyboard_t> reports;
    EXPECT_CALL(driver, send_keyboard_mock(_)).WillRepeatedly([&](report_keyboard_t &r) { reports.push_back(r); });
    press(1, 1); // A/GUI
    idle_for(30);
    press(0, 1); // Q on the same hand, inside the tapping term
    release(1, 1);
    release(0, 1);
    bool saw_a = false, saw_q = false;
    for (auto &r : reports) {
        EXPECT_EQ(r.mods, 0);
        for (auto code : r.keys) { saw_a |= code == KC_A; saw_q |= code == KC_Q; }
    }
    EXPECT_TRUE(saw_a);
    EXPECT_TRUE(saw_q);
    EXPECT_EQ(get_mods(), 0);
    VERIFY_AND_CLEAR(driver);
}

TEST_P(Miryoku, OppositeHandNestedChordIsControlUBeforeTimeout) {
    TestDriver driver;
    InSequence sequence;
    EXPECT_REPORT(driver, (KC_LCTL));
    EXPECT_REPORT(driver, (KC_LCTL, KC_U));
    EXPECT_REPORT(driver, (KC_LCTL));
    EXPECT_EMPTY_REPORT(driver);
    press(1, 3); // S/Ctrl
    idle_for(30);
    tap_key(key(4, 3)); // U, complete its tap while S remains held.
    EXPECT_EQ(get_mods(), MOD_BIT(KC_LCTL));
    release(1, 3);
    VERIFY_AND_CLEAR(driver);
}

TEST_P(Miryoku, OppositeHandRollStillTypesLettersWhenModReleasedFirst) {
    TestDriver driver;
    std::vector<report_keyboard_t> reports;
    EXPECT_CALL(driver, send_keyboard_mock(_)).WillRepeatedly([&](report_keyboard_t &r) { reports.push_back(r); });
    press(1, 3); // S/Ctrl
    idle_for(30);
    press(4, 3); // U
    release(1, 3); // Release S first: roll, not nested modifier chord.
    release(4, 3);
    bool saw_s = false, saw_u = false;
    for (auto &r : reports) {
        EXPECT_EQ(r.mods, 0);
        for (auto code : r.keys) { saw_s |= code == KC_S; saw_u |= code == KC_U; }
    }
    EXPECT_TRUE(saw_s);
    EXPECT_TRUE(saw_u);
    VERIFY_AND_CLEAR(driver);
}

TEST_P(Miryoku, ShiftAndLayerFirstReleaseDoNotStick) {
    TestDriver driver;
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_REPORT(driver, (KC_LSFT, KC_A));
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_EMPTY_REPORT(driver);
        press(5, 4); // N/Shift
        idle_for(TAPPING_TERM + 1);
        tap_key(key(1, 1)); // A/GUI must tap A with held Shift.
        release(5, 4);
        VERIFY_AND_CLEAR(driver);
    }
    press(3, 4); // Space/NAV
    idle_for(TAPPING_TERM + 1);
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_LCTL));
        EXPECT_EMPTY_REPORT(driver);
        press(1, 3); // NAV's real Ctrl
        release(3, 4); // Drop layer while Ctrl is held.
        release(1, 3);
        VERIFY_AND_CLEAR(driver);
    }
    EXPECT_EQ(layer_state, 0u);
    EXPECT_EQ(get_mods(), 0);
}

TEST_P(Miryoku, NavigationNumberSymbolAndFunctionPositions) {
    TestDriver driver;
    press(3, 4);
    idle_for(TAPPING_TERM + 1);
    const uint8_t nav[] = {KC_LEFT, KC_DOWN, KC_UP, KC_RGHT};
    for (uint8_t i = 0; i < 4; ++i) expect_tap(driver, 5, 4 - i, nav[i]);
    const uint8_t bottom[] = {KC_INS, KC_HOME, KC_PGDN, KC_PGUP, KC_END};
    for (uint8_t i = 0; i < 5; ++i) expect_tap(driver, 6, 5 - i, bottom[i]);
    expect_tap(driver, 7, 5, KC_ENT);
    expect_tap(driver, 7, 4, KC_BSPC);
    expect_tap(driver, 7, 3, KC_DEL);
    release(3, 4);

    press(7, 4);
    idle_for(TAPPING_TERM + 1);
    const uint8_t nums[] = {KC_7, KC_8, KC_9, KC_4, KC_5, KC_6, KC_1, KC_2, KC_3};
    for (uint8_t i = 0; i < 9; ++i) expect_tap(driver, i / 3, 2 + i % 3, nums[i]);
    expect_tap(driver, 3, 4, KC_0);
    release(7, 4);

    press(7, 5);
    idle_for(TAPPING_TERM + 1);
    {
        InSequence sequence;
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_REPORT(driver, (KC_LSFT, KC_1));
        EXPECT_REPORT(driver, (KC_LSFT));
        EXPECT_EMPTY_REPORT(driver);
        tap_key(key(2, 2)); // !
        VERIFY_AND_CLEAR(driver);
    }
    release(7, 5);

    press(7, 3);
    idle_for(TAPPING_TERM + 1);
    const uint8_t fn[] = {KC_F12, KC_F7, KC_F8, KC_F9, KC_F11, KC_F4, KC_F5, KC_F6, KC_F10, KC_F1, KC_F2, KC_F3};
    for (uint8_t i = 0; i < 12; ++i) expect_tap(driver, i / 4, 1 + i % 4, fn[i]);
    release(7, 3);
    EXPECT_EQ(layer_state, 0u);
}

TEST_P(Miryoku, FastSameHandLayerChordCanHold) {
    TestDriver driver;
    InSequence sequence;
    EXPECT_REPORT(driver, (KC_LCTL));
    EXPECT_EMPTY_REPORT(driver);
    press(3, 4); // Space/NAV
    idle_for(30);
    tap_key(key(1, 3)); // Same-hand NAV Ctrl, complete before the tapping term.
    EXPECT_TRUE(layer_state_is(M_NAV));
    release(3, 4);
    VERIFY_AND_CLEAR(driver);
}

TEST_P(Miryoku, MouseAndMediaSendCorrectReportTypes) {
    TestDriver driver;
    press(3, 5);
    idle_for(TAPPING_TERM + 1);
    bool saw_left = false;
    EXPECT_CALL(driver, send_mouse_mock(_)).WillRepeatedly([&](report_mouse_t &r) { saw_left |= r.x < 0; });
    press(5, 4);
    idle_for(32);
    release(5, 4);
    EXPECT_TRUE(saw_left);
    VERIFY_AND_CLEAR(driver);
    EXPECT_MOUSE_REPORT(driver, (0, 0, 0, 0, 1));
    EXPECT_EMPTY_MOUSE_REPORT(driver);
    tap_key(key(7, 4)); // Mouse left button
    release(3, 5);
    VERIFY_AND_CLEAR(driver);

    press(3, 3);
    idle_for(TAPPING_TERM + 1);
    bool saw_volume = false;
    EXPECT_CALL(driver, send_extra_mock(_)).WillRepeatedly([&](report_extra_t &r) {
        saw_volume |= r.report_id == REPORT_ID_CONSUMER && r.usage == AUDIO_VOL_UP;
    });
    tap_key(key(5, 2));
    release(3, 3);
    EXPECT_TRUE(saw_volume);
    VERIFY_AND_CLEAR(driver);
}

INSTANTIATE_TEST_SUITE_P(LeftUsb, Miryoku, testing::Values(true));
