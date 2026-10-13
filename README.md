# Gamepad Mouse

A lightweight macOS Menu Bar utility that lets you control your system mouse cursor with a connected gamepad/controller.

## Features

- **Left joystick** controls cursor movement with scaled radial deadzone for drift-free precision
- **Right joystick** provides trackpad-smooth scrolling
- **Button mapping** — A button for left click, B button for right click
- **Menu bar native** — lives quietly in your menu bar, no dock icon
- **Multi-monitor support** with DPI normalization
- **Drag and drop** — hold a button and move for native macOS drag behavior
- **Auto-detection** — connects automatically when a gamepad is detected
- **Sleep/wake handling** — gracefully handles Bluetooth reconnects after wake
- **Simple configuration** via a human-readable TOML file
- **Launch at Login** support

## Installation

Download the latest release from [GitHub Releases](https://github.com/onurkerem/gamepad-mouse/releases), drag to Applications, and launch.

## First Launch

1. Launch **Gamepad Mouse** — a gamepad icon appears in your menu bar
2. Grant **Accessibility permissions** when prompted (required for cursor control)
3. Connect your gamepad via Bluetooth or USB
4. The menu bar icon updates to show active connection
5. Control your Mac!

## Configuration

Edit `~/.config/gamepad-mouse/config.toml`:

```toml
polling_hz = 120
mouse_speed = 15.0
scroll_speed = 5.0
deadzone = 0.10
invert_scroll_y = false

[mapping]
click_left = "button_bottom"
click_right = "button_right"
toggle_app = "button_start"
```

Changes apply instantly — no restart needed.

## Controls

| Input | Action |
|-------|--------|
| Left Joystick | Move cursor |
| Right Joystick | Scroll (vertical + horizontal) |
| A / Cross | Left click |
| B / Circle | Right click |
| Start / Options | Toggle input on/off |

## Building from Source

### Prerequisites

- Xcode 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
cd packages/app
xcodegen generate
open GamepadMouse.xcodeproj
```

Then build and run from Xcode (Cmd+R).

## Website

The marketing website is in `packages/website/`:

```bash
cd packages/website
npm install
npm run dev
```

## License

MIT
