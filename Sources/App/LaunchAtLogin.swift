import Foundation
import ServiceManagement

/// Thin wrapper over `SMAppService` for the "Launch at login" toggle. Lets the
/// app register itself as a login item so it's always present in the menu bar
/// (a prerequisite for auto-connecting when the buds connect).
///
/// The user's choice is also kept in UserDefaults. The login item macOS keeps
/// is tied to the bundle identifier and the on-disk path, so a reinstall
/// to a different location silently drops it — the toggle still read "on" in
/// the old item's settings while nothing launched. Re-registering from the
/// stored preference at launch puts the item back the next time the app runs.
enum LaunchAtLogin {
    private static let preferenceKey = "launchAtLogin"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers/unregisters the app as a login item. Errors are logged rather
    /// than thrown — registration can fail for an unsigned/ad-hoc build run
    /// outside /Applications.
    static func set(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: preferenceKey)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            DiagnosticsLog.shared.log(
                "launch at login: \(enabled ? "register" : "unregister") failed: \(error)")
        }
    }

    /// Called once at launch: restores a registration the user asked for but
    /// macOS no longer has, and records the current state in the log so a
    /// "doesn't start at login" report shows which side forgot.
    static func restoreIfNeeded() {
        let status = SMAppService.mainApp.status
        let wanted = UserDefaults.standard.object(forKey: preferenceKey) as? Bool
        DiagnosticsLog.shared.log(
            "launch at login: status \(status.rawValue), preference \(wanted.map(String.init) ?? "unset"), "
            + "path \(Bundle.main.bundlePath)")
        guard wanted == true, status != .enabled, status != .requiresApproval else { return }
        set(true)
    }
}
