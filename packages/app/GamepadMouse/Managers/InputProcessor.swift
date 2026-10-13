import Cocoa
import Combine
import GameController

final class InputProcessor: ObservableObject {
    @Published var isEnabled: Bool = true

    private var pollingTimer: DispatchSourceTimer?
    private let pollingQueue = DispatchQueue(label: "com.gamepad-mouse.polling", qos: .userInteractive)
    private var isTimerSuspended = true

    private var lastTickTime: DispatchTime = .now()
    private var previousButtonStates: [String: Bool] = [:]
    private var isLeftButtonDown = false
    private var isRightButtonDown = false

    private let mouseController: MouseController
    private let scrollController: ScrollController
    private let keyboardController: KeyboardController
    private var configuration: AppConfiguration
    private var gamepad: GCExtendedGamepad?
    private var hasAccessibilityPermission: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(
        mouseController: MouseController,
        scrollController: ScrollController,
        keyboardController: KeyboardController,
        configuration: AppConfiguration
    ) {
        self.mouseController = mouseController
        self.scrollController = scrollController
        self.keyboardController = keyboardController
        self.configuration = configuration
    }

    func updateConfiguration(_ config: AppConfiguration) {
        configuration = config
        if !isTimerSuspended {
            recreateTimer()
        }
    }

    func updateGamepad(_ gamepad: GCExtendedGamepad?) {
        self.gamepad = gamepad
    }

    func startPolling() {
        guard gamepad != nil else { return }
        guard isTimerSuspended else { return }

        lastTickTime = .now()
        previousButtonStates.removeAll()

        let timer = createTimer()
        timer.resume()
        pollingTimer = timer
        isTimerSuspended = false
    }

    func stopPolling() {
        guard !isTimerSuspended else { return }
        pollingTimer?.cancel()
        pollingTimer = nil
        isTimerSuspended = true

        mouseController.forceReleaseAll()
    }

    func forceReleaseAll() {
        mouseController.forceReleaseAll()
        isLeftButtonDown = false
        isRightButtonDown = false
        previousButtonStates.removeAll()
    }

    // MARK: - Private

    private func createTimer() -> DispatchSourceTimer {
        let interval = 1.0 / TimeInterval(max(1, configuration.pollingHz))
        let timer = DispatchSource.makeTimerSource(queue: pollingQueue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in self?.processFrame() }
        return timer
    }

    private func recreateTimer() {
        let wasRunning = !isTimerSuspended
        if wasRunning {
            pollingTimer?.cancel()
            pollingTimer = nil
            isTimerSuspended = true
        }
        if wasRunning {
            startPolling()
        }
    }

    private func processFrame() {
        guard isEnabled, let gamepad else { return }

        if !hasAccessibilityPermission {
            hasAccessibilityPermission = AXIsProcessTrusted()
            if !hasAccessibilityPermission { return }
        }

        let now = DispatchTime.now()
        let rawDelta = Double(now.uptimeNanoseconds - lastTickTime.uptimeNanoseconds) / 1_000_000_000.0
        lastTickTime = now
        let deltaTime = min(rawDelta, Constants.maxDeltaTime)

        let leftStick = ScaledRadialDeadzone.apply(
            x: gamepad.leftThumbstick.xAxis.value,
            y: gamepad.leftThumbstick.yAxis.value,
            deadzone: Float(configuration.deadzone)
        )

        let rightStick = ScaledRadialDeadzone.apply(
            x: gamepad.rightThumbstick.xAxis.value,
            y: gamepad.rightThumbstick.yAxis.value,
            deadzone: Float(configuration.deadzone)
        )

        // Trigger amplification (L2 = cursor boost, R2 = scroll boost)
        let l2Amplify = 1.0 + Double(gamepad.leftTrigger.value) * 1.0
        let r2Amplify = 1.0 + Double(gamepad.rightTrigger.value) * 4.0

        // Cursor movement
        let hasMovement = abs(leftStick.x) > 0.001 || abs(leftStick.y) > 0.001
        if hasMovement {
            let dx = Double(leftStick.x) * configuration.mouseSpeed * deltaTime * 100 * l2Amplify
            let dy = Double(leftStick.y) * configuration.mouseSpeed * deltaTime * 100 * l2Amplify
            mouseController.moveCursor(dx: dx, dy: dy, isLeftButtonDown: isLeftButtonDown, isRightButtonDown: isRightButtonDown)
        }

        // Scroll
        let hasScroll = abs(rightStick.x) > 0.001 || abs(rightStick.y) > 0.001
        if hasScroll {
            let scrollDX = Double(rightStick.x) * configuration.scrollSpeed * deltaTime * 80 * r2Amplify
            let scrollDY = Double(rightStick.y) * configuration.scrollSpeed * deltaTime * 80 * r2Amplify
            scrollController.scroll(dx: scrollDX, dy: scrollDY, invertY: configuration.invertScrollY)
        }

        // Button handling
        let dpad = gamepad.dpad
        NSLog("[DpadDebug] up=%.2f down=%.2f left=%.2f right=%.2f", dpad.up.value, dpad.down.value, dpad.left.value, dpad.right.value)
        processButtons(gamepad)

        // Toggle button
        let togglePressed = resolveButtonIsPressed(configuration.mapping.toggleApp, gamepad)
        let prevToggle = previousButtonStates["toggle"] ?? false
        if togglePressed && !prevToggle {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isEnabled.toggle()
                if !self.isEnabled {
                    self.forceReleaseAll()
                }
            }
        }
        previousButtonStates["toggle"] = togglePressed
    }

    private func processButtons(_ gamepad: GCExtendedGamepad) {
        // Left click
        let leftPressed = resolveButtonIsPressed(configuration.mapping.clickLeft, gamepad)
        let prevLeft = previousButtonStates["clickLeft"] ?? false

        if leftPressed && !prevLeft {
            mouseController.performLeftMouseDown()
            isLeftButtonDown = true
        } else if !leftPressed && prevLeft {
            mouseController.performLeftMouseUp()
            isLeftButtonDown = false
        }
        previousButtonStates["clickLeft"] = leftPressed

        // Right click
        let rightPressed = resolveButtonIsPressed(configuration.mapping.clickRight, gamepad)
        let prevRight = previousButtonStates["clickRight"] ?? false

        if rightPressed && !prevRight {
            mouseController.performRightMouseDown()
            isRightButtonDown = true
        } else if !rightPressed && prevRight {
            mouseController.performRightMouseUp()
            isRightButtonDown = false
        }
        previousButtonStates["clickRight"] = rightPressed

        // Delete word (Option+Backspace) / Delete to line start with R2 (Command+Backspace)
        let deletePressed = resolveButtonIsPressed(configuration.mapping.deleteWord, gamepad)
        let prevDelete = previousButtonStates["deleteWord"] ?? false
        if deletePressed && !prevDelete {
            let r2Held = gamepad.rightTrigger.value > 0.5
            if r2Held {
                keyboardController.deleteToLineStart()
            } else {
                keyboardController.deleteWord()
            }
        }
        previousButtonStates["deleteWord"] = deletePressed

        // Dictation
        let dictationPressed = resolveButtonIsPressed(configuration.mapping.dictation, gamepad)
        let prevDictation = previousButtonStates["dictation"] ?? false
        if dictationPressed && !prevDictation {
            keyboardController.toggleDictation()
        }
        previousButtonStates["dictation"] = dictationPressed

        // App switch forward (Cmd+Tab)
        let switchForwardPressed = resolveButtonIsPressed(configuration.mapping.appSwitchForward, gamepad)
        let prevSwitchForward = previousButtonStates["appSwitchForward"] ?? false
        if switchForwardPressed && !prevSwitchForward {
            keyboardController.appSwitchForward()
        }
        previousButtonStates["appSwitchForward"] = switchForwardPressed

        // App switch backward (Cmd+Shift+Tab)
        let switchBackwardPressed = resolveButtonIsPressed(configuration.mapping.appSwitchBackward, gamepad)
        let prevSwitchBackward = previousButtonStates["appSwitchBackward"] ?? false
        if switchBackwardPressed && !prevSwitchBackward {
            keyboardController.appSwitchBackward()
        }
        previousButtonStates["appSwitchBackward"] = switchBackwardPressed

        // Arrow Up
        let arrowUpPressed = resolveButtonIsPressed(configuration.mapping.arrowUp, gamepad)
        let prevArrowUp = previousButtonStates["arrowUp"] ?? false
        if arrowUpPressed && !prevArrowUp {
            keyboardController.pressArrowUp()
        }
        previousButtonStates["arrowUp"] = arrowUpPressed

        // Arrow Down
        let arrowDownPressed = resolveButtonIsPressed(configuration.mapping.arrowDown, gamepad)
        let prevArrowDown = previousButtonStates["arrowDown"] ?? false
        if arrowDownPressed && !prevArrowDown {
            keyboardController.pressArrowDown()
        }
        previousButtonStates["arrowDown"] = arrowDownPressed

        // Arrow Left
        let arrowLeftPressed = resolveButtonIsPressed(configuration.mapping.arrowLeft, gamepad)
        let prevArrowLeft = previousButtonStates["arrowLeft"] ?? false
        if arrowLeftPressed && !prevArrowLeft {
            keyboardController.pressArrowLeft()
        }
        previousButtonStates["arrowLeft"] = arrowLeftPressed

        // Arrow Right
        let arrowRightPressed = resolveButtonIsPressed(configuration.mapping.arrowRight, gamepad)
        let prevArrowRight = previousButtonStates["arrowRight"] ?? false
        if arrowRightPressed && !prevArrowRight {
            keyboardController.pressArrowRight()
        }
        previousButtonStates["arrowRight"] = arrowRightPressed

        // Enter
        let enterPressed = resolveButtonIsPressed(configuration.mapping.enterKey, gamepad)
        let prevEnter = previousButtonStates["enterKey"] ?? false
        if enterPressed && !prevEnter {
            keyboardController.pressEnter()
        }
        previousButtonStates["enterKey"] = enterPressed
    }

    private func resolveButtonIsPressed(_ buttonName: String, _ gamepad: GCExtendedGamepad) -> Bool {
        guard let button = ButtonMapping.resolve(buttonName, on: gamepad) else {
            print("[DEBUG] Unknown button: \(buttonName)")
            return false
        }
        let pressed = button.isPressed
        if pressed { print("[DEBUG] Button pressed: \(buttonName) (value=\(button.value))") }
        return pressed
    }
}
