// App Store Connect IAP review-screenshot generator. Not part of the regular
// test suite (lives in tool/, CI runs test/ only). Run with:
//
//   IAP_SHOT_DIR=/path/to/output flutter test tool/iap_review_screenshots_test.dart
//
// Renders the real paywall sheet + filter strip (locked state) at iPhone
// 6.7" resolution (1290×2796) and writes one PNG per paid collection.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/features/paywall/entitlement_controller.dart';
import 'package:mirrorbooth/features/paywall/paywall_sheet.dart';
import 'package:mirrorbooth/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScreenshotEntitlement extends EntitlementController {
  _ScreenshotEntitlement(super.service, super.prefs)
      : super(storeSupported: false) {
    state = EntitlementState(
      owned: const {},
      storeAvailable: true,
      products: {
        for (final c in FilterCollection.values)
          if (c.productId != null)
            c: ProductDetails(
              id: c.productId!,
              title: '${c.label} Collection',
              description: '${c.label} filters',
              price: r'$1.99',
              rawPrice: 1.99,
              currencyCode: 'USD',
            ),
      },
    );
  }
}

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
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);

  // Roboto lacks the geometric glyphs used as filter icons (◉ ◕ ❆ …);
  // on-device system fonts cover them via fallback, in tests we borrow the
  // macOS symbols font for the same effect.
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

void main() {
  testWidgets('generate IAP review screenshots', (tester) async {
    await tester.runAsync(_loadRealFonts);

    // This IS a test — it just lives in tool/ so CI's suite skips it.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // 6.9" display (iPhone 16 Pro Max class) — as of 2026 this is one of the
    // only two iPhone sizes App Store Connect still accepts for uploaded
    // screenshots (the other being 6.5" / 1242x2688); the old 6.7"
    // (1290x2796) now fails with "The dimensions of one or more screenshots
    // are wrong."
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final outDir = Directory(
        Platform.environment['IAP_SHOT_DIR'] ?? Directory.systemTemp.path)
      ..createSync(recursive: true);

    final scenes = {
      FilterCollection.art: MirrorFilter.pencil,
      FilterCollection.fantasy: MirrorFilter.vampire,
    };

    for (final MapEntry(key: collection, value: filter) in scenes.entries) {
      final controller = _ScreenshotEntitlement(PurchaseService(), prefs);
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entitlementProvider.overrideWith((_) => controller),
          ],
          child: RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: () {
                final base = ThemeData.dark(useMaterial3: true).copyWith(
                  scaffoldBackgroundColor: Colors.black,
                  colorScheme: const ColorScheme.dark(),
                );
                return base.copyWith(
                  textTheme: base.textTheme.apply(
                      fontFamilyFallback: const [
                        'AppleSymbols',
                        'ZapfDingbats'
                      ]),
                );
              }(),
              home: Scaffold(
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Stand-in for the live camera preview.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.25),
                          radius: 1.2,
                          colors: [Color(0xFF3A3A46), Color(0xFF0A0A0E)],
                        ),
                      ),
                    ),
                    // Staged above where the sheet will sit so the locked
                    // chips stay visible in the screenshot.
                    Positioned(
                      bottom: 380,
                      left: 0,
                      right: 0,
                      child: FilterStrip(
                        selected: filter,
                        onSelect: (_) {},
                        ownedCollections: const {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      showPaywallSheet(tester.element(find.byType(Stack).first), collection);
      await tester.pumpAndSettle();

      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final width = image.width;
        final height = image.height;
        image.dispose();
        // Apple rejects screenshots carrying an alpha channel, even fully
        // opaque (ui.Image's built-in PNG encoder always emits one) — flatten
        // to plain RGB, same as the promo-image generator.
        final src = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: rgba!.buffer,
          numChannels: 4,
          order: img.ChannelOrder.rgba,
        );
        final flat = img.Image(width: width, height: height, numChannels: 3);
        img.compositeImage(flat, src);
        final bytes = img.encodePng(flat);
        final file =
            File('${outDir.path}/iap_review_${collection.name}.png');
        await file.writeAsBytes(bytes);
        debugPrint('wrote ${file.path} (${width}x$height)');
      });
    }
  });
}
