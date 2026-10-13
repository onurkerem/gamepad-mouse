import SwiftUI
import GameController

@main
struct GamepadMouseApp: App {
    @StateObject private var controllerManager: ControllerManager
    @StateObject private var configManager: ConfigManager
    @StateObject private var permissionManager: PermissionManager
    @StateObject private var powerManager: PowerManager
    @StateObject private var inputProcessor: InputProcessor

    init() {
        GCController.shouldMonitorBackgroundEvents = true

        let config = ConfigManager()
        let perm = PermissionManager()
        let mouse = MouseController()
        let scroll = ScrollController()
        let keyboard = KeyboardController()
        let input = InputProcessor(
            mouseController: mouse,
            scrollController: scroll,
            keyboardController: keyboard,
            configuration: config.configuration
        )

        _configManager = StateObject(wrappedValue: config)
        _permissionManager = StateObject(wrappedValue: perm)
        _inputProcessor = StateObject(wrappedValue: input)

        let ctrl = ControllerManager(
            onControllerConnected: { gamepad in
                input.updateGamepad(gamepad)
                input.startPolling()
            },
            onControllerDisconnected: {
                input.stopPolling()
                input.updateGamepad(nil)
            }
        )
        _controllerManager = StateObject(wrappedValue: ctrl)

        _powerManager = StateObject(wrappedValue: PowerManager(
            onWake: { }
        ))

        ctrl.startMonitoring()
    }

    var body: some Scene {
        MenuBarExtra("Gamepad Mouse", systemImage: menuBarIconName) {
            MenuBarView()
                .environmentObject(controllerManager)
                .environmentObject(configManager)
                .environmentObject(permissionManager)
                .environmentObject(powerManager)
                .environmentObject(inputProcessor)
        }
        .menuBarExtraStyle(.menu)
    }

    private var menuBarIconName: String {
        if !permissionManager.isPermissionGranted {
            return "gamecontroller"
        } else if !controllerManager.isControllerConnected {
            return "gamecontroller"
        } else if !inputProcessor.isEnabled {
            return "pause.circle"
        } else {
            return "gamecontroller.fill"
        }
    }
}
