import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mirror_filter.dart';
import '../../l10n/l10n.dart';
import 'entitlement_controller.dart';

/// Shows the purchase sheet for a locked [collection]. The barrier stays
/// light so the live filtered camera preview remains visible behind it —
/// the preview is the sales pitch.
Future<void> showPaywallSheet(BuildContext context, FilterCollection collection) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    isScrollControlled: true,
    builder: (_) => _PaywallSheet(collection: collection),
  );
}

class _PaywallSheet extends ConsumerWidget {
  final FilterCollection collection;

  const _PaywallSheet({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entitlementProvider);
    final notifier = ref.read(entitlementProvider.notifier);
    final l10n = context.l10n;
    final collectionName = collection.localizedLabel(l10n);

    // Auto-dismiss once the collection is owned — covers both a direct
    // purchase and a restore that happens to grant this collection.
    ref.listen<EntitlementState>(entitlementProvider, (_, next) {
      if (next.owns(collection) && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.collectionUnlocked(collectionName))),
        );
      }
    });

    final product = state.products[collection];
    final canBuy =
        state.storeAvailable && product != null && !state.purchasePending;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        decoration: BoxDecoration(
          // Nearly opaque: the filter strip sits right behind the sheet and
          // bleeds through anything lighter, hurting legibility.
          color: Colors.black.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.collectionFilters(collectionName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              MirrorFilter.inCollection(collection)
                  .map((f) => '${f.icon} ${f.localizedLabel(l10n)}')
                  .join('   '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.paywallPreviewFree,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            // CTA styled as a scaled-up active filter chip: white pill,
            // black text.
            GestureDetector(
              onTap: canBuy ? () => notifier.buy(collection) : null,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: canBuy ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: state.purchasePending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black54),
                      )
                    : Text(
                        !state.storeAvailable
                            ? l10n.storeUnavailable
                            : product == null
                                ? l10n.loadingPrice
                                : l10n.unlockFor(product.price),
                        style: TextStyle(
                          color: canBuy ? Colors.black : Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.error!.isEmpty ? l10n.purchaseFailed : state.error!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            TextButton(
              onPressed: state.purchasePending ? null : notifier.restore,
              child: Text(
                l10n.restorePurchases,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
