import Foundation

enum Constants {
    static let configDirectoryName = "gamepad-mouse"
    static let configDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent(configDirectoryName)
    }()
    static let configFileName = "config.toml"
    static let configPath: URL = configDirectory.appendingPathComponent(configFileName)

    static let debounceInterval: TimeInterval = 0.5
    static let permissionPollInterval: TimeInterval = 1.0
    static let maxDeltaTime: TimeInterval = 0.1

    static var isMacOS154Buggy: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return version.majorVersion == 15 && version.minorVersion == 4
    }
}
