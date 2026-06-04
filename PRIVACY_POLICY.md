# Privacy Policy for SlidePilot Pro

**Last Updated: June 4, 2026**

SkillUp Circle ("we", "our", or "us") operates the **SlidePilot Pro** mobile application (the "App"). We are committed to protecting and respecting your privacy.

This Privacy Policy explains how SlidePilot Pro handles data. By using the App, you agree to the terms of this policy.

---

## 1. Zero Data Collection Policy

SlidePilot Pro does **NOT** collect, store, transmit, or share any personal data, usage telemetry, logs, or analytics. 
- **No Internet Access**: The App does not require internet connection permissions (`android.permission.INTERNET` is not requested). It operates entirely offline.
- **No Account Creation**: You do not need to register, create an account, or log in to use SlidePilot Pro.
- **No Telemetry / Crash Reporting**: We do not send crash logs, performance logs, or diagnostic reports to any external servers. All live logs remain local in your device's memory buffer and are cleared when the app is closed.

---

## 2. Explanation of Android Permissions

SlidePilot Pro functions as a standard Bluetooth Human Interface Device (HID) keyboard and mouse. To advertise and establish these local connections, Android requires the following permissions:

### A. Bluetooth Connect (`android.permission.BLUETOOTH_CONNECT`)
- **Purpose**: Used to pair with host computers, connect to the HID profile proxy, and send keystroke/mouse input reports.
- **Data Shared**: None. The connection is established directly between your phone and your host computer (Mac, Windows, or Linux) over local Bluetooth radio.

### B. Bluetooth Scan & Advertise (`android.permission.BLUETOOTH_SCAN` & `android.permission.BLUETOOTH_ADVERTISE`)
- **Purpose**: Used to discover available paired hosts and advertise the local SlidePilot Pro keyboard/mouse SDP (Service Discovery Protocol) record so your computer can detect it as a remote controller.
- **Data Shared**: None.

### C. Location Access (Legacy Android Only)
- **Purpose**: On older versions of Android (Android 11 and below), scanning for Bluetooth devices requires coarse or fine location permissions.
- **Data Shared**: None. We do not access, store, or transmit your physical location.

---

## 3. Data Transmission (HID Reports)

When you tap buttons or use the trackpad, the App builds standard USB/Bluetooth HID reports:
- Keyboard reports contain keypress codes (e.g. F5, Right Arrow).
- Mouse reports contain relative X/Y coordinate shifts.
- These packets are transmitted directly over the Bluetooth link to your paired host computer. They are never logged or stored anywhere.

---

## 4. Contact Us

If you have any questions or concerns about this Privacy Policy, please contact us at:
- **Email**: tejas.work@gmail.com
- **Website**: [https://skillupcircle.in](https://skillupcircle.in)
