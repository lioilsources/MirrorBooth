import AVFoundation
import Flutter
import Foundation

/// Diagnostic-only channel that reports the device's available camera lenses,
/// their zoom ranges, and (where applicable) the iOS virtual-device switch-
/// over zoom factors. This is consumed by the debug overlay; production zoom
/// still flows through the cross-platform `camera` plugin.
public class CameraInfoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "mirrorbooth/camera_info",
            binaryMessenger: registrar.messenger()
        )
        let instance = CameraInfoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getLensInfo":
            result(buildLensInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func buildLensInfo() -> [String: Any] {
        var out: [String: Any] = [:]
        out["front"] = lenses(for: .front)
        out["back"] = lenses(for: .back)
        return out
    }

    private func lenses(for position: AVCaptureDevice.Position) -> [[String: Any]] {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInDualCamera,
        ]
        if #available(iOS 13.0, *) {
            deviceTypes.append(contentsOf: [
                .builtInUltraWideCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
            ])
        }

        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )

        return session.devices.map { device in
            var info: [String: Any] = [
                "type": device.deviceType.rawValue,
                "name": device.localizedName,
                "minZoom": device.minAvailableVideoZoomFactor,
                "maxZoom": device.maxAvailableVideoZoomFactor,
            ]
            if #available(iOS 13.0, *) {
                let factors = device.virtualDeviceSwitchOverVideoZoomFactors.map { $0.doubleValue }
                info["switchOverFactors"] = factors
                let constituents = device.constituentDevices.map { $0.deviceType.rawValue }
                info["constituentTypes"] = constituents
                info["constituentCount"] = constituents.count
            } else {
                info["switchOverFactors"] = [Double]()
                info["constituentTypes"] = [String]()
                info["constituentCount"] = 0
            }
            return info
        }
    }
}
