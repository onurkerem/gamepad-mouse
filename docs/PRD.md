# PRD: Gamepad Mouse for macOS

## 1. Product Summary

Gamepad Mouse is a lightweight macOS Menu Bar utility that allows users to control the system mouse cursor seamlessly with a connected gamepad/controller.

The first version will focus on a highly responsive, background-running application that maps gamepad inputs to mouse actions:
* Left joystick controls cursor movement.
* Right joystick controls smooth scrolling.
* Selected buttons simulate left click, right click, and toggle states.

By living in the macOS Menu Bar, the tool provides a native, zero-friction experience without keeping a terminal window open. It is intended for users who want to control their Mac from a distance, use a controller as an alternative input device, or experiment with gamepad-based desktop control.

## 2. Goals

The first version should provide a working macOS `.app` utility that can:
* Reside quietly in the macOS Menu Bar with visual feedback of controller connection status.
* Handle macOS Accessibility permissions smoothly as a standalone app, seamlessly detecting permission grants without restarts.
* Detect a connected gamepad/controller automatically, handling Mac Sleep/Wake cycles gracefully.
* Move the macOS cursor smoothly natively across multiple monitors using delta-time calculations and DPI/Scaling normalization.
* Support precise low-speed cursor movement and faster movement when the joystick is pushed further using a scaled radial deadzone.
* Properly handle concurrent actions (e.g., flawless native drag-and-drop).
* Provide smooth, trackpad-like scrolling via the right joystick.
* Support Launch at Login.
* Maintain absolute simplicity: no complex visual settings UI for v1; configuration will be handled via a simple human-readable TOML file.
* Pass Apple's Gatekeeper seamlessly via proper Developer ID Code Signing and Notarization.

## 3. Non-Goals for v1

The first version will **not** include:
* A complex visual Settings window/UI.
* Per-application profiles.
* Advanced gesture support.
* Cloud sync.
* Multi-controller support.
* Complex automation or macro features.

The first version should prioritize input quality, background efficiency, native integration, and ease of installation.

## 4. Target Platform

* **Minimum macOS Version:** `macOS 13.0 Ventura`. Both `MenuBarExtra` and `SMAppService` require this minimum. *(Note: Users on macOS 15.4 will experience broken background controller input due to an Apple regression; the app should display a warning banner in the Menu Bar dropdown for detected 15.4 versions, advising upgrade to 15.5+).*
* **Architecture:** Universal Binary for Apple Silicon & Intel.
* **Application type:** macOS Menu Bar App (`.app` bundle)
* **Recommended Frameworks & APIs:**
  * `SwiftUI` (`MenuBarExtra`) for the menu bar interface.
  * `GameController.framework` for reading controller input.
  * `CoreGraphics` / `Quartz CGEvent` APIs for generating mouse movement, clicks, and scroll events.
  * `ServiceManagement` (`SMAppService`) for Launch at Login functionality.
  * *Note on Configuration:* A lightweight Swift Package Manager (SPM) library (e.g., `TOMLDecoder`) will be utilized to parse the TOML config file.

## 5. Primary User Flow

1. The user downloads the compiled `.dmg` or `.zip` via GitHub Releases.
2. The user drags the `Gamepad Mouse.app` into their Applications folder and double-clicks to launch it. **Thanks to Apple Notarization, macOS Gatekeeper verifies the app seamlessly.**
3. A menu bar icon appears (e.g., a gamepad icon).
4. **Onboarding / Permissions:** The app checks for Accessibility permissions. If missing, it displays a native macOS alert with an "Open System Settings" button. 
5. The user grants the app permission. The app automatically detects this in the background and becomes active immediately.
6. The user connects a gamepad via Bluetooth or USB.
7. The menu bar icon changes state to indicate active connection.
8. The user can immediately control the mouse. They can press the `Start` button on the controller to pause/resume the input mapping without quitting the app.

## 6. v1 Functional Requirements

### 6.1 Controller Detection, Power & Background Events
* **Background Event Flag:** `GCController.shouldMonitorBackgroundEvents` MUST be set to `true` immediately at app launch, before any `GCControllerDidConnect` notification is received (setting it after connection on older macOS versions could cause crashes). *Note: As mentioned, macOS 15.4 introduced a regression where this flag stopped working for background apps — this was resolved in macOS 15.5.*
* The tool should detect connected controllers using macOS `GameController.framework` (`GCExtendedGamepad` profile).
* The Menu Bar icon should reflect the state:
  * Dimmed/Gray icon: No controller connected.
  * Solid/Black icon: Controller connected and active.
  * Icon with a pause/slash indicator: App is connected but paused.
* **UI Detail:** The Menu Bar icon MUST be configured as a `Template Image` (`isTemplate = true`) to ensure automatic color switching between macOS Light Mode and Dark Mode.
* **Power & Sleep States:** 
  * If no controller is connected, the app MUST pause the high-frequency polling loop and sleep, relying solely on `GameController` connection listener notifications.
  * The app must handle macOS Sleep/Wake states gracefully. When the Mac wakes up from sleep, or a Bluetooth device reconnects, the app must resume the polling loop safely without freezing or crashing.

### 6.2 Left Joystick Mouse Movement & Dragging
* **Deadzone Implementation (Scaled Radial):** The deadzone MUST be implemented as a scaled radial (circular) deadzone. The raw stick vector's magnitude is computed; if below `deadzone`, the output is zero. If above, the output magnitude is rescaled as `(magnitude - deadzone) / (1 - deadzone)`, with direction preserved. Axial (per-axis) deadzones MUST NOT be used as they cause diagonal snap artifacts during cursor movement.
* **Coordinate Space & Multi-Monitor:** Movement calculations must support multi-monitor setups natively, crossing screen boundaries seamlessly.
* **DPI/Scaling Normalization:** Cursor speed calculations should account for different screen scaling factors so that the perceived speed remains consistent across screens.
* **Drag and Drop (CoreGraphics Failsafe):** When the left click state is down, movement events MUST be dispatched as `CGEventType.leftMouseDragged` rather than `mouseMoved`. This ensures native macOS click-and-drag behavior works flawlessly in all apps.

### 6.3 Right Joystick Scroll
* Right joystick up/down → vertical scroll; left/right → horizontal scroll.
* **Smooth Scrolling:** The implementation should utilize `CGEventField.scrollWheelEventIsContinuous` flag set to `1` (true) to ensure scrolling is smooth like a trackpad.
* **Natural Scrolling:** Must support Y and X axis inversion via the config file.

### 6.4 Button Mapping & Safety Failsafes
* **Primary Clicks (Physical Layout Mapping):** Button mappings MUST rely on physical positions rather than platform-specific labels (A/B vs Cross/Circle) to avoid user confusion:
  * `button_bottom` (e.g., Xbox 'A', PS 'Cross') → left mouse down | released → left mouse up.
  * `button_right` (e.g., Xbox 'B', PS 'Circle') or `button_r1` (Right Bumper) → right mouse down | released → right mouse up.
* **Graceful Exit / Toggle:** 
  * Pressing `Start` toggles the input on/off.
  * **Critical:** Whenever the app is toggled off, or the app is Quit via the menu bar, the app MUST force a `leftMouseUp` and `rightMouseUp` event if any buttons were virtually held down. This prevents the system mouse from getting "stuck".

### 6.5 Menu Bar Interface
Instead of terminal commands, the user interacts via a simple drop-down from the Menu Bar icon:
* `[Status] Controller Connected` (Disabled/Grayed-out text)
* *(Optional)* `[Warning] Config Error - Using Defaults` (Visible only if config parsing fails)
* *(Optional)* `[Warning] macOS 15.4 Bug Detected: Update to 15.5+ for background controller support` (Visible only if running on 15.4)
* `[Toggle] Enable Gamepad Mouse` (Checkmark toggle)
* `---` (Separator)
* `[Action] Edit Configuration...` (Opens the config file)
* `[Action] Reset Configuration to Defaults` (Overwrites broken configs safely)
* `[Toggle] Launch at Login` (Checkmark toggle)
* `---` (Separator)
* `[Action] Quit Gamepad Mouse`

### 6.6 Configuration & Error Handling
* When "Edit Configuration..." is clicked, the app automatically creates (if not exists) and opens `~/.config/gamepad-mouse/config.toml` using the default system text editor.
* **Config File Watching:** The app MUST use `DispatchSource.makeFileSystemObjectSource` to monitor the config file for write events at the kernel level. On change detection, reload should be debounced by ~500ms to avoid partial-write reads. As a fallback, the app should also re-read the config when it receives `NSWorkspace.didActivateApplicationNotification`. The file descriptor must be properly closed and the source cancelled on app quit.
* **Default TOML Schema Example:**
  ```toml
  # Gamepad Mouse Configuration

  polling_hz = 120
  mouse_speed = 15.0
  scroll_speed = 5.0
  
  # deadzone: Scaled radial threshold (0.0–1.0). Values below this magnitude are ignored.
  # 0.10 is recommended for most controllers; increase if you see cursor drift at rest.
  deadzone = 0.10
  
  invert_scroll_y = false

  [mapping]
  # Use physical positions: button_bottom, button_right, button_left, button_top, r1, l1
  click_left = "button_bottom"
  click_right = "button_right"
  toggle_app = "button_start"
  ```
* **Failsafe:** If the config file contains a syntax error, the app MUST NOT crash. It should catch the parsing error, fall back to default values, and display a warning in the Menu Bar. The *"Reset Configuration"* menu option will safely restore the default TOML.

## 7. Technical & Security Requirements
* **Polling Timer Architecture:** The polling loop MUST be implemented using `DispatchSourceTimer` on a dedicated `DispatchQueue` with `.userInteractive` QoS. The timer interval is derived from `polling_hz` in the config (default: 120Hz → ~8.3ms). `CVDisplayLink` and `CADisplayLink` MUST NOT be used; display sync is irrelevant for input polling and introduces unnecessary constraints. The `DispatchSourceTimer` must be correctly balanced with `suspend()`/`resume()` calls to avoid crashes on deallocation.
* **Delta-time Calculation:** Cursor movement must be calculated using delta-time (time elapsed since the last frame) to ensure consistent cursor speed regardless of system refresh rates.
* **Accessibility Inheritance:** Because it is an `.app` bundle, it will request its own Accessibility permissions, avoiding Terminal-inheritance issues.
* **Apple Developer Distribution (Gatekeeper):**
  * The application MUST be signed with a valid **"Developer ID Application"** certificate.
  * The app MUST be compiled with the **Hardened Runtime** enabled.
  * The final `.dmg` or `.zip` MUST be submitted to Apple's Notary Service via `notarytool` and stapled.
  * **CRITICAL:** **App Sandbox MUST be disabled.** Enabling App Sandbox will prevent the app from injecting `CGEvent` mouse movements globally and break Accessibility permissions. Hardened Runtime is sufficient for Notarization.

## 8. Permission Handling
* If Accessibility permission is missing, the app must not silently fail. It should show an alert:
  *"Gamepad Mouse requires Accessibility permissions to control the cursor. Please enable it in Privacy & Security. (Note: If it is already checked, try removing it with the minus button and adding it again.)"*
* Include an "Open System Settings" button that deep-links to `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
* **Permission Detection After Grant:** After displaying the permissions alert, the app MUST NOT require a restart. It should: 
  1. Observe `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` to detect when the user changes Accessibility settings.
  2. On each notification, re-check via `AXIsProcessTrustedWithOptions(prompt: false)`. 
  3. As a fallback, a 1-second `DispatchSourceTimer` polling loop should run while permission is pending, stopping immediately upon successful grant. 
  4. The Menu Bar icon and status text must update in real-time.

## 9. Success Criteria for v1
1. A user can download the `.dmg`, drag it to Applications, and launch it without touching the terminal.
2. The app passes macOS Gatekeeper validations natively without "App is damaged" errors.
3. Accessibility permission changes are detected automatically without requiring app restarts.
4. The Menu Bar icon accurately reflects controller state and supports Dark Mode (`isTemplate`).
5. `DispatchSourceTimer` and Scaled Radial Deadzone provide perfectly smooth, drift-free, multi-monitor DPI-aware cursor movement.
6. Mac sleep/wake cycles and Bluetooth reconnects are handled gracefully.
7. Right stick provides smooth, continuous scrolling.
8. File watching via `makeFileSystemObjectSource` updates TOML changes instantly, safely handling syntax errors without crashing.
9. Battery life is preserved because the polling timer suspends when the controller is disconnected.
10. Users can start/stop the app via the `Start` button or Menu Bar toggle without a stuck cursor.

## 10. Future Features (v2 and beyond)
* **Automated CI/CD Pipeline:** Use GitHub Actions to automatically build, sign, notarize, and package the `.dmg` upon pushing a release tag.
* A fully native SwiftUI Settings Window (replacing the config text file).
* **Drag Lock:** A feature to hold a button to lock the drag state, easing physical strain.
* Per-application profiles (e.g., different sensitivity when a media player is focused).
* Battery status percentage in the Menu Bar drop-down.
* Customizable button combos (e.g., holding a bumper to increase cursor speed dynamically).
* Keyboard shortcut simulation (Mapping buttons to Cmd+C / Cmd+V).
* Haptic/Rumble feedback when toggling states.