import AVKit
import Flutter
import UIKit

/// Hardware capture-button shutter (volume buttons, Action button, Camera
/// Control) via AVCaptureEventInteraction — the public API Apple provides for
/// camera apps on iOS 17.2+. Older systems simply never emit events and the
/// on-screen buttons remain the only trigger.
public class ShutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    /// Hold this long to toggle recording instead of taking a photo.
    private static let longPressSeconds: CFTimeInterval = 0.5

    private var eventSink: FlutterEventSink?
    private var pressStart: CFTimeInterval?
    /// Typed as Any? so the class still compiles/loads below iOS 17.2.
    private var interaction: Any?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ShutterPlugin()
        let methodChannel = FlutterMethodChannel(
            name: "mirrorbooth/shutter",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        let eventChannel = FlutterEventChannel(
            name: "mirrorbooth/shutter_events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setEnabled":
            let args = call.arguments as? [String: Any]
            setEnabled((args?["enabled"] as? Bool) ?? false)
            result(nil)
        case "isSupported":
            if #available(iOS 17.2, *) { result(true) } else { result(false) }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - Capture events

    private func setEnabled(_ enabled: Bool) {
        guard #available(iOS 17.2, *) else { return }
        if enabled {
            guard interaction == nil, let view = rootView() else { return }
            let captureInteraction = AVCaptureEventInteraction { [weak self] event in
                self?.handleCaptureEvent(event)
            }
            captureInteraction.isEnabled = true
            view.addInteraction(captureInteraction)
            interaction = captureInteraction
        } else {
            if let captureInteraction = interaction as? AVCaptureEventInteraction {
                captureInteraction.view?.removeInteraction(captureInteraction)
            }
            interaction = nil
            pressStart = nil
        }
    }

    @available(iOS 17.2, *)
    private func handleCaptureEvent(_ event: AVCaptureEvent) {
        switch event.phase {
        case .began:
            pressStart = CACurrentMediaTime()
        case .ended:
            let start = pressStart ?? CACurrentMediaTime()
            pressStart = nil
            emit(long: CACurrentMediaTime() - start >= Self.longPressSeconds)
        case .cancelled:
            pressStart = nil
        @unknown default:
            pressStart = nil
        }
    }

    private func emit(long: Bool) {
        guard let sink = eventSink else { return }
        if Thread.isMainThread {
            sink(["long": long])
        } else {
            DispatchQueue.main.async { sink(["long": long]) }
        }
    }

    private func rootView() -> UIView? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        let window = windows.first { $0.isKeyWindow } ?? windows.first
        return window?.rootViewController?.view
    }
}
