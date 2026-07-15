enum FilterCollection {
  pretty('Pretty'),
  ugly('Ugly'),
  art('Art');

  const FilterCollection(this.label);

  final String label;
}

enum MirrorFilter {
  none,
  // Pretty
  glow,
  slim,
  doll,
  // Ugly
  bigNose,
  alien,
  melt,
  // Art
  pencil,
  comic,
  glitch,
  neon,
  thermal,
  oil,
  crt,
  popArt;

  String get label => switch (this) {
        MirrorFilter.none => 'None',
        MirrorFilter.glow => 'Glow',
        MirrorFilter.slim => 'Slim',
        MirrorFilter.doll => 'Doll',
        MirrorFilter.bigNose => 'Nose',
        MirrorFilter.alien => 'Alien',
        MirrorFilter.melt => 'Melt',
        MirrorFilter.pencil => 'Pencil',
        MirrorFilter.comic => 'Comic',
        MirrorFilter.glitch => 'Glitch',
        MirrorFilter.neon => 'Neon',
        MirrorFilter.thermal => 'Heat',
        MirrorFilter.oil => 'Oil',
        MirrorFilter.crt => 'CRT',
        MirrorFilter.popArt => 'Pop',
      };

  String get icon => switch (this) {
        MirrorFilter.none => 'O',
        MirrorFilter.glow => '✧',
        MirrorFilter.slim => '|',
        MirrorFilter.doll => '◉',
        MirrorFilter.bigNose => '▲',
        MirrorFilter.alien => 'Λ',
        MirrorFilter.melt => '≈',
        MirrorFilter.pencil => '/',
        MirrorFilter.comic => '!',
        MirrorFilter.glitch => '~',
        MirrorFilter.neon => 'N',
        MirrorFilter.thermal => 'T',
        MirrorFilter.oil => 'Q',
        MirrorFilter.crt => 'V',
        MirrorFilter.popArt => '●',
      };

  bool get needsTime => switch (this) {
        MirrorFilter.melt => true,
        MirrorFilter.glitch => true,
        MirrorFilter.neon => true,
        _ => false,
      };

  /// Whether the shader declares uFaceCenter/uFaceScale uniforms. Today they
  /// receive constant defaults (mirror axis premise: face centered on the
  /// canvas); a face detector can feed real coordinates later.
  bool get needsFace => switch (this) {
        MirrorFilter.slim => true,
        MirrorFilter.doll => true,
        MirrorFilter.bigNose => true,
        MirrorFilter.alien => true,
        _ => false,
      };

  FilterCollection? get collection => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.glow ||
        MirrorFilter.slim ||
        MirrorFilter.doll =>
          FilterCollection.pretty,
        MirrorFilter.bigNose ||
        MirrorFilter.alien ||
        MirrorFilter.melt =>
          FilterCollection.ugly,
        _ => FilterCollection.art,
      };

  static List<MirrorFilter> inCollection(FilterCollection c) =>
      values.where((f) => f.collection == c).toList();

  String? get shaderAsset => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.glow => 'shaders/filter_glow.frag',
        MirrorFilter.slim => 'shaders/filter_slim.frag',
        MirrorFilter.doll => 'shaders/filter_doll.frag',
        MirrorFilter.bigNose => 'shaders/filter_big_nose.frag',
        MirrorFilter.alien => 'shaders/filter_alien.frag',
        MirrorFilter.melt => 'shaders/filter_melt.frag',
        MirrorFilter.pencil => 'shaders/filter_pencil.frag',
        MirrorFilter.comic => 'shaders/filter_comic.frag',
        MirrorFilter.glitch => 'shaders/filter_glitch.frag',
        MirrorFilter.neon => 'shaders/filter_neon.frag',
        MirrorFilter.thermal => 'shaders/filter_thermal.frag',
        MirrorFilter.oil => 'shaders/filter_oil.frag',
        MirrorFilter.crt => 'shaders/filter_crt.frag',
        MirrorFilter.popArt => 'shaders/filter_pop_art.frag',
      };
}
