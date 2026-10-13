import Cocoa
import Combine

final class PermissionManager: ObservableObject {
    @Published var isPermissionGranted: Bool = false

    private var pollTimer: DispatchSourceTimer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        isPermissionGranted = AXIsProcessTrusted()
        if !isPermissionGranted {
            promptAccessibility()
        }
        startPolling()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
    }

    func checkAndRequest() {
        if AXIsProcessTrusted() {
            isPermissionGranted = true
        } else {
            promptAccessibility()
            showPermissionAlert()
        }
    }

    private func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @objc private func accessibilitySettingsChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPermissionGranted = AXIsProcessTrusted()
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Gamepad Mouse requires Accessibility permissions to control the cursor.

        Please enable it in System Settings > Privacy & Security > Accessibility.

        If it is already checked, try removing it with the minus button and adding it again.
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func startPolling() {
        stopPolling()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: Constants.permissionPollInterval)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let trusted = AXIsProcessTrusted()
            DispatchQueue.main.async {
                self.isPermissionGranted = trusted
                if trusted {
                    self.stopPolling()
                }
            }
        }
        timer.resume()
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.cancel()
        pollTimer = nil
    }

    deinit {
        stopPolling()
        NotificationCenter.default.removeObserver(self)
    }
}
