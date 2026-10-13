import CoreGraphics

final class KeyboardController {
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    // kVK_RightCommand = 54
    private static let rightCommand: UInt16 = 54

    // kVK_Delete = 51
    private static let backspace: UInt16 = 51

    // kVK_Tab = 48
    private static let tab: UInt16 = 48

    // kVK_UpArrow = 126
    private static let upArrow: UInt16 = 126
    // kVK_DownArrow = 125
    private static let downArrow: UInt16 = 125
    // kVK_LeftArrow = 123
    private static let leftArrow: UInt16 = 123
    // kVK_RightArrow = 124
    private static let rightArrow: UInt16 = 124
    // kVK_Return = 36
    private static let enter: UInt16 = 36

    func toggleDictation() {
        guard let source = eventSource else { return }

        // Double-press right Command key to trigger dictation
        postKeyPress(source: source, virtualKey: Self.rightCommand)
        usleep(100000)
        postKeyPress(source: source, virtualKey: Self.rightCommand)
    }

    func deleteWord() {
        postKeyPressWithFlags(virtualKey: Self.backspace, flags: .maskAlternate)
    }

    func deleteToLineStart() {
        postKeyPressWithFlags(virtualKey: Self.backspace, flags: .maskCommand)
    }

    func appSwitchForward() {
        postKeyPressWithFlags(virtualKey: Self.tab, flags: .maskCommand)
    }

    func appSwitchBackward() {
        postKeyPressWithFlags(virtualKey: Self.tab, flags: [.maskCommand, .maskShift])
    }

    func triggerMissionControl() {
        postKeyPressWithFlags(virtualKey: Self.upArrow, flags: .maskControl)
    }

    func triggerShowDesktop() {
        postKeyPressWithFlags(virtualKey: Self.downArrow, flags: .maskControl)
    }

    func pressArrowUp() {
        guard let source = eventSource else { return }
        postKeyPress(source: source, virtualKey: Self.upArrow)
    }

    func pressArrowDown() {
        guard let source = eventSource else { return }
        postKeyPress(source: source, virtualKey: Self.downArrow)
    }

    func pressArrowLeft() {
        guard let source = eventSource else { return }
        postKeyPress(source: source, virtualKey: Self.leftArrow)
    }

    func pressArrowRight() {
        guard let source = eventSource else { return }
        postKeyPress(source: source, virtualKey: Self.rightArrow)
    }

    func pressEnter() {
        guard let source = eventSource else { return }
        postKeyPress(source: source, virtualKey: Self.enter)
    }

    private func postKeyPress(source: CGEventSource, virtualKey: UInt16) {
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: virtualKey,
            keyDown: true
        )
        keyDown?.post(tap: CGEventTapLocation.cghidEventTap)

        usleep(30000)

        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: virtualKey,
            keyDown: false
        )
        keyUp?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    private func postKeyPressWithFlags(virtualKey: UInt16, flags: CGEventFlags) {
        guard let source = eventSource else { return }

        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: virtualKey,
            keyDown: true
        )
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        usleep(30000)

        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: virtualKey,
            keyDown: false
        )
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}
