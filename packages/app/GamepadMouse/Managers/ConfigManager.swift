import Cocoa
import Combine
import Foundation
import TOMLDecoder

final class ConfigManager: ObservableObject {
    @Published var configuration: AppConfiguration = .default
    @Published var hasConfigError: Bool = false

    private var fileDescriptor: Int32 = -1
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var reloadWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadConfig()
        startFileWatching()

        NotificationCenter.default.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in self?.loadConfig() }
            .store(in: &cancellables)
    }

    func editConfiguration() {
        ensureConfigFileExists()
        let url = Constants.configPath
        NSWorkspace.shared.open(url)
    }

    func resetConfiguration() {
        writeDefaultConfig()
        loadConfig()
    }

    // MARK: - Config Loading

    private func loadConfig() {
        let path = Constants.configPath
        guard FileManager.default.fileExists(atPath: path.path) else {
            configuration = .default
            hasConfigError = false
            return
        }

        do {
            let data = try Data(contentsOf: path)
            let decoded = try TOMLDecoder().decode(AppConfiguration.self, from: data)
            DispatchQueue.main.async { [weak self] in
                self?.configuration = decoded
                self?.hasConfigError = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.hasConfigError = true
            }
        }
    }

    // MARK: - File Watching

    private func startFileWatching() {
        let dirURL = Constants.configDirectory
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        fileDescriptor = open(dirURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.scheduleReload()
        }
        source.resume()
        fileWatchSource = source
    }

    private func scheduleReload() {
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.loadConfig()
        }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.debounceInterval, execute: work)
    }

    // MARK: - File Management

    private func ensureConfigFileExists() {
        let path = Constants.configPath
        if !FileManager.default.fileExists(atPath: path.path) {
            writeDefaultConfig()
        }
    }

    private func writeDefaultConfig() {
        let dirURL = Constants.configDirectory
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        let toml = defaultTomlString
        try? toml.write(to: Constants.configPath, atomically: true, encoding: .utf8)
    }

    private var defaultTomlString: String {
        """
        # Gamepad Mouse Configuration

        polling_hz = 120
        mouse_speed = 15.0
        scroll_speed = 5.0

        # deadzone: Scaled radial threshold (0.0–1.0). Values below this magnitude are ignored.
        # 0.10 is recommended for most controllers; increase if you see cursor drift at rest.
        deadzone = 0.10

        invert_scroll_y = false

        [mapping]
        # Use physical positions: button_bottom, button_right, button_left, button_top, r1, l1, l3, dpad_up, dpad_down, dpad_left, dpad_right
        click_left = "button_bottom"
        click_right = "button_left"
        delete_word = "button_right"
        toggle_app = "button_start"
        app_switch_forward = "r1"
        app_switch_backward = "l1"
        arrow_up = "dpad_up"
        arrow_down = "dpad_down"
        arrow_left = "dpad_left"
        arrow_right = "dpad_right"
        enter_key = "l3"
        """
    }

    deinit {
        reloadWorkItem?.cancel()
        fileWatchSource?.cancel()
        if fileDescriptor >= 0 { close(fileDescriptor) }
    }
}
