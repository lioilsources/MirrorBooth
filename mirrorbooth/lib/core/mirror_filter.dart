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

  /// Store product ID (identical on App Store and Play), null for free
  /// collections.
  String? get productId => switch (this) {
        FilterCollection.art => 'com.ol1n.mirrorbooth.collection.art',
        FilterCollection.fantasy => 'com.ol1n.mirrorbooth.collection.fantasy',
        _ => null,
      };

  /// Reverse lookup for purchase-stream events.
  static FilterCollection? byProductId(String id) {
    for (final c in values) {
      if (c.productId == id) return c;
    }
    return null;
  }
}

enum MirrorFilter {
  none,
  // Pretty
  glow,
  slim,
  doll,
  chibi,
  lips,
  // Ugly
  bigNose,
  alien,
  melt,
  bigEars,
  longNeck,
  // Art
  pencil,
  comic,
  glitch,
  neon,
  thermal,
  oil,
  crt,
  popArt,
  // Fantasy
  vampire,
  zombie,
  ghost,
  demon,
  cyborg,
  frozen;

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
      };

  bool get needsTime => switch (this) {
        MirrorFilter.melt => true,
        MirrorFilter.glitch => true,
        MirrorFilter.neon => true,
        MirrorFilter.ghost => true,
        MirrorFilter.demon => true,
        MirrorFilter.cyborg => true,
        MirrorFilter.frozen => true,
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
        _ => false,
      };

  // Deliberately no wildcard branch: collections decide free vs paid, so a
  // new filter must be assigned here consciously (compile error otherwise)
  // instead of silently landing in a paid collection.
  FilterCollection? get collection => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.glow ||
        MirrorFilter.slim ||
        MirrorFilter.doll ||
        MirrorFilter.chibi ||
        MirrorFilter.lips =>
          FilterCollection.pretty,
        MirrorFilter.bigNose ||
        MirrorFilter.alien ||
        MirrorFilter.melt ||
        MirrorFilter.bigEars ||
        MirrorFilter.longNeck =>
          FilterCollection.ugly,
        MirrorFilter.pencil ||
        MirrorFilter.comic ||
        MirrorFilter.glitch ||
        MirrorFilter.neon ||
        MirrorFilter.thermal ||
        MirrorFilter.oil ||
        MirrorFilter.crt ||
        MirrorFilter.popArt =>
          FilterCollection.art,
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
      };
}
