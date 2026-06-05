package com.skillup.slidepilot_pro

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class BluetoothHidPlugin: FlutterPlugin, MethodCallHandler, HidManager.StatusListener, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel : MethodChannel
    private var hidManager: HidManager? = null
    private var context: Context? = null
    private var activity: android.app.Activity? = null
    private var permissionResult: Result? = null

    companion object {
        private const val REQUEST_CODE_BLUETOOTH = 101
        private const val tag = "BluetoothHidPlugin"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.skillup.slidepilot_pro/bluetooth_hid")
        channel.setMethodCallHandler(this)
        hidManager = HidManager(flutterPluginBinding.applicationContext, this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val manager = hidManager
        if (manager == null) {
            result.error("UNAVAILABLE", "HID Manager not initialized", null)
            return
        }

        when (call.method) {
            "checkHidSupport" -> {
                result.success(manager.checkHidSupport())
            }
            "openBluetoothSettings" -> {
                try {
                    val intent = android.content.Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS)
                    intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    context?.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to open Bluetooth settings: ${e.message}", null)
                }
            }
            "isBluetoothEnabled" -> {
                result.success(manager.isBluetoothEnabled())
            }
            "getPairedDevices" -> {
                result.success(manager.getPairedDevices())
            }
            "connectDevice" -> {
                val address = call.argument<String>("address")
                if (address == null) {
                    result.error("INVALID_ARGUMENT", "Address cannot be null", null)
                    return
                }
                result.success(manager.connectDevice(address))
            }
            "disconnectDevice" -> {
                result.success(manager.disconnectDevice())
            }
            "sendKeyboardKey" -> {
                val modifierName = call.argument<String>("modifier") ?: ""
                val keyName = call.argument<String>("key")
                if (keyName == null) {
                    result.error("INVALID_ARGUMENT", "Key name cannot be null", null)
                    return
                }
                val modifier = KeyboardReportBuilder.getModifierFromName(modifierName)
                val keyCode = KeyboardReportBuilder.getKeyCodeFromName(keyName)
                result.success(manager.sendKeyboardKey(modifier, keyCode))
            }
            "sendKeyboardShortcut" -> {
                val modifierName = call.argument<String>("modifier") ?: ""
                val keyName = call.argument<String>("key")
                if (keyName == null) {
                    result.error("INVALID_ARGUMENT", "Key name cannot be null", null)
                    return
                }
                val modifier = KeyboardReportBuilder.getModifierFromName(modifierName)
                val keyCode = KeyboardReportBuilder.getKeyCodeFromName(keyName)
                result.success(manager.sendKeyboardKey(modifier, keyCode))
            }
            "sendMouseMove" -> {
                val x = call.argument<Int>("x")?.toByte() ?: 0
                val y = call.argument<Int>("y")?.toByte() ?: 0
                result.success(manager.sendMouseMove(x, y))
            }
            "sendMouseButton" -> {
                val buttonIndex = call.argument<Int>("button") ?: 0 // 0: Left, 1: Right, 2: Middle
                val isPressed = call.argument<Boolean>("isPressed") ?: false
                val button = when (buttonIndex) {
                    0 -> MouseReportBuilder.BUTTON_LEFT
                    1 -> MouseReportBuilder.BUTTON_RIGHT
                    2 -> MouseReportBuilder.BUTTON_MIDDLE
                    else -> MouseReportBuilder.BUTTON_NONE
                }
                result.success(manager.sendMouseButton(button, isPressed))
            }
            "sendMouseScroll" -> {
                val scroll = call.argument<Int>("scroll")?.toByte() ?: 0
                result.success(manager.sendMouseScroll(scroll))
            }
            "checkPermissions" -> {
                result.success(hasPermissions())
            }
            "requestPermissions" -> {
                requestPermissions(result)
            }
            "getSystemInfo" -> {
                result.success(getSystemInfo())
            }
            "registerApp" -> {
                result.success(manager.registerApp())
            }
            "initializeHidProfile" -> {
                manager.initializeHidProfile()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        hidManager?.unregisterApp()
        hidManager = null
        context = null
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        Log.d(tag, "Attached to Activity: ${binding.activity.localClassName}")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    // RequestPermissionsResultListener implementation
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == REQUEST_CODE_BLUETOOTH) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }
            Log.d(tag, "Permission request finished: allGranted=$allGranted")
            permissionResult?.success(allGranted)
            permissionResult = null
            
            if (allGranted) {
                // Permissions granted, re-initialize
                hidManager?.initializeHidProfile()
            }
            return true
        }
        return false
    }

    private fun hasPermissions(): Boolean {
        val ctx = context ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ctx.checkSelfPermission(android.Manifest.permission.BLUETOOTH_SCAN) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            ctx.checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            ctx.checkSelfPermission(android.Manifest.permission.BLUETOOTH_ADVERTISE) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            ctx.checkSelfPermission(android.Manifest.permission.BLUETOOTH) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            ctx.checkSelfPermission(android.Manifest.permission.BLUETOOTH_ADMIN) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
            (ctx.checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED ||
             ctx.checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED)
        }
    }

    private fun requestPermissions(result: Result) {
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity not attached", null)
            return
        }

        if (hasPermissions()) {
            result.success(true)
            return
        }

        permissionResult = result
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                android.Manifest.permission.BLUETOOTH_SCAN,
                android.Manifest.permission.BLUETOOTH_CONNECT,
                android.Manifest.permission.BLUETOOTH_ADVERTISE
            )
        } else {
            arrayOf(
                android.Manifest.permission.BLUETOOTH,
                android.Manifest.permission.BLUETOOTH_ADMIN,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }

        Log.d(tag, "Requesting permissions for Android ${Build.VERSION.SDK_INT}")
        act.requestPermissions(permissions, REQUEST_CODE_BLUETOOTH)
    }

    private fun getSystemInfo(): Map<String, Any> {
        return mapOf(
            "release" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER
        )
    }

    // StatusListener implementation
    override fun onBluetoothStateChanged(enabled: Boolean) {
        mainHandlerPost {
            channel.invokeMethod("onBluetoothStateChanged", enabled)
        }
    }

    override fun onHidSupportStatusChanged(supported: Boolean) {
        mainHandlerPost {
            channel.invokeMethod("onHidSupportStatusChanged", supported)
        }
    }

    override fun onConnectionStateChanged(deviceAddress: String?, state: Int) {
        mainHandlerPost {
            channel.invokeMethod("onConnectionStateChanged", mapOf(
                "address" to deviceAddress,
                "state" to state
            ))
        }
    }

    override fun onAppRegistrationStateChanged(registered: Boolean) {
        mainHandlerPost {
            channel.invokeMethod("onAppRegistrationStateChanged", registered)
        }
    }

    private fun mainHandlerPost(action: () -> Unit) {
        android.os.Handler(android.os.Looper.getMainLooper()).post(action)
    }
}
