package com.skillup.slidepilot_pro

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.Executors

class HidManager(private val context: Context, private val statusListener: StatusListener) {

    interface StatusListener {
        fun onBluetoothStateChanged(enabled: Boolean)
        fun onHidSupportStatusChanged(supported: Boolean)
        fun onConnectionStateChanged(deviceAddress: String?, state: Int)
        fun onAppRegistrationStateChanged(registered: Boolean)
    }

    private val tag = "HidManager"
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var hidDevice: BluetoothHidDevice? = null
    private var isAppRegistered = false
    private var connectedDevice: BluetoothDevice? = null
    private var currentConnectionState = BluetoothProfile.STATE_DISCONNECTED
    private val mainHandler = Handler(Looper.getMainLooper())

    private val reportExecutor = Executors.newSingleThreadExecutor()

    init {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter
        initializeHidProfile()
    }

    private val profileListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(tag, "HID Profile Proxy connected successfully")
                hidDevice = proxy as BluetoothHidDevice
                registerApp()
                mainHandler.post {
                    statusListener.onHidSupportStatusChanged(true)
                }
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.d(tag, "HID Profile Proxy disconnected")
                hidDevice = null
                isAppRegistered = false
                mainHandler.post {
                    statusListener.onHidSupportStatusChanged(false)
                    statusListener.onAppRegistrationStateChanged(false)
                }
            }
        }
    }

    private val hidDeviceCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            super.onAppStatusChanged(pluggedDevice, registered)
            Log.d(tag, "HID App registration status changed: $registered")
            isAppRegistered = registered
            mainHandler.post {
                statusListener.onAppRegistrationStateChanged(registered)
            }
        }

        @SuppressLint("MissingPermission")
        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            super.onConnectionStateChanged(device, state)
            Log.d(tag, "HID Connection state changed to: $state for device: ${device?.address}")
            currentConnectionState = state
            connectedDevice = if (state == BluetoothProfile.STATE_CONNECTED) device else null

            mainHandler.post {
                statusListener.onConnectionStateChanged(device?.address, state)
            }
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            super.onGetReport(device, type, id, bufferSize)
            Log.d(tag, "onGetReport: type=$type id=$id")
            val emptyReport = if (id.toInt() == 1) {
                KeyboardReportBuilder.buildEmptyReport()
            } else {
                MouseReportBuilder.buildReport(0, 0, 0, 0)
            }
            if (hasConnectPermission()) {
                try {
                    hidDevice?.replyReport(device, type, id, emptyReport)
                } catch (e: SecurityException) {
                    Log.e(tag, "SecurityException in onGetReport: ${e.message}")
                }
            }
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
            super.onSetReport(device, type, id, data)
            Log.d(tag, "onSetReport: type=$type id=$id")
            if (hasConnectPermission()) {
                try {
                    hidDevice?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
                } catch (e: SecurityException) {
                    Log.e(tag, "SecurityException in onSetReport: ${e.message}")
                }
            }
        }
    }

    fun initializeHidProfile() {
        val adapter = bluetoothAdapter
        if (adapter == null) {
            Log.e(tag, "Bluetooth not supported on this device")
            statusListener.onHidSupportStatusChanged(false)
            return
        }

        val enabled = isBluetoothEnabled()
        statusListener.onBluetoothStateChanged(enabled)

        if (!hasConnectPermission()) {
            Log.w(tag, "No BLUETOOTH_CONNECT permission to request HID profile proxy")
            // Do not report unsupported yet, wait for permission grant
            return
        }

        if (hidDevice != null) {
            // Already initialized, notify availability
            statusListener.onHidSupportStatusChanged(true)
            registerApp()
            return
        }

        try {
            Log.d(tag, "Requesting HID Device profile proxy...")
            val success = adapter.getProfileProxy(context, profileListener, BluetoothProfile.HID_DEVICE)
            if (!success) {
                Log.e(tag, "Failed to request HID Device profile proxy")
                statusListener.onHidSupportStatusChanged(false)
            }
        } catch (e: SecurityException) {
            Log.e(tag, "SecurityException requesting profile proxy: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception during getProfileProxy: ${e.message}")
            statusListener.onHidSupportStatusChanged(false)
        }
    }

    fun registerApp(): Boolean {
        val device = hidDevice ?: return false
        if (isAppRegistered) return true

        if (!hasConnectPermission()) {
            Log.e(tag, "Missing BLUETOOTH_CONNECT permission to register app")
            return false
        }

        val sdpSettings = BluetoothHidDeviceAppSdpSettings(
            "SlidePilot Pro",
            "Universal Bluetooth Presentation Controller",
            "SkillUp Circle",
            BluetoothHidDevice.SUBCLASS1_COMBO,
            HID_DESCRIPTOR
        )

        // Null QoS settings fallback to default best effort QoS settings
        return try {
            val success = device.registerApp(
                sdpSettings,
                null,
                null,
                reportExecutor,
                hidDeviceCallback
            )
            if (!success) {
                Log.e(tag, "Failed to register HID application")
            } else {
                Log.d(tag, "HID application registered successfully")
            }
            success
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception registering application: ${e.message}")
            false
        } catch (e: Exception) {
            Log.e(tag, "Exception registering application: ${e.message}")
            false
        }
    }

    fun unregisterApp() {
        val device = hidDevice ?: return
        if (!isAppRegistered) return
        if (!hasConnectPermission()) return

        try {
            device.unregisterApp()
            isAppRegistered = false
        } catch (e: Exception) {
            Log.e(tag, "Exception unregistering application: ${e.message}")
        }
    }

    fun isBluetoothEnabled(): Boolean {
        val adapter = bluetoothAdapter ?: return false
        if (!hasConnectPermission()) {
            Log.w(tag, "No permission to check if Bluetooth is enabled")
            return false
        }
        return try {
            adapter.isEnabled
        } catch (e: SecurityException) {
            Log.e(tag, "SecurityException checking isEnabled: ${e.message}")
            false
        }
    }

    fun checkHidSupport(): Boolean {
        return hidDevice != null
    }

    @SuppressLint("MissingPermission")
    fun getPairedDevices(): List<Map<String, String>> {
        val adapter = bluetoothAdapter ?: return emptyList()
        if (!hasConnectPermission()) return emptyList()

        return try {
            adapter.bondedDevices.map { device ->
                mapOf(
                    "name" to (device.name ?: "Unknown Device"),
                    "address" to device.address
                )
            }
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception getting paired devices: ${e.message}")
            emptyList()
        }
    }

    @SuppressLint("MissingPermission")
    fun connectDevice(address: String): Boolean {
        val device = hidDevice ?: return false
        val adapter = bluetoothAdapter ?: return false
        if (!hasConnectPermission()) return false

        try {
            val remoteDevice = adapter.getRemoteDevice(address)
            Log.d(tag, "Connecting to device: $address")
            return device.connect(remoteDevice)
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception connecting device: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception connecting device: ${e.message}")
        }
        return false
    }

    @SuppressLint("MissingPermission")
    fun disconnectDevice(): Boolean {
        val device = hidDevice ?: return false
        val active = connectedDevice ?: return false
        if (!hasConnectPermission()) return false

        try {
            Log.d(tag, "Disconnecting from device: ${active.address}")
            return device.disconnect(active)
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception disconnecting device: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception disconnecting device: ${e.message}")
        }
        return false
    }

    private fun ByteArray.toHexString(): String {
        return this.joinToString(separator = " ", prefix = "[", postfix = "]") {
            String.format("%02X", it)
        }
    }

    @SuppressLint("MissingPermission")
    fun sendKeyboardKey(modifier: Byte, keyCode: Byte): Map<String, Any> {
        val device = hidDevice ?: return mapOf("success" to false, "error" to "Profile not bound (hidDevice is null)")
        val active = connectedDevice ?: return mapOf("success" to false, "error" to "No connected host")
        if (!hasConnectPermission()) return mapOf("success" to false, "error" to "BLUETOOTH_CONNECT permission denied")

        return try {
            val report = KeyboardReportBuilder.buildReport(modifier, keyCode)
            val success = device.sendReport(active, REPORT_ID_KEYBOARD.toInt(), report)

            // Send release key report after 30ms to simulate full keypress lifecycle
            mainHandler.postDelayed({
                try {
                    val emptyReport = KeyboardReportBuilder.buildEmptyReport()
                    device.sendReport(active, REPORT_ID_KEYBOARD.toInt(), emptyReport)
                } catch (e: Exception) {
                    Log.e(tag, "Failed to send empty key release report: ${e.message}")
                }
            }, 30)

            mapOf(
                "success" to success,
                "reportType" to "keyboard",
                "reportId" to REPORT_ID_KEYBOARD.toInt(),
                "bytes" to report.toHexString(),
                "action" to "Keyboard keypress (modifier=$modifier, code=$keyCode)"
            )
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception sending keyboard key: ${e.message}")
            mapOf("success" to false, "error" to "SecurityException: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception sending keyboard key: ${e.message}")
            mapOf("success" to false, "error" to "Exception: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun sendMouseMove(x: Byte, y: Byte): Map<String, Any> {
        val device = hidDevice ?: return mapOf("success" to false, "error" to "Profile not bound (hidDevice is null)")
        val active = connectedDevice ?: return mapOf("success" to false, "error" to "No connected host")
        if (!hasConnectPermission()) return mapOf("success" to false, "error" to "BLUETOOTH_CONNECT permission denied")

        return try {
            val buttons = MouseReportBuilder.getButtonsState()
            val report = MouseReportBuilder.buildReport(buttons, x, y, 0)
            val success = device.sendReport(active, REPORT_ID_MOUSE.toInt(), report)
            mapOf(
                "success" to success,
                "reportType" to "mouse",
                "reportId" to REPORT_ID_MOUSE.toInt(),
                "bytes" to report.toHexString(),
                "action" to "Mouse Move (dx=$x, dy=$y)"
            )
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception sending mouse move: ${e.message}")
            mapOf("success" to false, "error" to "SecurityException: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception sending mouse move: ${e.message}")
            mapOf("success" to false, "error" to "Exception: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun sendMouseButton(button: Byte, isPressed: Boolean): Map<String, Any> {
        val device = hidDevice ?: return mapOf("success" to false, "error" to "Profile not bound (hidDevice is null)")
        val active = connectedDevice ?: return mapOf("success" to false, "error" to "No connected host")
        if (!hasConnectPermission()) return mapOf("success" to false, "error" to "BLUETOOTH_CONNECT permission denied")

        return try {
            val buttons = MouseReportBuilder.updateButtonState(button, isPressed)
            val report = MouseReportBuilder.buildReport(buttons, 0, 0, 0)
            val success = device.sendReport(active, REPORT_ID_MOUSE.toInt(), report)
            val btnName = when(button) {
                MouseReportBuilder.BUTTON_LEFT -> "Left Button"
                MouseReportBuilder.BUTTON_RIGHT -> "Right Button"
                MouseReportBuilder.BUTTON_MIDDLE -> "Middle Button"
                else -> "Unknown Button"
            }
            mapOf(
                "success" to success,
                "reportType" to "mouse",
                "reportId" to REPORT_ID_MOUSE.toInt(),
                "bytes" to report.toHexString(),
                "action" to "Mouse Click ($btnName, pressed=$isPressed)"
            )
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception sending mouse button: ${e.message}")
            mapOf("success" to false, "error" to "SecurityException: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception sending mouse button: ${e.message}")
            mapOf("success" to false, "error" to "Exception: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun sendMouseScroll(scroll: Byte): Map<String, Any> {
        val device = hidDevice ?: return mapOf("success" to false, "error" to "Profile not bound (hidDevice is null)")
        val active = connectedDevice ?: return mapOf("success" to false, "error" to "No connected host")
        if (!hasConnectPermission()) return mapOf("success" to false, "error" to "BLUETOOTH_CONNECT permission denied")

        return try {
            val buttons = MouseReportBuilder.getButtonsState()
            val report = MouseReportBuilder.buildReport(buttons, 0, 0, scroll)
            val success = device.sendReport(active, REPORT_ID_MOUSE.toInt(), report)
            mapOf(
                "success" to success,
                "reportType" to "mouse",
                "reportId" to REPORT_ID_MOUSE.toInt(),
                "bytes" to report.toHexString(),
                "action" to "Mouse Scroll (scroll=$scroll)"
            )
        } catch (e: SecurityException) {
            Log.e(tag, "Security exception sending mouse scroll: ${e.message}")
            mapOf("success" to false, "error" to "SecurityException: ${e.message}")
        } catch (e: Exception) {
            Log.e(tag, "Exception sending mouse scroll: ${e.message}")
            mapOf("success" to false, "error" to "Exception: ${e.message}")
        }
    }

    private fun hasConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return context.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == android.content.pm.PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    companion object {
        private const val REPORT_ID_KEYBOARD: Byte = 1
        private const val REPORT_ID_MOUSE: Byte = 2

        private val HID_DESCRIPTOR = byteArrayOf(
            // Keyboard
            0x05.toByte(), 0x01.toByte(),          // USAGE_PAGE (Generic Desktop)
            0x09.toByte(), 0x06.toByte(),          // USAGE (Keyboard)
            0xa1.toByte(), 0x01.toByte(),          // COLLECTION (Application)
            0x85.toByte(), 0x01.toByte(),          //   REPORT_ID (1)
            0x05.toByte(), 0x07.toByte(),          //   USAGE_PAGE (Keyboard)
            0x19.toByte(), 0xe0.toByte(),          //   USAGE_MINIMUM (Keyboard LeftControl)
            0x29.toByte(), 0xe7.toByte(),          //   USAGE_MAXIMUM (Keyboard Right GUI)
            0x15.toByte(), 0x00.toByte(),          //   LOGICAL_MINIMUM (0)
            0x25.toByte(), 0x01.toByte(),          //   LOGICAL_MAXIMUM (1)
            0x75.toByte(), 0x01.toByte(),          //   REPORT_SIZE (1)
            0x95.toByte(), 0x08.toByte(),          //   REPORT_COUNT (8)
            0x81.toByte(), 0x02.toByte(),          //   INPUT (Data,Var,Abs) - Modifier byte
            0x95.toByte(), 0x01.toByte(),          //   REPORT_COUNT (1)
            0x75.toByte(), 0x08.toByte(),          //   REPORT_SIZE (8)
            0x81.toByte(), 0x03.toByte(),          //   INPUT (Cnst,Var,Abs) - Reserved byte
            0x95.toByte(), 0x05.toByte(),          //   REPORT_COUNT (5)
            0x75.toByte(), 0x01.toByte(),          //   REPORT_SIZE (1)
            0x05.toByte(), 0x08.toByte(),          //   USAGE_PAGE (LEDs)
            0x19.toByte(), 0x01.toByte(),          //   USAGE_MINIMUM (Num Lock)
            0x29.toByte(), 0x05.toByte(),          //   USAGE_MAXIMUM (Kana)
            0x91.toByte(), 0x02.toByte(),          //   OUTPUT (Data,Var,Abs) - LED report
            0x95.toByte(), 0x01.toByte(),          //   REPORT_COUNT (1)
            0x75.toByte(), 0x03.toByte(),          //   REPORT_SIZE (3)
            0x91.toByte(), 0x03.toByte(),          //   OUTPUT (Cnst,Var,Abs) - LED report padding
            0x95.toByte(), 0x06.toByte(),          //   REPORT_COUNT (6)
            0x75.toByte(), 0x08.toByte(),          //   REPORT_SIZE (8)
            0x15.toByte(), 0x00.toByte(),          //   LOGICAL_MINIMUM (0)
            0x25.toByte(), 0x65.toByte(),          //   LOGICAL_MAXIMUM (101) - 101 keys
            0x05.toByte(), 0x07.toByte(),          //   USAGE_PAGE (Keyboard)
            0x19.toByte(), 0x00.toByte(),          //   USAGE_MINIMUM (Reserved)
            0x29.toByte(), 0x65.toByte(),          //   USAGE_MAXIMUM (Keyboard Application)
            0x81.toByte(), 0x00.toByte(),          //   INPUT (Data,Ary,Abs) - Key bytes (6 keys)
            0xc0.toByte(),                         // END_COLLECTION

            // Mouse
            0x05.toByte(), 0x01.toByte(),          // USAGE_PAGE (Generic Desktop)
            0x09.toByte(), 0x02.toByte(),          // USAGE (Mouse)
            0xa1.toByte(), 0x01.toByte(),          // COLLECTION (Application)
            0x85.toByte(), 0x02.toByte(),          //   REPORT_ID (2)
            0x09.toByte(), 0x01.toByte(),          //   USAGE (Pointer)
            0xa1.toByte(), 0x00.toByte(),          //   COLLECTION (Physical)
            0x05.toByte(), 0x09.toByte(),          //     USAGE_PAGE (Button)
            0x19.toByte(), 0x01.toByte(),          //     USAGE_MINIMUM (Button 1)
            0x29.toByte(), 0x03.toByte(),          //     USAGE_MAXIMUM (Button 3)
            0x15.toByte(), 0x00.toByte(),          //     LOGICAL_MINIMUM (0)
            0x25.toByte(), 0x01.toByte(),          //     LOGICAL_MAXIMUM (1)
            0x75.toByte(), 0x01.toByte(),          //     REPORT_SIZE (1)
            0x95.toByte(), 0x03.toByte(),          //     REPORT_COUNT (3)
            0x81.toByte(), 0x02.toByte(),          //     INPUT (Data,Var,Abs) - 3 buttons
            0x95.toByte(), 0x01.toByte(),          //     REPORT_COUNT (1)
            0x75.toByte(), 0x05.toByte(),          //     REPORT_SIZE (5)
            0x81.toByte(), 0x03.toByte(),          //     INPUT (Cnst,Var,Abs) - padding
            0x05.toByte(), 0x01.toByte(),          //     USAGE_PAGE (Generic Desktop)
            0x09.toByte(), 0x30.toByte(),          //     USAGE (X)
            0x09.toByte(), 0x31.toByte(),          //     USAGE (Y)
            0x15.toByte(), 0x81.toByte(),          //     LOGICAL_MINIMUM (-127)
            0x25.toByte(), 0x7f.toByte(),          //     LOGICAL_MAXIMUM (127)
            0x75.toByte(), 0x08.toByte(),          //     REPORT_SIZE (8)
            0x95.toByte(), 0x02.toByte(),          //     REPORT_COUNT (2)
            0x81.toByte(), 0x06.toByte(),          //     INPUT (Data,Var,Rel) - X, Y position
            0x09.toByte(), 0x38.toByte(),          //     USAGE (Wheel)
            0x15.toByte(), 0x81.toByte(),          //     LOGICAL_MINIMUM (-127)
            0x25.toByte(), 0x7f.toByte(),          //     LOGICAL_MAXIMUM (127)
            0x75.toByte(), 0x08.toByte(),          //     REPORT_SIZE (8)
            0x95.toByte(), 0x01.toByte(),          //     REPORT_COUNT (1)
            0x81.toByte(), 0x06.toByte(),          //     INPUT (Data,Var,Rel) - Wheel scroll
            0xc0.toByte(),                         //   END_COLLECTION
            0xc0.toByte()                          // END_COLLECTION
        )
    }
}
