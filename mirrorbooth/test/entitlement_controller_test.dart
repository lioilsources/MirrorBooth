import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/features/paywall/entitlement_controller.dart';
import 'package:mirrorbooth/l10n/app_localizations.dart';
import 'package:mirrorbooth/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePurchaseService implements PurchaseService {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  final bought = <ProductDetails>[];
  int restoreCalls = 0;
  bool available = true;
  List<ProductDetails> products = [];
  Set<String> history = {};
  final promoted = StreamController<String>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProducts(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: products, notFoundIDs: []);

  @override
  Future<void> buyNonConsumable(ProductDetails product) async =>
      bought.add(product);

  @override
  Future<void> restorePurchases() async => restoreCalls++;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  @override
  Future<Set<String>> purchasedProductIds() async => history;

  @override
  Stream<String> promotedPurchases() => promoted.stream;
}

ProductDetails _product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: r'$0.99',
      rawPrice: 0.99,
      currencyCode: 'USD',
    );

PurchaseDetails _purchase(
  String productId,
  PurchaseStatus status, {
  bool pendingComplete = false,
  String? errorMessage,
}) {
  final details = PurchaseDetails(
    purchaseID: 'txn-1',
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'signed-receipt',
      source: 'test',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = pendingComplete;
  if (errorMessage != null) {
    details.error =
        IAPError(source: 'test', code: 'err', message: errorMessage);
  }
  return details;
}

Future<(EntitlementController, FakePurchaseService, SharedPreferences)>
    _makeController({
  Map<String, Object> prefsValues = const {},
  bool storeSupported = true,
  Set<String> history = const {},
  List<ProductDetails> products = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final service = FakePurchaseService()
    ..history = history
    ..products = products;
  final controller = EntitlementController(
    service,
    prefs,
    storeSupported: storeSupported,
  );
  // Let _init's async chain settle.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return (controller, service, prefs);
}

// The tests run as Android (flutter_test's default platform); the App Store
// group below overrides the platform.
const _artId = 'com.ol1n.mirrorbooth.collection.art_unlock';
const _fantasyId = 'com.ol1n.mirrorbooth.collection.fantasy_unlock';
const _bundleId = 'com.ol1n.mirrorbooth.collection.all_unlock';
const _legacyArtId = 'com.ol1n.mirrorbooth.collection.art';
const _legacyFantasyId = 'com.ol1n.mirrorbooth.collection.fantasy';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntitlementController', () {
    test('cached entitlements load instantly; free always owned', () async {
      final (c, _, _) = await _makeController(prefsValues: {
        'owned_collections': ['art'],
      });
      expect(c.state.owns(FilterCollection.art), isTrue);
      expect(c.state.owns(FilterCollection.fantasy), isFalse);
      expect(c.state.owns(FilterCollection.pretty), isTrue);
      expect(c.state.owns(FilterCollection.ugly), isTrue);
    });

    test('corrupt cache values are ignored', () async {
      final (c, _, _) = await _makeController(prefsValues: {
        'owned_collections': ['bogus', 'pretty'],
      });
      // 'pretty' is free and never granted via the owned set; 'bogus' unknown.
      expect(c.state.owned, isEmpty);
    });

    test('desktop (storeSupported=false) unlocks everything', () async {
      final (c, service, _) = await _makeController(storeSupported: false);
      expect(c.state.owns(FilterCollection.art), isTrue);
      expect(c.state.owns(FilterCollection.fantasy), isTrue);
      expect(c.state.storeAvailable, isFalse);
      expect(service.controller.hasListener, isFalse);
    });

    test('purchased event grants, persists, and completes', () async {
      final (c, service, prefs) = await _makeController();
      service.controller.add([
        _purchase(_artId, PurchaseStatus.purchased, pendingComplete: true),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.owns(FilterCollection.art), isTrue);
      expect(prefs.getStringList('owned_collections'), ['art']);
      expect(service.completed, hasLength(1));
    });

    test('restored event grants', () async {
      final (c, service, _) = await _makeController();
      service.controller.add([_purchase(_fantasyId, PurchaseStatus.restored)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.owns(FilterCollection.fantasy), isTrue);
    });

    test('unknown product id is ignored', () async {
      final (c, service, _) = await _makeController();
      service.controller
          .add([_purchase('com.other.thing', PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.owned, isEmpty);
    });

    test('error event clears pending and surfaces message', () async {
      final (c, service, _) = await _makeController();
      service.controller.add([
        _purchase(_artId, PurchaseStatus.error, errorMessage: 'card declined'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.purchasePending, isFalse);
      expect(c.state.error, 'card declined');
    });

    test('user cancellation reported as error stays silent', () async {
      final (c, service, _) = await _makeController();
      service.controller.add([
        _purchase(_artId, PurchaseStatus.error,
            errorMessage: 'BillingResponse.userCanceled'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.error, isNull);
    });

    test('canceled event clears pending without error', () async {
      final (c, service, _) = await _makeController();
      service.controller.add([_purchase(_artId, PurchaseStatus.canceled)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.purchasePending, isFalse);
      expect(c.state.error, isNull);
    });

    test('restore() delegates to the service', () async {
      final (c, service, _) = await _makeController();
      await c.restore();
      expect(service.restoreCalls, 1);
    });

    test('Play sells *_unlock when it exists, else the original ID',
        () async {
      final (c, _, _) = await _makeController(products: [
        _product(_legacyArtId),
        _product(_artId),
        _product(_legacyFantasyId),
      ]);
      expect(c.state.products[FilterCollection.art]?.id, _artId);
      expect(c.state.products[FilterCollection.fantasy]?.id, _legacyFantasyId);
    });

    test('transaction history unlocks old purchases at launch', () async {
      final (c, _, prefs) =
          await _makeController(history: {_legacyFantasyId});
      expect(c.state.owns(FilterCollection.fantasy), isTrue);
      expect(c.state.owns(FilterCollection.art), isFalse);
      expect(prefs.getStringList('owned_collections'), ['fantasy']);
    });

    test('bundle purchase unlocks every paid collection', () async {
      final (c, service, _) =
          await _makeController(products: [_product(_bundleId)]);
      expect(c.state.bundle?.id, _bundleId);
      await c.buyBundle();
      expect(service.bought.single.id, _bundleId);
      service.controller.add([_purchase(_bundleId, PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.owns(FilterCollection.art), isTrue);
      expect(c.state.owns(FilterCollection.fantasy), isTrue);
    });

    test('purchase started on the store page buys that product', () async {
      final (_, service, _) = await _makeController(
          products: [_product(_artId), _product(_fantasyId)]);
      service.promoted.add(_fantasyId);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(service.bought.single.id, _fantasyId);
    });

    test('store-page purchase of an owned collection buys nothing', () async {
      final (_, service, _) = await _makeController(
        prefsValues: {'owned_collections': ['art']},
        products: [_product(_artId)],
      );
      service.promoted.add(_artId);
      await Future<void>.delayed(Duration.zero);
      expect(service.bought, isEmpty);
    });
  });

  group('App Store product IDs', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('sells the non-consumable unlocks', () {
      expect(FilterCollection.art.productId,
          'com.ol1n.mirrorbooth.collection.art_unlock');
      expect(FilterCollection.fantasy.productId,
          'com.ol1n.mirrorbooth.collection.fantasy_unlock');
      expect(FilterCollection.storeProductIds, {
        'com.ol1n.mirrorbooth.collection.art_unlock',
        'com.ol1n.mirrorbooth.collection.fantasy_unlock',
        'com.ol1n.mirrorbooth.collection.all_unlock',
        for (final p in FilterCollection.packs)
          'com.ol1n.mirrorbooth.collection.${p.name}',
      });
    });

    test('never sells the old consumables', () {
      expect(FilterCollection.storeProductIds,
          isNot(contains(anyOf(_legacyArtId, _legacyFantasyId))));
    });

    test('old consumables still grant their collection', () {
      expect(FilterCollection.grantedBy(_legacyArtId), {FilterCollection.art});
      expect(FilterCollection.grantedBy(_legacyFantasyId),
          {FilterCollection.fantasy});
      expect(
          FilterCollection.grantedBy(
              'com.ol1n.mirrorbooth.collection.all_unlock'),
          FilterCollection.values.where((c) => c.isPaid).toSet());
    });
  });

  group('FilterCollection metadata', () {
    test('every filter except none has a collection', () {
      for (final f in MirrorFilter.values) {
        expect(f.collection, f == MirrorFilter.none ? isNull : isNotNull,
            reason: '$f');
      }
    });

    // Pins the shipped filters to their collections (free vs paid must never
    // change silently). Collections may grow: pipeline/integrate.py adds new
    // filters to a collection chosen explicitly on its command line.
    test('shipped filters stay in their collections', () {
      const shipped = {
        FilterCollection.pretty: ['glow', 'slim', 'doll', 'chibi', 'lips'],
        FilterCollection.ugly: ['bigNose', 'alien', 'melt', 'bigEars', 'longNeck'],
        FilterCollection.art: [
          'pencil', 'comic', 'glitch', 'neon', 'thermal', 'oil', 'crt', 'popArt'
        ],
        FilterCollection.fantasy: [
          'vampire', 'zombie', 'ghost', 'demon', 'cyborg', 'frozen'
        ],
      };
      for (final MapEntry(key: c, value: names) in shipped.entries) {
        final actual = MirrorFilter.inCollection(c).map((f) => f.name);
        expect(actual, containsAllInOrder(names), reason: '$c');
      }
    });

    test('isPaid ⇔ productId non-null, and IDs round-trip', () {
      for (final c in FilterCollection.values) {
        expect(c.productId != null, c.isPaid, reason: '$c');
        if (c.productId case final id?) {
          expect(FilterCollection.byProductId(id), c);
        }
      }
      expect(FilterCollection.byProductId('nope'), isNull);
    });
  });

  group('FilterStrip lock badges', () {
    Widget strip(Set<FilterCollection> owned) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FilterStrip(
              selected: MirrorFilter.none,
              onSelect: (_) {},
              ownedCollections: owned,
            ),
          ),
        );

    testWidgets('unowned paid collections show locks', (tester) async {
      await tester.pumpWidget(strip(const {}));
      // Art, Fantasy and Packs tabs are locked (active tab is Pretty).
      expect(find.byIcon(Icons.lock), findsNWidgets(3));
    });

    testWidgets('owned collections show no locks', (tester) async {
      await tester.pumpWidget(
          strip(FilterCollection.values.where((c) => c.isPaid).toSet()));
      expect(find.byIcon(Icons.lock), findsNothing);
    });
  });
}
