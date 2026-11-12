import Flutter
import UIKit
import Vision

/// Face detection for face-anchored filters (Apple Vision, on device).
/// `detect` takes a small RGBA frame and returns the face boxes, largest
/// first, as [left, top, width, height] normalized with a top-left origin.
public class FacePlugin: NSObject, FlutterPlugin {
    private let queue = DispatchQueue(label: "mirrorbooth.face", qos: .userInitiated)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "mirrorbooth/face",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(FacePlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "detect",
              let args = call.arguments as? [String: Any],
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let data = args["rgba"] as? FlutterStandardTypedData
        else {
            result(FlutterMethodNotImplemented)
            return
        }
        queue.async {
            let boxes = Self.detect(rgba: data.data, width: width, height: height)
            DispatchQueue.main.async { result(boxes) }
        }
    }

    private static func detect(rgba: Data, width: Int, height: Int) -> [[Double]] {
        guard rgba.count >= width * height * 4,
              let provider = CGDataProvider(data: rgba as CFData),
              let image = CGImage(
                  width: width, height: height,
                  bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false,
                  intent: .defaultIntent)
        else { return [] }
        let request = VNDetectFaceRectanglesRequest()
        do {
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        } catch {
            return []
        }
        // Vision boxes are normalized with a bottom-left origin.
        let faces: [VNFaceObservation] = request.results ?? []
        let boxes: [CGRect] = faces.map { $0.boundingBox }
            .sorted { (a: CGRect, b: CGRect) -> Bool in a.width * a.height > b.width * b.height }
        return boxes.map { (b: CGRect) -> [Double] in
            let left = Double(b.minX)
            let top = 1.0 - Double(b.maxY)
            return [left, top, Double(b.width), Double(b.height)]
        }
    }
}
