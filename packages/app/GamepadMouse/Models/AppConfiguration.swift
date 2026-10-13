import Foundation

struct AppConfiguration: Codable {
    var pollingHz: Int = 120
    var mouseSpeed: Double = 15.0
    var scrollSpeed: Double = 5.0
    var deadzone: Double = 0.10
    var invertScrollY: Bool = false
    var mapping: ButtonMappingConfig = .default

    enum CodingKeys: String, CodingKey {
        case pollingHz = "polling_hz"
        case mouseSpeed = "mouse_speed"
        case scrollSpeed = "scroll_speed"
        case deadzone
        case invertScrollY = "invert_scroll_y"
        case mapping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pollingHz = (try? container.decode(Int.self, forKey: .pollingHz)) ?? 120
        mouseSpeed = (try? container.decode(Double.self, forKey: .mouseSpeed)) ?? 15.0
        scrollSpeed = (try? container.decode(Double.self, forKey: .scrollSpeed)) ?? 5.0
        deadzone = (try? container.decode(Double.self, forKey: .deadzone)) ?? 0.10
        invertScrollY = (try? container.decode(Bool.self, forKey: .invertScrollY)) ?? false
        mapping = (try? container.decode(ButtonMappingConfig.self, forKey: .mapping)) ?? .default
    }

    init() {}

    static let `default` = AppConfiguration()
}

struct ButtonMappingConfig: Codable {
    var clickLeft: String = "button_bottom"
    var clickRight: String = "button_left"
    var deleteWord: String = "button_right"
    var toggleApp: String = "button_start"
    var dictation: String = "button_top"
    var appSwitchForward: String = "r1"
    var appSwitchBackward: String = "l1"
    var arrowUp: String = "dpad_up"
    var arrowDown: String = "dpad_down"
    var arrowLeft: String = "dpad_left"
    var arrowRight: String = "dpad_right"
    var enterKey: String = "l3"

    enum CodingKeys: String, CodingKey {
        case clickLeft = "click_left"
        case clickRight = "click_right"
        case deleteWord = "delete_word"
        case toggleApp = "toggle_app"
        case dictation
        case appSwitchForward = "app_switch_forward"
        case appSwitchBackward = "app_switch_backward"
        case arrowUp = "arrow_up"
        case arrowDown = "arrow_down"
        case arrowLeft = "arrow_left"
        case arrowRight = "arrow_right"
        case enterKey = "enter_key"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        clickLeft = (try? container.decode(String.self, forKey: .clickLeft)) ?? "button_bottom"
        clickRight = (try? container.decode(String.self, forKey: .clickRight)) ?? "button_left"
        deleteWord = (try? container.decode(String.self, forKey: .deleteWord)) ?? "button_right"
        toggleApp = (try? container.decode(String.self, forKey: .toggleApp)) ?? "button_start"
        dictation = (try? container.decode(String.self, forKey: .dictation)) ?? "button_top"
        appSwitchForward = (try? container.decode(String.self, forKey: .appSwitchForward)) ?? "r1"
        appSwitchBackward = (try? container.decode(String.self, forKey: .appSwitchBackward)) ?? "l1"
        arrowUp = (try? container.decode(String.self, forKey: .arrowUp)) ?? "dpad_up"
        arrowDown = (try? container.decode(String.self, forKey: .arrowDown)) ?? "dpad_down"
        arrowLeft = (try? container.decode(String.self, forKey: .arrowLeft)) ?? "dpad_left"
        arrowRight = (try? container.decode(String.self, forKey: .arrowRight)) ?? "dpad_right"
        enterKey = (try? container.decode(String.self, forKey: .enterKey)) ?? "l3"
    }

    init() {}

    static let `default` = ButtonMappingConfig()
}
