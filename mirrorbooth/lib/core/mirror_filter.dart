import 'package:flutter/foundation.dart';

enum FilterCollection {
  pretty('Pretty'),
  ugly('Ugly'),
  art('Art'),
  fantasy('Fantasy'),

  /// Freshly generated shaders (ShaderGen UC2 on L40S) for live QA. Free;
  /// shown in debug/profile and in builds made with --dart-define=MB_LAB=true
  /// (TestFlight lab builds), hidden in store releases.
  experimental('Lab');

  const FilterCollection(this.label);

  final String label;

  static const _labBuild = bool.fromEnvironment('MB_LAB');

  bool get isVisible =>
      this != FilterCollection.experimental || !kReleaseMode || _labBuild;

  static List<FilterCollection> get visible =>
      values.where((c) => c.isVisible).toList();

  /// Lab holds many raw candidates; the strip pages them in groups this big.
  static const labGroupSize = 10;

  /// Paid collections are sold as non-consumable in-app purchases; free ones
  /// are always available. Locked filters still preview live — the paywall
  /// only gates saving photos/videos.
  bool get isPaid => switch (this) {
        FilterCollection.pretty ||
        FilterCollection.ugly ||
        FilterCollection.experimental =>
          false,
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
  // Experimental (Lab): UC2 MAP-Elites archive, numbered for review
  c1918,
  c0874,
  c0626,
  c0842,
  c1035,
  c1856,
  c1182,
  c1400,
  c1642,
  c1938,
  c1931,
  c0735,
  c1367,
  c1422,
  c0988,
  c1011,
  c1703,
  c0012,
  c1304,
  c1787,
  c1348,
  c1062,
  // Lab 23-52: outliers of the UC2 population (motion, distortion, lineage)
  c1206,
  c1632,
  c1504,
  c0044,
  c1131,
  c0108,
  c0253,
  c1058,
  c1091,
  c1861,
  c0191,
  c0242,
  c1601,
  c1086,
  c1247,
  c0094,
  c1485,
  c0008,
  c0297,
  c0098,
  c1409,
  c0026,
  c1357,
  c0324,
  c0118,
  c1470,
  c1192,
  c0825,
  c0841,
  c0035,
  // @shadergen:enum:experimental
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
        MirrorFilter.c1918 => '01 c1918',
        MirrorFilter.c0874 => '02 c0874',
        MirrorFilter.c0626 => '03 c0626',
        MirrorFilter.c0842 => '04 c0842',
        MirrorFilter.c1035 => '05 c1035',
        MirrorFilter.c1856 => '06 c1856',
        MirrorFilter.c1182 => '07 c1182',
        MirrorFilter.c1400 => '08 c1400',
        MirrorFilter.c1642 => '09 c1642',
        MirrorFilter.c1938 => '10 c1938',
        MirrorFilter.c1931 => '11 c1931',
        MirrorFilter.c0735 => '12 c0735',
        MirrorFilter.c1367 => '13 c1367',
        MirrorFilter.c1422 => '14 c1422',
        MirrorFilter.c0988 => '15 c0988',
        MirrorFilter.c1011 => '16 c1011',
        MirrorFilter.c1703 => '17 c1703',
        MirrorFilter.c0012 => '18 c0012',
        MirrorFilter.c1304 => '19 c1304',
        MirrorFilter.c1787 => '20 c1787',
        MirrorFilter.c1348 => '21 c1348',
        MirrorFilter.c1062 => '22 c1062',
        MirrorFilter.c1206 => '23 c1206',
        MirrorFilter.c1632 => '24 c1632',
        MirrorFilter.c1504 => '25 c1504',
        MirrorFilter.c0044 => '26 c0044',
        MirrorFilter.c1131 => '27 c1131',
        MirrorFilter.c0108 => '28 c0108',
        MirrorFilter.c0253 => '29 c0253',
        MirrorFilter.c1058 => '30 c1058',
        MirrorFilter.c1091 => '31 c1091',
        MirrorFilter.c1861 => '32 c1861',
        MirrorFilter.c0191 => '33 c0191',
        MirrorFilter.c0242 => '34 c0242',
        MirrorFilter.c1601 => '35 c1601',
        MirrorFilter.c1086 => '36 c1086',
        MirrorFilter.c1247 => '37 c1247',
        MirrorFilter.c0094 => '38 c0094',
        MirrorFilter.c1485 => '39 c1485',
        MirrorFilter.c0008 => '40 c0008',
        MirrorFilter.c0297 => '41 c0297',
        MirrorFilter.c0098 => '42 c0098',
        MirrorFilter.c1409 => '43 c1409',
        MirrorFilter.c0026 => '44 c0026',
        MirrorFilter.c1357 => '45 c1357',
        MirrorFilter.c0324 => '46 c0324',
        MirrorFilter.c0118 => '47 c0118',
        MirrorFilter.c1470 => '48 c1470',
        MirrorFilter.c1192 => '49 c1192',
        MirrorFilter.c0825 => '50 c0825',
        MirrorFilter.c0841 => '51 c0841',
        MirrorFilter.c0035 => '52 c0035',
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
        MirrorFilter.c1918 => '◈',
        MirrorFilter.c0874 => '◈',
        MirrorFilter.c0626 => '◈',
        MirrorFilter.c0842 => '◈',
        MirrorFilter.c1035 => '◈',
        MirrorFilter.c1856 => '◈',
        MirrorFilter.c1182 => '◈',
        MirrorFilter.c1400 => '◈',
        MirrorFilter.c1642 => '◈',
        MirrorFilter.c1938 => '◈',
        MirrorFilter.c1931 => '◈',
        MirrorFilter.c0735 => '◈',
        MirrorFilter.c1367 => '◈',
        MirrorFilter.c1422 => '◈',
        MirrorFilter.c0988 => '◈',
        MirrorFilter.c1011 => '◈',
        MirrorFilter.c1703 => '◈',
        MirrorFilter.c0012 => '◈',
        MirrorFilter.c1304 => '◈',
        MirrorFilter.c1787 => '◈',
        MirrorFilter.c1348 => '◈',
        MirrorFilter.c1062 => '◈',
        MirrorFilter.c1206 => '◆',
        MirrorFilter.c1632 => '◆',
        MirrorFilter.c1504 => '◆',
        MirrorFilter.c0044 => '◆',
        MirrorFilter.c1131 => '◆',
        MirrorFilter.c0108 => '◆',
        MirrorFilter.c0253 => '◆',
        MirrorFilter.c1058 => '◆',
        MirrorFilter.c1091 => '◆',
        MirrorFilter.c1861 => '◆',
        MirrorFilter.c0191 => '◆',
        MirrorFilter.c0242 => '◆',
        MirrorFilter.c1601 => '◆',
        MirrorFilter.c1086 => '◆',
        MirrorFilter.c1247 => '◆',
        MirrorFilter.c0094 => '◆',
        MirrorFilter.c1485 => '◆',
        MirrorFilter.c0008 => '◆',
        MirrorFilter.c0297 => '◆',
        MirrorFilter.c0098 => '◆',
        MirrorFilter.c1409 => '◆',
        MirrorFilter.c0026 => '◆',
        MirrorFilter.c1357 => '◆',
        MirrorFilter.c0324 => '◆',
        MirrorFilter.c0118 => '◆',
        MirrorFilter.c1470 => '◆',
        MirrorFilter.c1192 => '◆',
        MirrorFilter.c0825 => '◆',
        MirrorFilter.c0841 => '◆',
        MirrorFilter.c0035 => '◆',
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
        MirrorFilter.c1918 => true,
        MirrorFilter.c0874 => true,
        MirrorFilter.c0626 => true,
        MirrorFilter.c0842 => true,
        MirrorFilter.c1035 => true,
        MirrorFilter.c1856 => true,
        MirrorFilter.c1182 => true,
        MirrorFilter.c1400 => true,
        MirrorFilter.c1642 => true,
        MirrorFilter.c1938 => true,
        MirrorFilter.c1931 => true,
        MirrorFilter.c0735 => true,
        MirrorFilter.c1367 => true,
        MirrorFilter.c1422 => true,
        MirrorFilter.c0988 => true,
        MirrorFilter.c1011 => true,
        MirrorFilter.c1703 => true,
        MirrorFilter.c0012 => true,
        MirrorFilter.c1304 => true,
        MirrorFilter.c1787 => true,
        MirrorFilter.c1348 => true,
        MirrorFilter.c1062 => true,
        MirrorFilter.c1206 => true,
        MirrorFilter.c1632 => true,
        MirrorFilter.c1504 => true,
        MirrorFilter.c0044 => true,
        MirrorFilter.c1131 => true,
        MirrorFilter.c0108 => true,
        MirrorFilter.c0253 => true,
        MirrorFilter.c1058 => true,
        MirrorFilter.c1091 => true,
        MirrorFilter.c1861 => true,
        MirrorFilter.c0191 => true,
        MirrorFilter.c0242 => true,
        MirrorFilter.c1601 => true,
        MirrorFilter.c1086 => true,
        MirrorFilter.c1247 => true,
        MirrorFilter.c0094 => true,
        MirrorFilter.c1485 => true,
        MirrorFilter.c0008 => true,
        MirrorFilter.c0297 => true,
        MirrorFilter.c0098 => true,
        MirrorFilter.c1409 => true,
        MirrorFilter.c0026 => true,
        MirrorFilter.c1357 => true,
        MirrorFilter.c0324 => true,
        MirrorFilter.c0118 => true,
        MirrorFilter.c1470 => true,
        MirrorFilter.c1192 => true,
        MirrorFilter.c0825 => true,
        MirrorFilter.c0841 => true,
        MirrorFilter.c0035 => true,
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
        MirrorFilter.c1918 => true,
        MirrorFilter.c0874 => true,
        MirrorFilter.c0626 => true,
        MirrorFilter.c0842 => true,
        MirrorFilter.c1035 => true,
        MirrorFilter.c1856 => true,
        MirrorFilter.c1182 => true,
        MirrorFilter.c1400 => true,
        MirrorFilter.c1642 => true,
        MirrorFilter.c1938 => true,
        MirrorFilter.c1931 => true,
        MirrorFilter.c0735 => true,
        MirrorFilter.c1367 => true,
        MirrorFilter.c1422 => true,
        MirrorFilter.c0988 => true,
        MirrorFilter.c1011 => true,
        MirrorFilter.c1703 => true,
        MirrorFilter.c1787 => true,
        MirrorFilter.c1348 => true,
        MirrorFilter.c1062 => true,
        MirrorFilter.c1206 => true,
        MirrorFilter.c1632 => true,
        MirrorFilter.c1504 => true,
        MirrorFilter.c0044 => true,
        MirrorFilter.c1131 => true,
        MirrorFilter.c0253 => true,
        MirrorFilter.c1058 => true,
        MirrorFilter.c1091 => true,
        MirrorFilter.c1861 => true,
        MirrorFilter.c0191 => true,
        MirrorFilter.c1601 => true,
        MirrorFilter.c1086 => true,
        MirrorFilter.c1247 => true,
        MirrorFilter.c1485 => true,
        MirrorFilter.c0008 => true,
        MirrorFilter.c0098 => true,
        MirrorFilter.c1409 => true,
        MirrorFilter.c1357 => true,
        MirrorFilter.c0324 => true,
        MirrorFilter.c0118 => true,
        MirrorFilter.c1470 => true,
        MirrorFilter.c1192 => true,
        MirrorFilter.c0825 => true,
        MirrorFilter.c0841 => true,
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
        // @shadergen:collection:experimental
        MirrorFilter.c0035 ||
        MirrorFilter.c0841 ||
        MirrorFilter.c0825 ||
        MirrorFilter.c1192 ||
        MirrorFilter.c1470 ||
        MirrorFilter.c0118 ||
        MirrorFilter.c0324 ||
        MirrorFilter.c1357 ||
        MirrorFilter.c0026 ||
        MirrorFilter.c1409 ||
        MirrorFilter.c0098 ||
        MirrorFilter.c0297 ||
        MirrorFilter.c0008 ||
        MirrorFilter.c1485 ||
        MirrorFilter.c0094 ||
        MirrorFilter.c1247 ||
        MirrorFilter.c1086 ||
        MirrorFilter.c1601 ||
        MirrorFilter.c0242 ||
        MirrorFilter.c0191 ||
        MirrorFilter.c1861 ||
        MirrorFilter.c1091 ||
        MirrorFilter.c1058 ||
        MirrorFilter.c0253 ||
        MirrorFilter.c0108 ||
        MirrorFilter.c1131 ||
        MirrorFilter.c0044 ||
        MirrorFilter.c1504 ||
        MirrorFilter.c1632 ||
        MirrorFilter.c1206 ||
        MirrorFilter.c1348 ||
        MirrorFilter.c1787 ||
        MirrorFilter.c1304 ||
        MirrorFilter.c0012 ||
        MirrorFilter.c1703 ||
        MirrorFilter.c1011 ||
        MirrorFilter.c0988 ||
        MirrorFilter.c1422 ||
        MirrorFilter.c1367 ||
        MirrorFilter.c0735 ||
        MirrorFilter.c1931 ||
        MirrorFilter.c1938 ||
        MirrorFilter.c1642 ||
        MirrorFilter.c1400 ||
        MirrorFilter.c1182 ||
        MirrorFilter.c1856 ||
        MirrorFilter.c1035 ||
        MirrorFilter.c0842 ||
        MirrorFilter.c0626 ||
        MirrorFilter.c0874 ||
        MirrorFilter.c1918 ||
        MirrorFilter.c1062 =>
          FilterCollection.experimental,
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
        MirrorFilter.c1918 => 'shaders/filter_c1918.frag',
        MirrorFilter.c0874 => 'shaders/filter_c0874.frag',
        MirrorFilter.c0626 => 'shaders/filter_c0626.frag',
        MirrorFilter.c0842 => 'shaders/filter_c0842.frag',
        MirrorFilter.c1035 => 'shaders/filter_c1035.frag',
        MirrorFilter.c1856 => 'shaders/filter_c1856.frag',
        MirrorFilter.c1182 => 'shaders/filter_c1182.frag',
        MirrorFilter.c1400 => 'shaders/filter_c1400.frag',
        MirrorFilter.c1642 => 'shaders/filter_c1642.frag',
        MirrorFilter.c1938 => 'shaders/filter_c1938.frag',
        MirrorFilter.c1931 => 'shaders/filter_c1931.frag',
        MirrorFilter.c0735 => 'shaders/filter_c0735.frag',
        MirrorFilter.c1367 => 'shaders/filter_c1367.frag',
        MirrorFilter.c1422 => 'shaders/filter_c1422.frag',
        MirrorFilter.c0988 => 'shaders/filter_c0988.frag',
        MirrorFilter.c1011 => 'shaders/filter_c1011.frag',
        MirrorFilter.c1703 => 'shaders/filter_c1703.frag',
        MirrorFilter.c0012 => 'shaders/filter_c0012.frag',
        MirrorFilter.c1304 => 'shaders/filter_c1304.frag',
        MirrorFilter.c1787 => 'shaders/filter_c1787.frag',
        MirrorFilter.c1348 => 'shaders/filter_c1348.frag',
        MirrorFilter.c1062 => 'shaders/filter_c1062.frag',
        MirrorFilter.c1206 => 'shaders/filter_c1206.frag',
        MirrorFilter.c1632 => 'shaders/filter_c1632.frag',
        MirrorFilter.c1504 => 'shaders/filter_c1504.frag',
        MirrorFilter.c0044 => 'shaders/filter_c0044.frag',
        MirrorFilter.c1131 => 'shaders/filter_c1131.frag',
        MirrorFilter.c0108 => 'shaders/filter_c0108.frag',
        MirrorFilter.c0253 => 'shaders/filter_c0253.frag',
        MirrorFilter.c1058 => 'shaders/filter_c1058.frag',
        MirrorFilter.c1091 => 'shaders/filter_c1091.frag',
        MirrorFilter.c1861 => 'shaders/filter_c1861.frag',
        MirrorFilter.c0191 => 'shaders/filter_c0191.frag',
        MirrorFilter.c0242 => 'shaders/filter_c0242.frag',
        MirrorFilter.c1601 => 'shaders/filter_c1601.frag',
        MirrorFilter.c1086 => 'shaders/filter_c1086.frag',
        MirrorFilter.c1247 => 'shaders/filter_c1247.frag',
        MirrorFilter.c0094 => 'shaders/filter_c0094.frag',
        MirrorFilter.c1485 => 'shaders/filter_c1485.frag',
        MirrorFilter.c0008 => 'shaders/filter_c0008.frag',
        MirrorFilter.c0297 => 'shaders/filter_c0297.frag',
        MirrorFilter.c0098 => 'shaders/filter_c0098.frag',
        MirrorFilter.c1409 => 'shaders/filter_c1409.frag',
        MirrorFilter.c0026 => 'shaders/filter_c0026.frag',
        MirrorFilter.c1357 => 'shaders/filter_c1357.frag',
        MirrorFilter.c0324 => 'shaders/filter_c0324.frag',
        MirrorFilter.c0118 => 'shaders/filter_c0118.frag',
        MirrorFilter.c1470 => 'shaders/filter_c1470.frag',
        MirrorFilter.c1192 => 'shaders/filter_c1192.frag',
        MirrorFilter.c0825 => 'shaders/filter_c0825.frag',
        MirrorFilter.c0841 => 'shaders/filter_c0841.frag',
        MirrorFilter.c0035 => 'shaders/filter_c0035.frag',
        // @shadergen:shaderAsset
      };
}
