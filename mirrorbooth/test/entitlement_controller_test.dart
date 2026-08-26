import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mirrorbooth/core/mirror_filter.dart';
import 'package:mirrorbooth/features/mirror_preview/filter_strip.dart';
import 'package:mirrorbooth/features/paywall/entitlement_controller.dart';
import 'package:mirrorbooth/services/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePurchaseService implements PurchaseService {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  final bought = <ProductDetails>[];
  int restoreCalls = 0;
  bool available = true;
  List<ProductDetails> products = [];

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
}

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
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final service = FakePurchaseService();
  final controller = EntitlementController(
    service,
    prefs,
    storeSupported: storeSupported,
  );
  // Let _init's async chain settle.
  await Future<void>.delayed(Duration.zero);
  return (controller, service, prefs);
}

const _artId = 'com.ol1n.mirrorbooth.collection.art';
const _fantasyId = 'com.ol1n.mirrorbooth.collection.fantasy';

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
  });

  group('FilterCollection metadata', () {
    test('every filter except none has a collection', () {
      for (final f in MirrorFilter.values) {
        expect(f.collection, f == MirrorFilter.none ? isNull : isNotNull,
            reason: '$f');
      }
    });

    test('collection sizes are 5/5/8/6', () {
      expect(MirrorFilter.inCollection(FilterCollection.pretty), hasLength(5));
      expect(MirrorFilter.inCollection(FilterCollection.ugly), hasLength(5));
      expect(MirrorFilter.inCollection(FilterCollection.art), hasLength(8));
      expect(MirrorFilter.inCollection(FilterCollection.fantasy), hasLength(6));
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
      // Art + Fantasy tabs are locked (active tab is Pretty → free chips).
      expect(find.byIcon(Icons.lock), findsNWidgets(2));
    });

    testWidgets('owned collections show no locks', (tester) async {
      await tester.pumpWidget(
          strip(const {FilterCollection.art, FilterCollection.fantasy}));
      expect(find.byIcon(Icons.lock), findsNothing);
    });
  });
}
