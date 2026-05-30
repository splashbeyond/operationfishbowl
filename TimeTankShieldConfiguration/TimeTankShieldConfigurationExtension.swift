import ManagedSettings
import ManagedSettingsUI
import UIKit

final class TimeTankShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    private func configuration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: UIColor(red: 1.0, green: 0.973, blue: 0.949, alpha: 1.0),
            icon: finnIcon(),
            title: ShieldConfiguration.Label(
                text: "Your budget is spent.",
                color: UIColor(red: 0.11, green: 0.102, blue: 0.094, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Opening this will make the tank murkier.",
                color: UIColor(red: 0.522, green: 0.475, blue: 0.459, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.169, alpha: 1.0),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Anyway",
                color: UIColor(red: 1.0, green: 0.549, blue: 0.38, alpha: 1.0)
            )
        )
    }

    private func finnIcon() -> UIImage? {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor(red: 1.0, green: 0.42, blue: 0.169, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 35, y: 45, width: 48, height: 30))

            cg.setFillColor(UIColor(red: 1.0, green: 0.549, blue: 0.38, alpha: 1.0).cgColor)
            cg.beginPath()
            cg.move(to: CGPoint(x: 36, y: 60))
            cg.addLine(to: CGPoint(x: 15, y: 42))
            cg.addLine(to: CGPoint(x: 15, y: 78))
            cg.closePath()
            cg.fillPath()

            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 68, y: 51, width: 9, height: 9))

            cg.setFillColor(UIColor(red: 0.11, green: 0.102, blue: 0.094, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 72, y: 55, width: 3, height: 3))

            cg.setStrokeColor(UIColor(red: 1.0, green: 0.42, blue: 0.169, alpha: 0.3).cgColor)
            cg.setLineWidth(3)
            cg.strokeEllipse(in: CGRect(x: 8, y: 8, width: 104, height: 104))
        }
    }
}
