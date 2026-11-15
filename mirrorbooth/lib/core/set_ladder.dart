// Complete-the-set pricing: several store products unlock the same "all"
// bundle, each at a fixed lower price, and the app offers exactly one of them
// depending on how many items the customer already owns. Stores cannot price
// a product per customer, so the discount is a choice between products.
//
// Pure Dart with no imports on purpose: the same file (and its table test) is
// copied verbatim into every Ol1n app that sells an "all" bundle.

/// One step of the ladder: offered once the customer owns at least
/// [threshold] items.
typedef SetTier = ({int threshold, String productId});

/// The product ID to offer to a customer who owns [owned] items, or null when
/// no tier applies (empty ladder, or every threshold above [owned]).
///
/// [tiers] is sorted by ascending threshold. The highest tier whose threshold
/// [owned] meets wins, so owning more than the last threshold keeps offering
/// the last tier: the bundle also covers items added later.
String? offerFromLadder(int owned, List<SetTier> tiers) {
  String? offer;
  for (final tier in tiers) {
    if (tier.threshold > owned) break;
    offer = tier.productId;
  }
  return offer;
}
