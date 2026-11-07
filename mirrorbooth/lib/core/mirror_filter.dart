import 'package:flutter/foundation.dart';

enum FilterCollection {
  pretty('Pretty'),
  ugly('Ugly'),
  art('Art'),
  fantasy('Fantasy');

  const FilterCollection(this.label);

  final String label;

  /// Paid collections are sold as non-consumable in-app purchases; free ones
  /// are always available. Locked filters still preview live — the paywall
  /// only gates saving photos/videos.
  bool get isPaid => switch (this) {
        FilterCollection.pretty || FilterCollection.ugly => false,
        FilterCollection.art || FilterCollection.fantasy => true,
      };

  /// Preferred store product ID, null for free collections: the
  /// non-consumable `*_unlock` item. The original IDs were created on the
  /// App Store as consumables, which Restore Purchases cannot bring back,
  /// and Apple allows neither changing the type nor reusing an ID.
  String? get productId => switch (this) {
        FilterCollection.art => 'com.ol1n.mirrorbooth.collection.art_unlock',
        FilterCollection.fantasy =>
          'com.ol1n.mirrorbooth.collection.fantasy_unlock',
        _ => null,
      };

  /// Product IDs the store is asked for, in order of preference; the first
  /// one the store returns is sold. The App Store only sells `*_unlock`.
  /// Play also falls back to the original IDs while they are still the
  /// ones set up there (Play has no consumable type at product level).
  List<String> get candidateProductIds => [
        ?productId,
        if (!_apple) ...grantingIds.difference({productId}),
      ];

  /// Every product ID that has ever granted this collection on any platform,
  /// including the App Store consumables sold up to 2.3.4.
  Set<String> get grantingIds => switch (this) {
        FilterCollection.art => const {
            'com.ol1n.mirrorbooth.collection.art',
            'com.ol1n.mirrorbooth.collection.art_unlock',
          },
        FilterCollection.fantasy => const {
            'com.ol1n.mirrorbooth.collection.fantasy',
            'com.ol1n.mirrorbooth.collection.fantasy_unlock',
          },
        _ => const {},
      };

  /// The "All filters" bundle: one purchase that unlocks every paid
  /// collection. Optional: the paywall offers it only when the store returns
  /// one of these products (same preference as [candidateProductIds]).
  static List<String> get bundleProductIds => [
        'com.ol1n.mirrorbooth.collection.all_unlock',
        if (!_apple) 'com.ol1n.mirrorbooth.collection.all',
      ];

  /// Every product ID this platform asks the store for, bundle included.
  static Set<String> get storeProductIds => {
        for (final c in values) ...c.candidateProductIds,
        ...bundleProductIds,
      };

  /// Reverse lookup for a single-collection product (current or legacy).
  static FilterCollection? byProductId(String id) {
    for (final c in values) {
      if (c.grantingIds.contains(id)) return c;
    }
    return null;
  }

  /// Collections a purchase of [id] unlocks; empty for unknown products.
  static Set<FilterCollection> grantedBy(String id) {
    if (const {
      'com.ol1n.mirrorbooth.collection.all',
      'com.ol1n.mirrorbooth.collection.all_unlock',
    }.contains(id)) {
      return values.where((c) => c.isPaid).toSet();
    }
    final c = byProductId(id);
    return c == null ? const {} : {c};
  }

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

// `// @shadergen:*` markers are insertion points for pipeline/integrate.py
// (ShaderGen). Keep them; they do not change behaviour.
enum MirrorFilter {
  none,
  // Pretty
  glow,
  slim,
  doll,
  chibi,
  lips,
  // @shadergen:enum:pretty
  // Ugly
  bigNose,
  alien,
  melt,
  bigEars,
  longNeck,
  // @shadergen:enum:ugly
  // Art
  pencil,
  comic,
  glitch,
  neon,
  thermal,
  oil,
  crt,
  popArt,
  // @shadergen:enum:art
  // Fantasy
  vampire,
  zombie,
  ghost,
  demon,
  cyborg,
  frozen,
  // @shadergen:enum:fantasy
  ;

  String get label => switch (this) {
        MirrorFilter.none => 'None',
        MirrorFilter.glow => 'Glow',
        MirrorFilter.slim => 'Slim',
        MirrorFilter.doll => 'Doll',
        MirrorFilter.chibi => 'Chibi',
        MirrorFilter.lips => 'Lips',
        MirrorFilter.bigNose => 'Nose',
        MirrorFilter.alien => 'Alien',
        MirrorFilter.melt => 'Melt',
        MirrorFilter.bigEars => 'Ears',
        MirrorFilter.longNeck => 'Neck',
        MirrorFilter.pencil => 'Pencil',
        MirrorFilter.comic => 'Comic',
        MirrorFilter.glitch => 'Glitch',
        MirrorFilter.neon => 'Neon',
        MirrorFilter.thermal => 'Heat',
        MirrorFilter.oil => 'Oil',
        MirrorFilter.crt => 'CRT',
        MirrorFilter.popArt => 'Pop',
        MirrorFilter.vampire => 'Vamp',
        MirrorFilter.zombie => 'Zombie',
        MirrorFilter.ghost => 'Ghost',
        MirrorFilter.demon => 'Demon',
        MirrorFilter.cyborg => 'Cyborg',
        MirrorFilter.frozen => 'Frost',
        // @shadergen:label
      };

  String get icon => switch (this) {
        MirrorFilter.none => 'O',
        MirrorFilter.glow => '✧',
        MirrorFilter.slim => '|',
        MirrorFilter.doll => '◉',
        MirrorFilter.chibi => '◕',
        MirrorFilter.lips => 'ω',
        MirrorFilter.bigNose => '▲',
        MirrorFilter.alien => 'Λ',
        MirrorFilter.melt => '≈',
        MirrorFilter.bigEars => '◖',
        MirrorFilter.longNeck => 'Y',
        MirrorFilter.pencil => '/',
        MirrorFilter.comic => '!',
        MirrorFilter.glitch => '~',
        MirrorFilter.neon => 'N',
        MirrorFilter.thermal => 'T',
        MirrorFilter.oil => 'Q',
        MirrorFilter.crt => 'V',
        MirrorFilter.popArt => '●',
        MirrorFilter.vampire => '†',
        MirrorFilter.zombie => 'Ж',
        MirrorFilter.ghost => '◌',
        MirrorFilter.demon => 'Ψ',
        MirrorFilter.cyborg => '▣',
        MirrorFilter.frozen => '❆',
        // @shadergen:icon
      };

  bool get needsTime => switch (this) {
        MirrorFilter.melt => true,
        MirrorFilter.glitch => true,
        MirrorFilter.neon => true,
        MirrorFilter.ghost => true,
        MirrorFilter.demon => true,
        MirrorFilter.cyborg => true,
        MirrorFilter.frozen => true,
        // @shadergen:needsTime
        _ => false,
      };

  /// Whether the shader declares uFaceCenter/uFaceScale uniforms. Today they
  /// receive constant defaults (mirror axis premise: face centered on the
  /// canvas); a face detector can feed real coordinates later.
  bool get needsFace => switch (this) {
        MirrorFilter.slim => true,
        MirrorFilter.doll => true,
        MirrorFilter.chibi => true,
        MirrorFilter.lips => true,
        MirrorFilter.bigNose => true,
        MirrorFilter.alien => true,
        MirrorFilter.bigEars => true,
        MirrorFilter.longNeck => true,
        MirrorFilter.vampire => true,
        MirrorFilter.zombie => true,
        MirrorFilter.demon => true,
        // @shadergen:needsFace
        _ => false,
      };

  // Deliberately no wildcard branch: collections decide free vs paid, so a
  // new filter must be assigned here consciously (compile error otherwise)
  // instead of silently landing in a paid collection.
  FilterCollection? get collection => switch (this) {
        MirrorFilter.none => null,
        // @shadergen:collection:pretty
        MirrorFilter.glow ||
        MirrorFilter.slim ||
        MirrorFilter.doll ||
        MirrorFilter.chibi ||
        MirrorFilter.lips =>
          FilterCollection.pretty,
        // @shadergen:collection:ugly
        MirrorFilter.bigNose ||
        MirrorFilter.alien ||
        MirrorFilter.melt ||
        MirrorFilter.bigEars ||
        MirrorFilter.longNeck =>
          FilterCollection.ugly,
        // @shadergen:collection:art
        MirrorFilter.pencil ||
        MirrorFilter.comic ||
        MirrorFilter.glitch ||
        MirrorFilter.neon ||
        MirrorFilter.thermal ||
        MirrorFilter.oil ||
        MirrorFilter.crt ||
        MirrorFilter.popArt =>
          FilterCollection.art,
        // @shadergen:collection:fantasy
        MirrorFilter.vampire ||
        MirrorFilter.zombie ||
        MirrorFilter.ghost ||
        MirrorFilter.demon ||
        MirrorFilter.cyborg ||
        MirrorFilter.frozen =>
          FilterCollection.fantasy,
      };

  static List<MirrorFilter> inCollection(FilterCollection c) =>
      values.where((f) => f.collection == c).toList();

  String? get shaderAsset => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.glow => 'shaders/filter_glow.frag',
        MirrorFilter.slim => 'shaders/filter_slim.frag',
        MirrorFilter.doll => 'shaders/filter_doll.frag',
        MirrorFilter.chibi => 'shaders/filter_chibi.frag',
        MirrorFilter.lips => 'shaders/filter_lips.frag',
        MirrorFilter.bigNose => 'shaders/filter_big_nose.frag',
        MirrorFilter.alien => 'shaders/filter_alien.frag',
        MirrorFilter.melt => 'shaders/filter_melt.frag',
        MirrorFilter.bigEars => 'shaders/filter_big_ears.frag',
        MirrorFilter.longNeck => 'shaders/filter_long_neck.frag',
        MirrorFilter.pencil => 'shaders/filter_pencil.frag',
        MirrorFilter.comic => 'shaders/filter_comic.frag',
        MirrorFilter.glitch => 'shaders/filter_glitch.frag',
        MirrorFilter.neon => 'shaders/filter_neon.frag',
        MirrorFilter.thermal => 'shaders/filter_thermal.frag',
        MirrorFilter.oil => 'shaders/filter_oil.frag',
        MirrorFilter.crt => 'shaders/filter_crt.frag',
        MirrorFilter.popArt => 'shaders/filter_pop_art.frag',
        MirrorFilter.vampire => 'shaders/filter_vampire.frag',
        MirrorFilter.zombie => 'shaders/filter_zombie.frag',
        MirrorFilter.ghost => 'shaders/filter_ghost.frag',
        MirrorFilter.demon => 'shaders/filter_demon.frag',
        MirrorFilter.cyborg => 'shaders/filter_cyborg.frag',
        MirrorFilter.frozen => 'shaders/filter_frozen.frag',
        // @shadergen:shaderAsset
      };
}
