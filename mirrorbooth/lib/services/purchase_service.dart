import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Thin delegation wrapper over the store plugin so the entitlement
/// controller can be unit-tested with a fake. Keep this the only file that
/// imports `in_app_purchase` outside the paywall state layer's types.
class PurchaseService {
  static const _promoted = MethodChannel('mirrorbooth/promoted_purchase');

  Stream<List<PurchaseDetails>> get purchaseStream =>
      InAppPurchase.instance.purchaseStream;

  Future<bool> isAvailable() => InAppPurchase.instance.isAvailable();

  Future<ProductDetailsResponse> queryProducts(Set<String> ids) =>
      InAppPurchase.instance.queryProductDetails(ids);

  Future<void> buyNonConsumable(ProductDetails product) => InAppPurchase
      .instance
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> restorePurchases() => InAppPurchase.instance.restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase) =>
      InAppPurchase.instance.completePurchase(purchase);

  /// Product IDs of every verified transaction in the App Store history
  /// (StoreKit 2 `Transaction.all`). With `SKIncludeConsumableInAppPurchaseHistory`
  /// in Info.plist, iOS 18+ also lists finished consumables, which is how
  /// buyers of the old consumable collections get them back. Never prompts
  /// for sign-in. Empty off iOS or on failure.
  Future<Set<String>> purchasedProductIds() async {
    if (!Platform.isIOS) return const {};
    try {
      final all = await SK2Transaction.transactions();
      return {for (final t in all) t.productId};
    } catch (e) {
      debugPrint('Transaction history unavailable: $e');
      return const {};
    }
  }

  /// Product IDs the user started buying on the App Store product page
  /// (promoted in-app purchases, StoreKit 2 `PurchaseIntent`, iOS 16.4+).
  /// Intents that arrived before Dart was listening are replayed first.
  Stream<String> promotedPurchases() {
    if (!Platform.isIOS) return const Stream.empty();
    final controller = StreamController<String>();
    _promoted.setMethodCallHandler((call) async {
      if (call.method == 'purchaseIntent' && call.arguments is String) {
        controller.add(call.arguments as String);
      }
    });
    _promoted.invokeListMethod<String>('ready').then(
      (pending) => pending?.forEach(controller.add),
      onError: (Object e) => debugPrint('promoted purchases: $e'),
    );
    return controller.stream;
  }
}
