import 'dart:typed_data';

import 'package:image/image.dart' as img;

class EncodeJob {
  final Uint8List rgbaBytes;
  final int width;
  final int height;
  const EncodeJob({required this.rgbaBytes, required this.width, required this.height});
}

Uint8List encodeToJpeg(EncodeJob job) {
  final image = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.rgbaBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}

Uint8List encodeToPng(EncodeJob job) {
  final image = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.rgbaBytes.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodePng(image));
}
