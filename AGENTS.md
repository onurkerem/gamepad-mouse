# AGENTS.md

## Project: Gamepad Mouse

A lightweight macOS Menu Bar utility that lets users control the system mouse cursor with a connected gamepad/controller.

## Repository Structure

```
gamepad-mouse/
├── docs/
│   └── PRD.md                     # Product Requirements Document
├── packages/
│   ├── app/                        # macOS Swift app
│   │   ├── project.yml             # XcodeGen spec
│   │   └── GamepadMouse/           # Swift source code
│   │       ├── App/                # @main entry point
│   │       ├── Managers/           # Core logic (controller, input, mouse, scroll, config, permission, power)
│   │       ├── Models/             # Data models (AppConfiguration, ButtonMapping)
│   │       ├── Views/              # SwiftUI views (MenuBarView)
│   │       ├── Resources/          # Assets, Info.plist, default config
│   │       └── Util/               # Utilities (deadzone, constants)
│   └── website/                    # Astro marketing website
│       ├── src/
│       │   ├── layouts/
│       │   ├── pages/
│       │   └── styles/
│       └── package.json
├── AGENTS.md                       # This file
├── CLAUDE.md                       # Claude Code instructions
└── README.md                       # Project overview
```

## Toolchain

### macOS App
- **Language:** Swift 5.7+ (targeting macOS 13.0 Ventura)
- **UI:** SwiftUI MenuBarExtra
- **Frameworks:** GameController, CoreGraphics (CGEvent), ServiceManagement
- **Config Parsing:** TOMLDecoder (SPM dependency)
- **Project Generation:** XcodeGen (`project.yml`)
- **Build:** `cd packages/app && xcodegen generate && open GamepadMouse.xcodeproj`

### Website
- **Framework:** Astro 5 + Tailwind CSS 4
- **Commands:** `cd packages/website && npm run dev / build / preview / check`

## Guidelines

- Website changes are part of every feature. Any change to app behavior, config structure, or documented capabilities must be reflected in the website.
- The macOS app MUST NOT enable App Sandbox (CGEvent injection requires it).
- All menu bar icons must be template images (`isTemplate = true`).
- Config file is at `~/.config/gamepad-mouse/config.toml`.

## Build & Run

- **Kill app:** `killall GamepadMouse` (process name has no space)
- **Build:** `xcodebuild -project GamepadMouse.xcodeproj -scheme GamepadMouse -configuration Debug build`
- **Launch:** `open /Users/keremini/Library/Developer/Xcode/DerivedData/GamepadMouse-gtbxiqwliwxkzvetjtksxqgrhyex/Build/Products/Debug/GamepadMouse.app`
- **Reset accessibility:** `tccutil reset Accessibility com.gamepad-mouse.app` — run before relaunch after a rebuild so the system prompts for accessibility permission again.
- After a rebuild, the code signature changes. Always reset accessibility with `tccutil` before launching so the app prompts for permission.
