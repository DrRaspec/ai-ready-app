import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup method channel for alternate app icons
    let controller = window?.rootViewController as! FlutterViewController
    let iconChannel = FlutterMethodChannel(
      name: "app_icon_channel",
      binaryMessenger: controller.binaryMessenger
    )
    
    iconChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getAlternateIconName":
        if #available(iOS 10.3, *) {
          result(UIApplication.shared.alternateIconName)
        } else {
          result(nil)
        }
        
      case "setAlternateIconName":
        if #available(iOS 10.3, *) {
          guard let args = call.arguments as? [String: Any?] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
          }
          let iconName = args["iconName"] as? String
          
          UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
              result(FlutterError(code: "ICON_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(true)
            }
          }
        } else {
          result(FlutterError(code: "UNSUPPORTED", message: "iOS 10.3+ required", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

