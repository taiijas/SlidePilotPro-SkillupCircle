package com.skillup.slidepilot_pro

object KeyboardReportBuilder {
    // Modifier masks
    private const val MODIFIER_NONE: Byte = 0
    private const val MODIFIER_LEFT_CTRL: Byte = 0x01
    private const val MODIFIER_LEFT_SHIFT: Byte = 0x02
    private const val MODIFIER_LEFT_ALT: Byte = 0x04
    private const val MODIFIER_LEFT_GUI: Byte = 0x08 // Cmd on Mac, Win on Windows

    // HID Keycodes
    const val KEY_NONE: Byte = 0
    const val KEY_A: Byte = 0x04
    const val KEY_B: Byte = 0x05
    const val KEY_P: Byte = 0x13
    const val KEY_W: Byte = 0x1A
    const val KEY_ENTER: Byte = 0x28
    const val KEY_ESCAPE: Byte = 0x29
    const val KEY_SPACE: Byte = 0x2C
    const val KEY_F5: Byte = 0x3E
    const val KEY_RIGHT_ARROW: Byte = 0x4F
    const val KEY_LEFT_ARROW: Byte = 0x50
    const val KEY_DOWN_ARROW: Byte = 0x51
    const val KEY_UP_ARROW: Byte = 0x52
    const val KEY_PAGE_UP: Byte = 0x4B
    const val KEY_PAGE_DOWN: Byte = 0x4E

    /**
     * Builds an 8-byte HID keyboard report.
     * Format:
     * Byte 0: Modifier keys status
     * Byte 1: Reserved (0)
     * Byte 2-7: Keycodes (up to 6 keys)
     */
    fun buildReport(modifier: Byte, keyCode: Byte): ByteArray {
        val report = ByteArray(8)
        report[0] = modifier
        report[1] = 0x00
        report[2] = keyCode
        // 3-7 are 0x00
        return report
    }

    /**
     * Builds an empty report indicating all keys are released.
     */
    fun buildEmptyReport(): ByteArray {
        return ByteArray(8)
    }

    /**
     * Maps key names from Flutter to HID codes.
     */
    fun getKeyCodeFromName(keyName: String): Byte {
        return when (keyName.lowercase()) {
            "right_arrow" -> KEY_RIGHT_ARROW
            "left_arrow" -> KEY_LEFT_ARROW
            "up_arrow" -> KEY_UP_ARROW
            "down_arrow" -> KEY_DOWN_ARROW
            "f5" -> KEY_F5
            "escape" -> KEY_ESCAPE
            "space" -> KEY_SPACE
            "page_up" -> KEY_PAGE_UP
            "page_down" -> KEY_PAGE_DOWN
            "b" -> KEY_B
            "w" -> KEY_W
            "p" -> KEY_P
            "enter" -> KEY_ENTER
            "return" -> KEY_ENTER
            else -> KEY_NONE
        }
    }

    /**
     * Maps modifier names from Flutter to modifier byte masks.
     */
    fun getModifierFromName(modifierName: String): Byte {
        var mask: Byte = MODIFIER_NONE
        if (modifierName.contains("ctrl")) mask = (mask.toInt() or MODIFIER_LEFT_CTRL.toInt()).toByte()
        if (modifierName.contains("shift")) mask = (mask.toInt() or MODIFIER_LEFT_SHIFT.toInt()).toByte()
        if (modifierName.contains("alt")) mask = (mask.toInt() or MODIFIER_LEFT_ALT.toInt()).toByte()
        if (modifierName.contains("gui") || modifierName.contains("cmd") || modifierName.contains("meta")) {
            mask = (mask.toInt() or MODIFIER_LEFT_GUI.toInt()).toByte()
        }
        return mask
    }
}
