import Cocoa
import CoreGraphics

final class MouseController {
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    func moveCursor(dx: Double, dy: Double, isLeftButtonDown: Bool, isRightButtonDown: Bool) {
        guard let source = eventSource else { return }

        let currentLocation = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint

        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
        let scaleFactor = screen?.backingScaleFactor ?? 1.0

        let adjustedDx = dx / Double(scaleFactor)
        let adjustedDy = dy / Double(scaleFactor)

        let newX = currentLocation.x + adjustedDx
        let newY = currentLocation.y - adjustedDy

        let eventType: CGEventType
        if isLeftButtonDown {
            eventType = .leftMouseDragged
        } else if isRightButtonDown {
            eventType = .rightMouseDragged
        } else {
            eventType = .mouseMoved
        }

        let moveEvent = CGEvent(
            mouseEventSource: source,
            mouseType: eventType,
            mouseCursorPosition: CGPoint(x: newX, y: newY),
            mouseButton: isLeftButtonDown ? .left : (isRightButtonDown ? .right : .center)
        )
        moveEvent?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func performLeftMouseDown() {
        guard let source = eventSource else { return }
        let location = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint
        let event = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func performLeftMouseUp() {
        guard let source = eventSource else { return }
        let location = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint
        let event = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func performRightMouseDown() {
        guard let source = eventSource else { return }
        let location = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint
        let event = CGEvent(
            mouseEventSource: source,
            mouseType: .rightMouseDown,
            mouseCursorPosition: location,
            mouseButton: .right
        )
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func performRightMouseUp() {
        guard let source = eventSource else { return }
        let location = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint
        let event = CGEvent(
            mouseEventSource: source,
            mouseType: .rightMouseUp,
            mouseCursorPosition: location,
            mouseButton: .right
        )
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }

    func forceReleaseAll() {
        guard let source = eventSource else { return }
        let location = CGEvent(source: nil)?.location ?? NSEvent.mouseLocation.cgPoint

        let leftUp = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        leftUp?.post(tap: CGEventTapLocation.cghidEventTap)

        let rightUp = CGEvent(
            mouseEventSource: source,
            mouseType: .rightMouseUp,
            mouseCursorPosition: location,
            mouseButton: .right
        )
        rightUp?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}

private extension NSPoint {
    var cgPoint: CGPoint {
        let mainScreenHeight = NSScreen.screens[0].frame.height
        return CGPoint(x: x, y: mainScreenHeight - y)
    }
}
