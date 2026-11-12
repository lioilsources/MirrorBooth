import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    MirrorPlugin.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "MirrorPlugin")!)
    ShutterPlugin.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "ShutterPlugin")!)
    FacePlugin.register(with: engineBridge.pluginRegistry.registrar(forPlugin: "FacePlugin")!)
    PromotedPurchasePlugin.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "PromotedPurchasePlugin")!)
  }
}

/// Purchases started on the App Store product page (promoted in-app
/// purchases). The in_app_purchase plugin runs on StoreKit 2, which delivers
/// them as `PurchaseIntent`s (iOS 16.4+) rather than through the StoreKit 1
/// `shouldAddStorePayment` hook. This only forwards the product ID; Dart
/// buys it through the normal purchase flow, which finishes the transaction.
/// Intents that arrive before Dart says "ready" (cold launch from the store)
/// are kept and handed over then.
final class PromotedPurchasePlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private var pending: [String] = []
  private var dartReady = false
  private var listener: Task<Void, Never>?

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "mirrorbooth/promoted_purchase",
      binaryMessenger: registrar.messenger()
    )
    let instance = PromotedPurchasePlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.listen()
  }

  private func listen() {
    guard #available(iOS 16.4, *) else { return }
    listener = Task { [weak self] in
      for await intent in PurchaseIntent.intents {
        let id = intent.product.id
        await MainActor.run { self?.deliver(id) }
      }
    }
  }

  private func deliver(_ productId: String) {
    if dartReady {
      channel.invokeMethod("purchaseIntent", arguments: productId)
    } else {
      pending.append(productId)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "ready":
      dartReady = true
      result(pending)
      pending.removeAll()
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  deinit {
    listener?.cancel()
  }
}
