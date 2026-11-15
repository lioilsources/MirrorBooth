import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/mirror_filter.dart';
import '../../core/set_ladder.dart';
import '../../services/purchase_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

class EntitlementState {
  /// Paid collections the user owns. Free collections are never stored here —
  /// [owns] treats them as always owned.
  final Set<FilterCollection> owned;

  /// Store metadata for paid collections, for price display on the paywall.
  final Map<FilterCollection, ProductDetails> products;

  /// "All filters" tiers the store returned, keyed by threshold (see
  /// [FilterCollection.bundleLadder]); tier 0 is the full price.
  final Map<int, ProductDetails> bundleTiers;

  /// False on desktop platforms and when the store is unreachable.
  final bool storeAvailable;

  /// A buy or restore call is in flight.
  final bool purchasePending;

  /// Last user-facing purchase error, null when none.
  final String? error;

  const EntitlementState({
    this.owned = const {},
    this.products = const {},
    this.bundleTiers = const {},
    this.storeAvailable = false,
    this.purchasePending = false,
    this.error,
  });

  bool owns(FilterCollection c) => !c.isPaid || owned.contains(c);

  /// Paid collections owned, the count the bundle tier is chosen by.
  int get ownedPaidCount => owned.where((c) => c.isPaid).length;

  /// The "All filters" tier on offer: the highest one the store returned whose
  /// threshold [ownedPaidCount] meets. Recomputed from [owned], so it drops
  /// right after a single-collection purchase. Null when the store sells no
  /// bundle. A tier the store did not return is skipped, so before the
  /// discounted products exist the full-price bundle is offered as before.
  ProductDetails? get bundle {
    final ladder = [
      for (final tier in FilterCollection.bundleLadder)
        if (bundleTiers[tier.threshold] case final p?)
          (threshold: tier.threshold, productId: p.id),
    ];
    final id = offerFromLadder(ownedPaidCount, ladder);
    return bundleTiers.values.where((p) => p.id == id).firstOrNull;
  }

  /// Threshold of the offered tier; 0 for the full price or no bundle.
  int get bundleThreshold {
    final id = bundle?.id;
    for (final MapEntry(:key, :value) in bundleTiers.entries) {
      if (value.id == id) return key;
    }
    return 0;
  }

  /// Full (tier 0) store price to strike through next to a discounted tier;
  /// null at tier 0 or when the store returned no tier 0 price.
  String? get bundleFullPrice {
    if (bundleThreshold == 0) return null;
    final price = bundleTiers[0]?.price;
    return price == null || price.isEmpty ? null : price;
  }

  EntitlementState copyWith({
    Set<FilterCollection>? owned,
    Map<FilterCollection, ProductDetails>? products,
    Map<int, ProductDetails>? bundleTiers,
    bool? storeAvailable,
    bool? purchasePending,
    String? error,
    bool clearError = false,
  }) {
    return EntitlementState(
      owned: owned ?? this.owned,
      products: products ?? this.products,
      bundleTiers: bundleTiers ?? this.bundleTiers,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      purchasePending: purchasePending ?? this.purchasePending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Controller ───────────────────────────────────────────────────────────────

class EntitlementController extends StateNotifier<EntitlementState> {
  static const _prefsKey = 'owned_collections';

  final PurchaseService _service;
  final SharedPreferences _prefs;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  StreamSubscription<String>? _promotedSub;

  /// Completes once product metadata has been queried (or the query failed),
  /// so a purchase started from the App Store can wait for it.
  final _productsLoaded = Completer<void>();

  EntitlementController(
    this._service,
    this._prefs, {
    bool? storeSupported,
  }) : super(const EntitlementState()) {
    _init(storeSupported ?? (Platform.isIOS || Platform.isAndroid));
  }

  Future<void> _init(bool storeSupported) async {
    // Cached entitlements first: instant and offline-safe.
    final cached = _prefs.getStringList(_prefsKey) ?? const [];
    final owned = <FilterCollection>{
      for (final name in cached)
        for (final c in FilterCollection.values)
          if (c.name == name && c.isPaid) c,
    };

    if (!storeSupported) {
      // Desktop builds have no store; everything is unlocked there.
      state = state.copyWith(
        owned: FilterCollection.values.where((c) => c.isPaid).toSet(),
        storeAvailable: false,
      );
      return;
    }

    state = state.copyWith(owned: owned);

    // Subscribe before any store query so transactions delivered at launch
    // (interrupted purchases, Ask-to-Buy approvals) are not missed.
    _sub = _service.purchaseStream.listen(_onPurchaseUpdates);

    // Purchases started on the App Store product page arrive here, possibly
    // before the products are loaded; they wait for them in [_onPromoted].
    _promotedSub = _service.promotedPurchases().listen(_onPromoted);

    try {
      final available = await _service.isAvailable();
      state = state.copyWith(storeAvailable: available);
      if (!available) return;

      final response =
          await _service.queryProducts(FilterCollection.storeProductIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
      }
      final byId = {for (final p in response.productDetails) p.id: p};
      ProductDetails? pick(Iterable<String> ids) =>
          ids.map((id) => byId[id]).nonNulls.firstOrNull;
      final products = <FilterCollection, ProductDetails>{
        for (final c in FilterCollection.values)
          c: ?pick(c.candidateProductIds),
      };
      final bundleTiers = <int, ProductDetails>{
        for (final tier in FilterCollection.bundleLadder)
          tier.threshold: ?pick(FilterCollection.bundleCandidates(tier)),
      };
      state = state.copyWith(products: products, bundleTiers: bundleTiers);
    } catch (e) {
      debugPrint('IAP init failed: $e');
      state = state.copyWith(storeAvailable: false);
    } finally {
      if (!_productsLoaded.isCompleted) _productsLoaded.complete();
    }

    await _migrateFromHistory();
  }

  /// Unlocks collections found in the store's transaction history. Covers the
  /// App Store consumables sold up to 2.3.x, which Restore Purchases never
  /// returns, after a reinstall or on a new device.
  Future<void> _migrateFromHistory() async {
    final paid = FilterCollection.values.where((c) => c.isPaid);
    if (paid.every(state.owned.contains)) return;
    for (final id in await _service.purchasedProductIds()) {
      _grant(id);
    }
  }

  Future<void> _onPromoted(String productId) async {
    await _productsLoaded.future;
    // Any bundle tier is accepted: the customer chose that product on the
    // App Store page, so it is sold as chosen.
    final ProductDetails? product =
        FilterCollection.bundleGrantingIds.contains(productId)
            ? state.bundleTiers.values
                .where((p) => p.id == productId)
                .firstOrNull
            : state.products[FilterCollection.byProductId(productId)];
    if (product == null) {
      debugPrint('Promoted purchase for unknown product $productId');
      return;
    }
    // Already owned: nothing to sell, the unlock listener still opens it.
    if (FilterCollection.grantedBy(productId).every(state.owned.contains)) {
      return;
    }
    await _buyProduct(product);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(purchasePending: true, clearError: true);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_verify(purchase)) _grant(purchase.productID);
          state = state.copyWith(purchasePending: false, clearError: true);
        case PurchaseStatus.error:
          // Empty = no store-provided message; the UI shows a localized
          // generic "Purchase failed" instead.
          final message = purchase.error?.message ?? '';
          // Android reports user cancellation as an error — stay silent then.
          final cancelled = message.toLowerCase().contains('cancel');
          state = state.copyWith(
            purchasePending: false,
            error: cancelled ? null : message,
            clearError: cancelled,
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(purchasePending: false, clearError: true);
      }
      // Mandatory: unfinished transactions are re-delivered forever on iOS
      // and auto-refunded after 3 days on Play.
      if (purchase.pendingCompletePurchase) {
        try {
          await _service.completePurchase(purchase);
        } catch (e) {
          debugPrint('completePurchase failed: $e');
        }
      }
    }
  }

  /// Local-only verification: the app has no backend, so we check the product
  /// is ours and the store attached signed verification data. Accepted risk:
  /// a patched device can forge this; refunds are never revoked.
  bool _verify(PurchaseDetails purchase) =>
      FilterCollection.grantedBy(purchase.productID).isNotEmpty &&
      purchase.verificationData.serverVerificationData.isNotEmpty;

  void _grant(String productId) {
    final granted = FilterCollection.grantedBy(productId);
    if (granted.isEmpty || granted.every(state.owned.contains)) return;
    final owned = {...state.owned, ...granted};
    state = state.copyWith(owned: owned);
    _prefs.setStringList(_prefsKey, owned.map((c) => c.name).toList());
  }

  Future<void> buy(FilterCollection collection) async {
    final product = state.products[collection];
    if (product == null) return;
    await _buyProduct(product);
  }

  /// Buys the offered "All filters" tier, when the store sells one.
  Future<void> buyBundle() async {
    final product = state.bundle;
    if (product == null) return;
    await _buyProduct(product);
  }

  Future<void> _buyProduct(ProductDetails product) async {
    if (state.purchasePending) return;
    state = state.copyWith(purchasePending: true, clearError: true);
    try {
      await _service.buyNonConsumable(product);
    } catch (e) {
      // buyNonConsumable can throw synchronously (e.g. purchase in progress).
      state = state.copyWith(purchasePending: false, error: e.toString());
    }
  }

  /// User-initiated only — an automatic restore at startup could pop an App
  /// Store sign-in dialog; the SharedPreferences cache covers normal starts.
  Future<void> restore() async {
    if (state.purchasePending) return;
    state = state.copyWith(purchasePending: true, clearError: true);
    try {
      await _service.restorePurchases();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      // Restored items (if any) arrive via the stream; the call returning
      // just means the request was submitted.
      state = state.copyWith(purchasePending: false);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _sub?.cancel();
    _promotedSub?.cancel();
    super.dispose();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Overridden in main() with the preloaded instance so cached entitlements
/// are available synchronously on first build.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('overridden in main'),
);

final purchaseServiceProvider = Provider<PurchaseService>(
  (_) => PurchaseService(),
);

// Not autoDispose: entitlements are app-lifetime and the purchase stream
// subscription must survive screen rebuilds.
final entitlementProvider =
    StateNotifierProvider<EntitlementController, EntitlementState>(
  (ref) => EntitlementController(
    ref.watch(purchaseServiceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);
