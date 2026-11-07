import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/mirror_filter.dart';
import '../../services/purchase_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

class EntitlementState {
  /// Paid collections the user owns. Free collections are never stored here —
  /// [owns] treats them as always owned.
  final Set<FilterCollection> owned;

  /// Store metadata for paid collections, for price display on the paywall.
  final Map<FilterCollection, ProductDetails> products;

  /// The optional "All filters" bundle; null when the store does not sell it.
  final ProductDetails? bundle;

  /// False on desktop platforms and when the store is unreachable.
  final bool storeAvailable;

  /// A buy or restore call is in flight.
  final bool purchasePending;

  /// Last user-facing purchase error, null when none.
  final String? error;

  const EntitlementState({
    this.owned = const {},
    this.products = const {},
    this.bundle,
    this.storeAvailable = false,
    this.purchasePending = false,
    this.error,
  });

  bool owns(FilterCollection c) => !c.isPaid || owned.contains(c);

  EntitlementState copyWith({
    Set<FilterCollection>? owned,
    Map<FilterCollection, ProductDetails>? products,
    ProductDetails? bundle,
    bool? storeAvailable,
    bool? purchasePending,
    String? error,
    bool clearError = false,
  }) {
    return EntitlementState(
      owned: owned ?? this.owned,
      products: products ?? this.products,
      bundle: bundle ?? this.bundle,
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
      ProductDetails? bundle;
      final products = <FilterCollection, ProductDetails>{};
      for (final p in response.productDetails) {
        if (p.id == FilterCollection.bundleProductId) {
          bundle = p;
        } else if (FilterCollection.byProductId(p.id) case final c?) {
          products[c] = p;
        }
      }
      state = state.copyWith(products: products, bundle: bundle);
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
    final ProductDetails? product = productId == state.bundle?.id
        ? state.bundle
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

  /// Buys the "All filters" bundle, when the store sells it.
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
