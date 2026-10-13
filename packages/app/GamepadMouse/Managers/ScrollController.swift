import CoreGraphics

final class ScrollController {
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    private var accumulatedX: Double = 0
    private var accumulatedY: Double = 0

    func scroll(dx: Double, dy: Double, invertY: Bool) {
        guard let source = eventSource else { return }
        guard abs(dx) > 0.001 || abs(dy) > 0.001 else { return }

        var scrollY = dy
        var scrollX = dx

        if invertY { scrollY = -scrollY }

        accumulatedY += scrollY
        accumulatedX += scrollX

        let pixelsY = Int32(accumulatedY)
        let pixelsX = Int32(accumulatedX)

        accumulatedY -= Double(pixelsY)
        accumulatedX -= Double(pixelsX)

        guard pixelsY != 0 || pixelsX != 0 else { return }

        let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .pixel,
            wheelCount: pixelsX != 0 ? 2 : 1,
            wheel1: pixelsY,
            wheel2: pixelsX,
            wheel3: 0
        )

        event?.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
