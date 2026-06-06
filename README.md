# SlidePilot Pro by SkillUp Circle

**Universal Presentation Controller for Android-powered Bluetooth HID control across Windows, macOS, Linux, iPadOS, iOS, Android host devices, Smart TVs, and compatible presentation displays.**

SlidePilot Pro is a free Android presentation controller, wireless mouse, keyboard controller, and smart gesture trackpad developed by **SkillUp Circle**. It allows a compatible Android phone to control presentations, browser slides, PDFs, and mouse movement on devices that accept standard Bluetooth keyboard and mouse input.

SlidePilot Pro supports two connection modes:

| Mode                    | Description                                                             | Computer App Required |
| ----------------------- | ----------------------------------------------------------------------- | --------------------- |
| Bluetooth HID Mode      | Android phone behaves like a Bluetooth keyboard and mouse               | No                    |
| Universal Receiver Mode | Android app controls Windows over local Wi-Fi using SlidePilot Receiver | Yes, Windows Receiver |

---

## Overview

SlidePilot Pro can control presentation and pointer input on Bluetooth HID-compatible host devices, including:

* Windows laptops and desktops
* MacBook, iMac, and macOS desktops
* Linux laptops and desktops
* iPad and iPadOS devices with Bluetooth keyboard/mouse support
* iPhone through supported accessibility pointer input
* Android tablets and selected Android host devices
* Smart TVs and presentation displays with Bluetooth keyboard/mouse support

For Android phones where Bluetooth HID Device Profile is not exposed by the manufacturer, SlidePilot Pro includes **Universal Receiver Mode** for Windows. This allows unsupported Android devices to control Windows computers over local Wi-Fi using the public **SlidePilot Receiver** application included in this repository.

---

## Project Status

Current stage: **Internal Alpha / MVP**

Implemented features:

* Flutter Android app
* Native Android Kotlin Bluetooth HID integration
* Bluetooth keyboard and mouse emulation
* Presentation remote controls
* Wireless trackpad mode
* Multi-touch gesture engine
* HID compatibility diagnostics
* Auto reconnect support
* Unsupported device detection
* SkillUp Circle branding
* Privacy-first offline design
* Windows Receiver Mode for unsupported Android phones
* Public Windows Receiver source code

---

## Repository Structure

```text
SlidePilotPro-SkillupCircle/
├── android/
│   └── Android native Kotlin Bluetooth HID integration
├── assets/
│   └── App icons and SkillUp Circle brand assets
├── lib/
│   └── Flutter Android app source code
├── test/
│   └── Flutter tests
├── SlidePilotReceiver/
│   └── Windows Receiver source code
├── README.md
├── PRIVACY_POLICY.md
├── play_store_assets.md
├── pubspec.yaml
└── analysis_options.yaml
```

---

## App Details

**App Name:** SlidePilot Pro
**Tagline:** Universal Bluetooth Presentation Controller
**Developer:** SkillUp Circle
**Founder / Author:** Tejas Hoskatti
**Organization:** SkillUp Ventures Pvt. Ltd.

SlidePilot Pro turns an Android phone into:

* Bluetooth presentation remote
* Bluetooth keyboard controller
* Wireless mouse
* Wireless trackpad
* Gesture-based presenter controller
* Universal Wi-Fi presenter through Windows Receiver Mode

It is designed for:

* Teachers
* Trainers
* Speakers
* Professors
* Corporate presenters
* Students
* Workshop facilitators
* Event hosts
* Seminar presenters

---

## Connection Modes

## Mode 1: Bluetooth HID Mode

Bluetooth HID Mode allows the Android phone to behave like a standard Bluetooth keyboard and mouse.

No laptop-side software is required.

This mode can control:

* Microsoft PowerPoint
* Google Slides
* Keynote-style presentation shortcuts
* PDF presentations
* Web-based slides
* Browser tabs
* Mouse cursor movement
* Mouse clicks
* Scroll input
* Gesture-mapped shortcuts

### Requirements

* Android phone must support Bluetooth HID Device Profile.
* Bluetooth must be enabled.
* Required Bluetooth permissions must be granted.
* Phone and host device must be paired over Bluetooth.

### Important Compatibility Note

Some Android manufacturers disable Bluetooth HID Device Profile in firmware. In such cases, Bluetooth pairing may work, but keyboard and mouse emulation will not work.

Tested compatible:

* Samsung Galaxy devices
* Google Pixel devices
* Selected OnePlus devices

Device-dependent or potentially unsupported:

* OPPO
* Vivo
* Realme
* Some Xiaomi devices
* Some custom ROM devices

If Bluetooth HID is unsupported, use **Universal Receiver Mode**.

---

## Mode 2: Universal Receiver Mode

Universal Receiver Mode is designed for Android phones where Bluetooth HID Device Profile is not available.

In this mode, the Android app communicates with a Windows computer over the local network.

```text
Android App
    ↓ Wi-Fi / Local Network
SlidePilot Receiver for Windows
    ↓ Windows SendInput API
PowerPoint / Google Slides / Browser / PDF Reader
```

This mode requires running the included **SlidePilot Receiver** app on Windows.

### Advantages

* Works on Android phones without Bluetooth HID support
* Supports Windows laptops and desktops
* Supports presentation controls
* Supports mouse movement
* Supports left click, right click, and scrolling
* Supports gesture commands
* Does not require browser extensions
* Works over local Wi-Fi or mobile hotspot
* Keeps all communication local

---

## Android App Features

## Connect Screen

The Connect screen provides system and compatibility status, including:

* Bluetooth status
* Android HID profile status
* HID app registration status
* Host connection status
* Paired device list
* Diagnostics panel
* Permission request flow
* Auto reconnect
* Unsupported device detection
* Universal Receiver Mode option

---

## Presenter Mode

Presentation controls:

* Next slide
* Previous slide
* Start slideshow
* Exit slideshow
* Black screen
* White screen

Supported gestures:

| Gesture     | Action          |
| ----------- | --------------- |
| Swipe left  | Next slide      |
| Swipe right | Previous slide  |
| Double tap  | Start slideshow |
| Long press  | Exit slideshow  |

---

## Trackpad Mode

Trackpad features:

* One-finger mouse movement
* Tap for left click
* Two-finger tap for right click
* Two-finger scroll
* Long press
* Drag support
* Multi-touch gesture support

---

## Smart Gesture Trackpad

SlidePilot Pro supports MacBook-style gesture concepts by detecting gestures on Android and converting them into Bluetooth HID shortcuts or Universal Receiver Mode commands.

Supported gesture concepts:

* One-finger cursor movement
* Two-finger scroll
* Two-finger tap
* Three-finger swipe
* Four-finger swipe
* Pinch in
* Pinch out
* Gesture-to-shortcut mapping

Important:

SlidePilot Pro does not emulate a true Apple Magic Trackpad. Instead, it detects gestures on Android and converts them into keyboard, mouse, scroll, and shortcut commands.

---

## Windows Receiver

The Windows Receiver source code is included publicly in this repository:

```text
SlidePilotReceiver/
```

The receiver is a portable Windows desktop app built with:

* .NET 8
* C#
* WPF
* WebSocket server
* Windows SendInput API
* System tray support
* QR pairing
* Local PIN authentication

---

## Receiver Features

* Runs as a portable EXE
* No installer required in MVP
* Starts a local WebSocket server on port `45678`
* Shows local IP address
* Generates QR code for Android pairing
* Uses 6-digit pairing PIN
* Accepts commands only after PIN authentication
* Injects keyboard and mouse input into Windows
* Supports system tray minimize and restore
* Includes firewall help option
* Keeps all communication local

---

## Windows Receiver Protocol

## QR Pairing Payload

The receiver displays a QR code containing:

```json
{
  "app": "SlidePilot",
  "mode": "receiver",
  "host": "192.168.1.100",
  "port": 45678,
  "pin": "385901",
  "deviceName": "WINDOWS-LAPTOP"
}
```

## Pairing Message from Android

After opening the WebSocket connection, Android must send a pairing message within the configured timeout period.

```json
{
  "type": "system",
  "action": "pair",
  "pin": "385901",
  "deviceName": "Android Phone"
}
```

Success response:

```json
{
  "ok": true,
  "message": "paired successfully"
}
```

Failure response:

```json
{
  "ok": false,
  "error": "invalid pin"
}
```

---

## Supported Receiver Commands

## Keyboard Key

```json
{
  "type": "keyboard",
  "action": "key",
  "key": "right_arrow"
}
```

Supported keys:

* `right_arrow`
* `left_arrow`
* `page_down`
* `page_up`
* `space`
* `f5`
* `escape`
* `b`
* `w`
* `next_slide`
* `previous_slide`
* `start_presentation`
* `exit_presentation`
* `black_screen`
* `white_screen`

---

## Keyboard Shortcut

```json
{
  "type": "keyboard",
  "action": "shortcut",
  "keys": ["ctrl", "win", "right"]
}
```

Supported modifiers:

* `ctrl`
* `control`
* `alt`
* `shift`
* `win`
* `lwin`

Supported shortcut keys include:

* `tab`
* `space`
* `escape`
* `page_up`
* `page_down`
* `left`
* `right`
* `up`
* `down`
* `f5`
* `plus`
* `minus`
* `0`
* `a`
* `b`
* `c`
* `d`
* `l`
* `r`
* `w`

---

## Mouse Move

```json
{
  "type": "mouse",
  "action": "move",
  "dx": 12,
  "dy": -8
}
```

---

## Mouse Click

```json
{
  "type": "mouse",
  "action": "click",
  "button": "left"
}
```

Supported buttons:

* `left`
* `right`
* `middle`

---

## Mouse Button Down / Up

```json
{
  "type": "mouse",
  "action": "button_down",
  "button": "left"
}
```

```json
{
  "type": "mouse",
  "action": "button_up",
  "button": "left"
}
```

---

## Mouse Scroll

```json
{
  "type": "mouse",
  "action": "scroll",
  "delta": 120
}
```

---

## Gesture Command

```json
{
  "type": "gesture",
  "action": "three_finger_swipe_up",
  "profile": "windows"
}
```

Supported gesture mappings:

| Gesture                    | Windows Action     |
| -------------------------- | ------------------ |
| `three_finger_swipe_up`    | Win + Tab          |
| `three_finger_swipe_down`  | Win + D            |
| `three_finger_swipe_left`  | Alt + Tab          |
| `three_finger_swipe_right` | Alt + Shift + Tab  |
| `four_finger_swipe_left`   | Ctrl + Win + Left  |
| `four_finger_swipe_right`  | Ctrl + Win + Right |
| `pinch_out`                | Ctrl + Plus        |
| `pinch_in`                 | Ctrl + Minus       |
| `two_finger_scroll`        | Mouse scroll       |
| `two_finger_tap`           | Right click        |

---

## Building the Android App

## Requirements

* Flutter SDK
* Android Studio
* Android SDK
* Kotlin support
* Android device for testing

Install dependencies:

```bash
flutter pub get
```

Analyze project:

```bash
flutter analyze
```

Build debug APK:

```bash
flutter build apk --debug
```

Build release APK:

```bash
flutter build apk --release
```

Release APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Building the Windows Receiver

## Requirements

* .NET 8 SDK

Project path:

```text
SlidePilotReceiver/
```

Build:

```bash
dotnet build SlidePilotReceiver/SlidePilotReceiver.csproj
```

Publish portable Windows EXE:

```bash
dotnet publish SlidePilotReceiver/SlidePilotReceiver.csproj -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true /p:IncludeNativeLibrariesForSelfExtract=true
```

Output:

```text
SlidePilotReceiver/bin/Release/net8.0-windows/win-x64/publish/SlidePilotReceiver.exe
```

Recommended GitHub practice:

* Keep the receiver source code public.
* Do not commit generated `bin/` and `obj/` folders.
* Publish compiled EXE files through GitHub Releases.

---

## Recommended .gitignore Additions

```gitignore
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/

# Android
android/.gradle/
android/local.properties

# .NET / Windows Receiver
SlidePilotReceiver/bin/
SlidePilotReceiver/obj/
*.user
*.suo
*.pdb

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
```

---

## Testing Checklist

## Bluetooth HID Mode

* Bluetooth permission granted
* Bluetooth system enabled
* Android HID profile available
* HID app registered
* Laptop or host device paired
* Host connected
* Next slide works
* Previous slide works
* Start presentation works
* Exit presentation works
* Mouse movement works
* Left click works
* Right click works
* Trackpad gestures work
* Auto reconnect works

## Universal Receiver Mode

* Windows Receiver launches
* Firewall permission allowed on private network
* QR code displayed
* Android app scans QR
* PIN pairing succeeds
* Receiver shows connected phone
* Next slide works
* Previous slide works
* F5 starts slideshow
* Escape exits slideshow
* Mouse movement works
* Clicks work
* Scroll works
* Gestures work
* Tray minimize and restore works

---

## Privacy

SlidePilot Pro is designed as a privacy-first utility.

* No login
* No user account
* No analytics
* No tracking
* No cloud backend
* No advertising
* No personal data collection

Bluetooth HID Mode works fully offline.

Universal Receiver Mode works only over the local network between the Android app and Windows Receiver.

See:

```text
PRIVACY_POLICY.md
```

---

## Public Links

SkillUp Circle:

```text
https://skillupcircle.in
```

Developer:

```text
https://htejas.com
```

LinkedIn:

```text
https://www.linkedin.com/in/htejas/
```

Instagram:

```text
https://www.instagram.com/htejas
```

---

## Trademark Notice

SkillUp Circle wordmark and logo are registered trademarks of SkillUp Ventures Pvt. Ltd.

SlidePilot Pro is developed as a free utility under the SkillUp Circle initiative.

---

## License

Add the selected license for this repository.

Recommended options:

| License             | When to Use                                       |
| ------------------- | ------------------------------------------------- |
| MIT License         | Best for simple open-source adoption              |
| Apache 2.0 License  | Good when explicit patent protection is preferred |
| Proprietary License | Use if code is public but reuse is restricted     |

Suggested for open-source adoption:

```text
MIT License
```

---

## Roadmap

Planned improvements:

* Android Universal Receiver Mode integration
* QR pairing from Android app
* Saved receiver profiles
* macOS Receiver
* Linux Receiver
* Improved gesture customization
* Better device compatibility database
* Play Store release
* GitHub Releases for Windows Receiver EXE
* Signed Windows Receiver build
* Installer option for non-technical users

---

## Contribution

Contributions, testing reports, and device compatibility feedback are welcome.

When reporting compatibility, include:

* Android phone model
* Android version
* Manufacturer
* HID Profile status
* Host device OS
* Bluetooth mode or Receiver mode
* What worked
* What failed

---

## Developer

Created by:

**Tejas Hoskatti**
**SkillUp Circle**
**SkillUp Ventures Pvt. Ltd.**

SlidePilot Pro is built to make presentations easier for teachers, trainers, speakers, students, and professionals.
