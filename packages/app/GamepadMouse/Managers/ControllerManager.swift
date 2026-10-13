import Cocoa
import Combine
import GameController

final class ControllerManager: ObservableObject {
    @Published var isControllerConnected: Bool = false
    @Published var controllerName: String = ""

    private var currentController: GCController?
    private(set) var currentGamepad: GCExtendedGamepad?
    private var cancellables = Set<AnyCancellable>()

    private let onControllerConnected: ((GCExtendedGamepad) -> Void)?
    private let onControllerDisconnected: (() -> Void)?

    init(
        onControllerConnected: ((GCExtendedGamepad) -> Void)? = nil,
        onControllerDisconnected: (() -> Void)? = nil
    ) {
        self.onControllerConnected = onControllerConnected
        self.onControllerDisconnected = onControllerDisconnected

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }

    func startMonitoring() {
        checkExistingControllers()
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
        handleDisconnect()
    }

    private func checkExistingControllers() {
        let controllers = GCController.controllers()
        if let controller = controllers.first {
            handleConnect(controller)
        }
    }

    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        if currentController == nil {
            handleConnect(controller)
        }
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        if currentController === controller {
            handleDisconnect()
        }
    }

    private func handleConnect(_ controller: GCController) {
        currentController = controller
        controllerName = controller.vendorName ?? "Controller"

        if let gamepad = controller.extendedGamepad {
            currentGamepad = gamepad
            DispatchQueue.main.async { [weak self] in
                self?.isControllerConnected = true
                self?.onControllerConnected?(gamepad)
            }
        }
    }

    private func handleDisconnect() {
        currentController = nil
        currentGamepad = nil

        DispatchQueue.main.async { [weak self] in
            self?.isControllerConnected = false
            self?.controllerName = ""
            self?.onControllerDisconnected?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
