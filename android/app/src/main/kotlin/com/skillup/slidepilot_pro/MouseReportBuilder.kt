package com.skillup.slidepilot_pro

object MouseReportBuilder {
    // Mouse buttons state
    private var buttonsState: Byte = 0

    const val BUTTON_LEFT: Byte = 0x01
    const val BUTTON_RIGHT: Byte = 0x02
    const val BUTTON_MIDDLE: Byte = 0x04
    const val BUTTON_NONE: Byte = 0x00

    /**
     * Builds a 4-byte HID mouse report.
     * Format:
     * Byte 0: Buttons (Bit 0: Left, Bit 1: Right, Bit 2: Middle)
     * Byte 1: X relative move (-127 to 127)
     * Byte 2: Y relative move (-127 to 127)
     * Byte 3: Wheel scroll (-127 to 127)
     */
    fun buildReport(buttons: Byte, x: Byte, y: Byte, scroll: Byte): ByteArray {
        val report = ByteArray(4)
        report[0] = buttons
        report[1] = x
        report[2] = y
        report[3] = scroll
        return report
    }

    /**
     * Sets or clears a button in the current mouse buttons state.
     */
    fun updateButtonState(button: Byte, isPressed: Boolean): Byte {
        buttonsState = if (isPressed) {
            (buttonsState.toInt() or button.toInt()).toByte()
        } else {
            (buttonsState.toInt() and button.toInt().inv()).toByte()
        }
        return buttonsState
    }

    /**
     * Returns the current button state.
     */
    fun getButtonsState(): Byte {
        return buttonsState
    }

    /**
     * Resets the button state.
     */
    fun reset() {
        buttonsState = 0
    }
}
