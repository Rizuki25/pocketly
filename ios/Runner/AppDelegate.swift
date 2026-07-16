import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let screenPrivacyChannel = "com.pocketly/screen_privacy"
  private var sensitiveScreen = false
  private var privacyShield: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: screenPrivacyChannel,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "setSensitiveScreen" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let arguments = call.arguments as? [String: Any]
        self?.sensitiveScreen = arguments?["sensitive"] as? Bool ?? false
        self?.updatePrivacyShield()
        result(nil)
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureDidChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    return launched
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    showPrivacyShield()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    updatePrivacyShield()
  }

  @objc private func screenCaptureDidChange() {
    updatePrivacyShield()
  }

  private func updatePrivacyShield() {
    if sensitiveScreen && UIScreen.main.isCaptured {
      showPrivacyShield()
    } else {
      hidePrivacyShield()
    }
  }

  private func showPrivacyShield() {
    guard let window = window else { return }
    let shield = privacyShield ?? makePrivacyShield()
    privacyShield = shield
    shield.frame = window.bounds
    if shield.superview == nil {
      window.addSubview(shield)
    }
    window.bringSubviewToFront(shield)
    shield.isHidden = false
  }

  private func hidePrivacyShield() {
    privacyShield?.isHidden = true
  }

  private func makePrivacyShield() -> UIView {
    let shield = UIView(frame: .zero)
    shield.backgroundColor = UIColor(
      red: 30.0 / 255.0,
      green: 32.0 / 255.0,
      blue: 41.0 / 255.0,
      alpha: 1
    )
    shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let label = UILabel()
    label.text = "pocketly"
    label.textColor = UIColor(
      red: 154.0 / 255.0,
      green: 106.0 / 255.0,
      blue: 255.0 / 255.0,
      alpha: 1
    )
    label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
    label.translatesAutoresizingMaskIntoConstraints = false
    shield.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: shield.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: shield.centerYAnchor),
    ])
    return shield
  }
}
