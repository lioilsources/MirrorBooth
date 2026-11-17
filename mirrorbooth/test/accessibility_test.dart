// Backs the App Store Accessibility labels: VoiceOver labels on the icon-only
// controls and Larger Text (Dynamic Type) on the camera controls and paywall.
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/core/mirror_side.dart';
import 'package:mirrorbooth/features/mirror_preview/camera_lens_toggle_button.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/features/mirror_preview/side_toggle_button.dart';
import 'package:mirrorbooth/features/paywall/entitlement_controller.dart';
import 'package:mirrorbooth/features/paywall/paywall_sheet.dart';
import 'package:mirrorbooth/l10n/app_localizations.dart';
import 'package:mirrorbooth/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProductDetails _product(String id, [String price = r'$0.99']) =>
    ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: 0.99,
      currencyCode: 'USD',
    );

class _Entitlement extends EntitlementController {
  _Entitlement(super.service, super.prefs, {Set<FilterCollection>? owned})
      : super(storeSupported: false) {
    state = EntitlementState(
      owned: owned ?? const {},
      storeAvailable: true,
      products: {FilterCollection.art: _product('art')},
      bundleTiers: {
        0: _product('all'),
        1: _product('all_s1', r'$3.99'),
      },
    );
  }
}

Widget _app(Widget child, {double textScale = 1, List overrides = const []}) =>
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(backgroundColor: Colors.black, body: child),
      ),
    );

Widget _controls() => Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilterStrip(
          selected: MirrorFilter.pencil,
          onSelect: (_) {},
          ownedCollections: const {},
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SideToggleButton(current: MirrorSide.left, onToggle: () {}),
            CameraLensToggleButton(
              current: CameraLensDirection.front,
              onToggle: () {},
            ),
          ],
        ),
      ],
    );

/// iPhone 15 logical size, so layouts are checked at phone width.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('icon-only controls have screen-reader labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(_controls()));
    expect(
      find.bySemanticsLabel(RegExp('^Mirror side')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('^Switch camera')), findsOneWidget);
    semantics.dispose();
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('camera controls lay out at text scale $scale',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(_controls(), textScale: scale));
      expect(tester.takeException(), isNull);
    });

    for (final discounted in [false, true]) {
      testWidgets(
          'paywall lays out at text scale $scale'
          '${discounted ? ' with a discounted bundle' : ''}', (tester) async {
        _phone(tester);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(_app(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    showPaywallSheet(context, FilterCollection.art),
                child: const Text('open'),
              ),
            ),
          ),
          textScale: scale,
          overrides: [
            entitlementProvider.overrideWith(
              (ref) => _Entitlement(
                PurchaseService(),
                prefs,
                owned: discounted ? {FilterCollection.fantasy} : null,
              ),
            ),
          ],
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(
          find.text(discounted
              ? r'All filters for $3.99'
              : r'All filters for $0.99'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
