import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mirrorbooth/services/share_service.dart';

void main() {
  testWidgets('watermark paints bottom-right only', (tester) async {
    await tester.runAsync(() async {
      const width = 400;
      const height = 800;
      final layer = ShareService.watermarkLayer(width, height);
      final bytes = (await layer.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(layer.width, width);
      expect(layer.height, height);

      var inMark = 0;
      var elsewhere = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (bytes.getUint8((y * width + x) * 4 + 3) == 0) continue;
          if (y > height * 0.85) {
            inMark++;
          } else {
            elsewhere++;
          }
        }
      }
      layer.dispose();
      expect(inMark, greaterThan(0));
      expect(elsewhere, 0);
    });
  });
}
