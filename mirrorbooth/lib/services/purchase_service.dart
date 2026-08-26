import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin delegation wrapper over the store plugin so the entitlement
/// controller can be unit-tested with a fake. Keep this the only file that
/// imports `in_app_purchase` outside the paywall state layer's types.
class PurchaseService {
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
}
