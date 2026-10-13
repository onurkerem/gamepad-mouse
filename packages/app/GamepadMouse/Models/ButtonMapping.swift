import GameController

enum PhysicalButton: String, Codable, CaseIterable {
    case buttonBottom = "button_bottom"
    case buttonRight = "button_right"
    case buttonLeft = "button_left"
    case buttonTop = "button_top"
    case r1 = "r1"
    case l1 = "l1"
    case buttonStart = "button_start"
    case dpadUp    = "dpad_up"
    case dpadDown  = "dpad_down"
    case dpadLeft  = "dpad_left"
    case dpadRight = "dpad_right"
    case l3 = "l3"
}

enum ButtonMapping {
    static func resolve(_ buttonName: String, on gamepad: GCExtendedGamepad) -> GCControllerButtonInput? {
        guard let button = PhysicalButton(rawValue: buttonName) else { return nil }
        return resolve(button, on: gamepad)
    }

    static func resolve(_ button: PhysicalButton, on gamepad: GCExtendedGamepad) -> GCControllerButtonInput? {
        switch button {
        case .buttonBottom: return gamepad.buttonA
        case .buttonRight: return gamepad.buttonB
        case .buttonLeft: return gamepad.buttonX
        case .buttonTop: return gamepad.buttonY
        case .r1: return gamepad.rightShoulder
        case .l1: return gamepad.leftShoulder
        case .buttonStart: return gamepad.buttonMenu
        case .dpadUp:    return gamepad.dpad.up
        case .dpadDown:  return gamepad.dpad.down
        case .dpadLeft:  return gamepad.dpad.left
        case .dpadRight: return gamepad.dpad.right
        case .l3: return gamepad.leftThumbstickButton
        }
    }
}
