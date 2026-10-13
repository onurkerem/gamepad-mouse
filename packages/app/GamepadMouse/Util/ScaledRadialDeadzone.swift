import Foundation

enum ScaledRadialDeadzone {
    static func apply(x: Float, y: Float, deadzone: Float) -> (x: Float, y: Float) {
        let magnitude = sqrt(x * x + y * y)
        guard magnitude > deadzone else { return (0, 0) }

        let scaledMagnitude = (magnitude - deadzone) / (1.0 - deadzone)
        let normalizedX = x / magnitude
        let normalizedY = y / magnitude

        return (normalizedX * scaledMagnitude, normalizedY * scaledMagnitude)
    }
}
