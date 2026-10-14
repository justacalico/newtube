import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "newtube.pip") {
      PipController.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "newtube.brightness") {
      let channel = FlutterMethodChannel(
        name: "newtube/brightness",
        binaryMessenger: registrar.messenger(),
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getBrightness":
          result(Double(UIScreen.main.brightness))
        case "setBrightness":
          if let value = call.arguments as? Double {
            UIScreen.main.brightness = CGFloat(value)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
