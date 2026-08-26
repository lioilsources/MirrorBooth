// App Store Connect IAP "Promotional Image" generator (optional field, used
// for product-page promotion / win-back offers). Requirements per Apple:
// JPG or PNG, 1024x1024, 72dpi, RGB, flattened, no rounded corners, no
// screenshots/UI chrome. Not part of the regular test suite. Run with:
//
//   IAP_SHOT_DIR=/path/to/output flutter test tool/iap_promo_image_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mirrorbooth/core/mirror_filter.dart';

Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent.parent.parent.parent.parent.path;
  final fonts = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('${fonts.path}/$f');
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto',
      ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);

  for (final MapEntry(key: family, value: path) in {
    'AppleSymbols': '/System/Library/Fonts/Apple Symbols.ttf',
    'ZapfDingbats': '/System/Library/Fonts/ZapfDingbats.ttf',
  }.entries) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader(family);
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

/// Strips the alpha channel — Apple rejects promotional images that carry
/// one, even fully opaque. The canvas is fully painted, so this is a lossless
/// RGBA->RGB copy, not a blend.
Uint8List _flattenToOpaquePng(Uint8List rgba, int width, int height) {
  final src = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  final dst = img.Image(width: width, height: height, numChannels: 3);
  img.compositeImage(dst, src);
  return Uint8List.fromList(img.encodePng(dst));
}

class _PromoArt extends StatelessWidget {
  final FilterCollection collection;
  final List<Color> gradient;

  const _PromoArt({required this.collection, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final filters = MirrorFilter.inCollection(collection);
    return Container(
      width: 1024,
      height: 1024,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.3,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              collection.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 108,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'MIRRORBOOTH FILTER COLLECTION',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: 760,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 28,
                runSpacing: 20,
                children: [
                  for (final f in filters)
                    Text(
                      '${f.icon}  ${f.label}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('generate IAP promotional images', (tester) async {
    await tester.runAsync(_loadRealFonts);

    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final outDir = Directory(
        Platform.environment['IAP_SHOT_DIR'] ?? Directory.systemTemp.path)
      ..createSync(recursive: true);

    final scenes = {
      FilterCollection.art: const [Color(0xFF4A3728), Color(0xFF0A0806)],
      FilterCollection.fantasy: const [Color(0xFF33234A), Color(0xFF08050C)],
    };

    for (final MapEntry(key: collection, value: gradient) in scenes.entries) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          // Bare Text widgets resolve a null fontFamily to nothing in the
          // test environment (no system fonts) — MaterialApp normally
          // supplies 'Roboto' via its TextTheme, so without it we set the
          // same default explicitly, plus the symbol-glyph fallbacks.
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontFamilyFallback: ['AppleSymbols', 'ZapfDingbats'],
            ),
            child: RepaintBoundary(
              key: boundaryKey,
              child: _PromoArt(collection: collection, gradient: gradient),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pngBytes = _flattenToOpaquePng(
            byteData!.buffer.asUint8List(), image.width, image.height);
        image.dispose();
        final file =
            File('${outDir.path}/iap_promo_${collection.name}.png');
        await file.writeAsBytes(pngBytes);
        debugPrint('wrote ${file.path}');
      });
    }
  });
}
