import Cocoa
import Combine

final class PowerManager: ObservableObject {
    @Published var isMacOS154Buggy: Bool = Constants.isMacOS154Buggy

    private let onWake: (() -> Void)?
    private let onSleep: (() -> Void)?

    init(onWake: (() -> Void)? = nil, onSleep: (() -> Void)? = nil) {
        self.onWake = onWake
        self.onSleep = onSleep

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemWillSleep() {
        onSleep?()
    }

    @objc private func systemDidWake() {
        onWake?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
