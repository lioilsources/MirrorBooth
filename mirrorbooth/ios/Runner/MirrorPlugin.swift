import Flutter
import Foundation

public class MirrorPlugin: NSObject, FlutterPlugin {
    let processor = MirrorVideoProcessor()
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "mirrorbooth/mirror",
            binaryMessenger: registrar.messenger()
        )
        let instance = MirrorPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }
        switch call.method {
        case "setEnabled":
            processor.isEnabled = (args["enabled"] as? Bool) ?? false
            result(nil)
        case "setMirrorSide":
            let side = (args["side"] as? String) ?? "left"
            processor.mirrorLeft = side == "left"
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
