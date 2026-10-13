import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @EnvironmentObject var controllerManager: ControllerManager
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var permissionManager: PermissionManager
    @EnvironmentObject var powerManager: PowerManager
    @EnvironmentObject var inputProcessor: InputProcessor

    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        if permissionManager.isPermissionGranted {
            if controllerManager.isControllerConnected {
                Text("Controller Connected: \(controllerManager.controllerName)")
                    .disabled(true)
            } else {
                Text("No Controller Connected")
                    .disabled(true)
            }
        } else {
            Button("Accessibility Permission Required...") {
                permissionManager.checkAndRequest()
            }
        }

        if configManager.hasConfigError {
            Text("⚠ Config Error - Using Defaults")
                .disabled(true)
        }

        if powerManager.isMacOS154Buggy {
            Text("⚠ macOS 15.4 Bug: Update to 15.5+")
                .disabled(true)
        }

        Toggle("Enable Gamepad Mouse", isOn: $inputProcessor.isEnabled)

        Divider()

        Button("Edit Configuration...") {
            configManager.editConfiguration()
        }

        Button("Reset Configuration to Defaults") {
            configManager.resetConfiguration()
        }

        Toggle("Launch at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { newValue in
                let service = SMAppService.mainApp
                do {
                    if newValue {
                        try service.register()
                    } else {
                        try service.unregister()
                    }
                } catch {
                    launchAtLogin.toggle()
                }
            }

        Divider()

        Button("Quit Gamepad Mouse") {
            NSApplication.shared.terminate(nil)
        }
    }
}
