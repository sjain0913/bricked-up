import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.bricked-up-ios")
    }

    private func makeConfig(appName: String? = nil) -> ShieldConfiguration {
        let modeName = sharedDefaults?.string(forKey: "activeModeName") ?? "Focus"

        let title = "BRICKED"
        let subtitle: String
        if let appName {
            subtitle = "\(appName) is locked during \(modeName) mode.\nTap your NFC chip to unlock."
        } else {
            subtitle = "\(modeName) mode is active.\nTap your NFC chip to unlock."
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.95),
            icon: UIImage(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(
                text: title,
                color: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor(white: 0.75, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(appName: application.localizedDisplayName ?? category.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(appName: webDomain.domain ?? category.localizedDisplayName)
    }
}
