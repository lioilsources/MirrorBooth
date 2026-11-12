import 'package:flutter/foundation.dart';

enum FilterCollection {
  pretty('Pretty'),
  ugly('Ugly'),
  art('Art'),
  fantasy('Fantasy'),

  // Packs: one technique family each, $0.99 apiece. The strip shows them
  // as chips under a single Packs tab instead of one tab each.
  mosaic('Mosaic'),
  halftone('Halftone'),
  sketch('Sketch'),
  optics('Optics'),
  kaleido('Kaleido'),
  tiles('Tiles'),
  glitch('Glitch'),
  vhs('VHS'),
  face('Face'),
  layers('Layers'),
  paint('Paint'),
  color('Color'),
  light('Light'),

  /// Freshly generated shaders (ShaderGen) for live QA. Free; shown in
  /// debug/profile and in builds made with --dart-define=MB_LAB=true
  /// (TestFlight lab builds), hidden in store releases and while empty.
  experimental('Lab');

  const FilterCollection(this.label);

  final String label;

  static const _labBuild = bool.fromEnvironment('MB_LAB');

  bool get isVisible =>
      this != FilterCollection.experimental ||
      ((!kReleaseMode || _labBuild) &&
          MirrorFilter.inCollection(this).isNotEmpty);

  static List<FilterCollection> get visible =>
      values.where((c) => c.isVisible).toList();

  static const packs = [
    mosaic,
    halftone,
    sketch,
    optics,
    kaleido,
    tiles,
    glitch,
    vhs,
    face,
    layers,
    paint,
    color,
    light,
  ];

  bool get isPack => packs.contains(this);

  /// Collections with a tab of their own; packs share one tab.
  static List<FilterCollection> get tabs =>
      visible.where((c) => !c.isPack).toList();

  /// Paid collections are sold as non-consumable in-app purchases; free ones
  /// are always available. Locked filters still preview live — the paywall
  /// only gates saving photos/videos.
  bool get isPaid => switch (this) {
        FilterCollection.pretty ||
        FilterCollection.ugly ||
        FilterCollection.experimental => false,
        _ => true,
      };

  /// Preferred store product ID, null for free collections: the
  /// non-consumable `*_unlock` item. The original Art/Fantasy IDs were
  /// created on the App Store as consumables, which Restore Purchases cannot
  /// bring back, and Apple allows neither changing the type nor reusing an
  /// ID. Packs were non-consumable from the start: `collection.<name>`.
  String? get productId => switch (this) {
        FilterCollection.art => 'com.ol1n.mirrorbooth.collection.art_unlock',
        FilterCollection.fantasy =>
          'com.ol1n.mirrorbooth.collection.fantasy_unlock',
        _ when isPack => 'com.ol1n.mirrorbooth.collection.$name',
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
        _ when isPack => {productId!},
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
  // Packs: one technique family per chip, sold separately
  r2MosaicC0025,
  r2MosaicC0041,
  r2MosaicC0042,
  r2MosaicC0133,
  r2MosaicC0289,
  r2MosaicC0331,
  r2MosaicC0366,
  r2MosaicC0460,
  r2HalftoneC0029,
  r2HalftoneC0031,
  r2HalftoneC0136,
  r2HalftoneC0182,
  r2HalftoneC0284,
  r2HalftoneC0368,
  r2HalftoneC0370,
  r2HalftoneC0376,
  r2SketchC0021,
  r2SketchC0104,
  r2SketchC0155,
  r2SketchC0310,
  r2SketchC0311,
  r2SketchC0360,
  r2SketchC0382,
  r2SketchC0388,
  r2OpticsC0056,
  r2OpticsC0060,
  r2OpticsC0068,
  r2OpticsC0262,
  r2OpticsC0376,
  r2OpticsC0411,
  r2OpticsC0415,
  r2OpticsC0437,
  r2OpticsTunnel,
  r2KaleidoC0027,
  r2KaleidoC0051,
  r2KaleidoC0097,
  r2KaleidoC0242,
  r2KaleidoC0276,
  r2KaleidoC0281,
  r2KaleidoC0438,
  r2KaleidoC0486,
  r2TilesC0020,
  r2TilesC0180,
  r2TilesC0198,
  r2TilesC0218,
  r2TilesC0273,
  r2TilesC0298,
  r2TilesC0401,
  r2TilesC0498,
  r2GlitchC0036,
  r2GlitchC0098,
  r2GlitchC0394,
  r2VhsC0291,
  r2VhsC0336,
  r2VhsC0497,
  r2FaceC0165,
  r2FaceC0184,
  r2FaceC0227,
  r2FaceC0232,
  r2FaceC0240,
  r2FaceC0258,
  r2FaceC0327,
  r2FaceC0417,
  r2LayersC0006,
  r2LayersC0009,
  r2LayersC0033,
  r2LayersC0110,
  r2LayersC0144,
  r2LayersC0304,
  r2LayersC0441,
  r2LayersC0473,
  r2PaintC0048,
  r2PaintC0052,
  r2PaintC0101,
  r2PaintC0126,
  r2PaintC0170,
  r2PaintC0173,
  r2PaintC0189,
  r2PaintC0194,
  r2ColorC0008,
  r2ColorC0015,
  r2ColorC0039,
  r2ColorC0065,
  r2ColorC0069,
  r2ColorC0073,
  r2ColorC0097,
  r2ColorC0181,
  r2LightC0003,
  r2LightC0011,
  r2LightC0012,
  r2LightC0044,
  r2LightC0050,
  r2LightC0156,
  r2LightC0163,
  r2LightC0176,
  // Lab 177+: glitch/VHS rerun without the flicker gate
  r2GlitchC0190,
  r2GlitchC0412,
  r2GlitchC0430,
  r2VhsC0004,
  r2VhsC0057,
  r2VhsC0206,
  r2VhsC0413,
  r2VhsC0437,
  r2VhsC0446,
  r2VhsC0483,
  r2VhsC0496,
  r2VhsNight,
  // Lab: round 3, Pretty and Ugly face features (11 families)
  r3EyesC0230,
  r3EyesC0016,
  r3EyesC0010,
  r3EyesC0294,
  r3EyesC0254,
  r3LipsC0276,
  r3LipsC0110,
  r3LipsC0261,
  r3LipsC0024,
  r3LipsC0080,
  r3LipsC0165,
  r3LipsC0290,
  r3LipsC0142,
  r3GlowC0015,
  r3GlowC0080,
  r3GlowC0230,
  r3GlowC0165,
  r3GlowC0016,
  r3GlowC0264,
  r3HairC0200,
  r3HairC0273,
  r3HairC0089,
  r3HairC0122,
  r3HairC0287,
  r3HairC0173,
  r3HairC0192,
  r3HairC0030,
  r3SculptC0232,
  r3SculptC0048,
  r3SculptC0126,
  r3SculptC0040,
  r3SculptC0246,
  r3SculptC0282,
  r3SculptC0004,
  r3SculptC0111,
  r3ScarsC0034,
  r3ScarsC0239,
  r3ScarsC0212,
  r3ScarsC0166,
  r3ScarsC0228,
  r3ScarsC0113,
  r3ScarsC0019,
  r3ScarsC0081,
  r3FacepaintC0113,
  r3FacepaintC0025,
  r3FacepaintC0149,
  r3FacepaintC0268,
  r3FacepaintC0245,
  r3FacepaintC0247,
  r3FacepaintC0288,
  r3FacepaintC0272,
  r3AlienC0003,
  r3AlienC0030,
  r3AlienC0112,
  r3AlienC0020,
  r3AlienC0012,
  r3AlienC0027,
  r3AlienC0015,
  r3AnimalC0234,
  r3AnimalC0202,
  r3AnimalC0239,
  r3AnimalC0258,
  r3AnimalC0282,
  r3AnimalC0216,
  r3AnimalC0169,
  r3AnimalC0186,
  r3FeaturesC0267,
  r3FeaturesC0287,
  r3FeaturesC0174,
  r3FeaturesC0233,
  r3FeaturesC0001,
  r3FeaturesC0072,
  r3FeaturesC0154,
  r3FeaturesC0232,
  r3MoviefxC0288,
  r3MoviefxC0254,
  r3MoviefxC0145,
  r3MoviefxC0280,
  r3MoviefxC0070,
  r3MoviefxC0222,
  r3MoviefxC0240,
  r3MoviefxC0117,
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
        MirrorFilter.r2OpticsTunnel => 'Tunnel',
        MirrorFilter.r2VhsNight => 'Night',
        MirrorFilter.r2MosaicC0025 => 'Mosaic 1',
        MirrorFilter.r2MosaicC0041 => 'Mosaic 2',
        MirrorFilter.r2MosaicC0042 => 'Mosaic 3',
        MirrorFilter.r2MosaicC0133 => 'Mosaic 4',
        MirrorFilter.r2MosaicC0289 => 'Mosaic 5',
        MirrorFilter.r2MosaicC0331 => 'Mosaic 6',
        MirrorFilter.r2MosaicC0366 => 'Mosaic 7',
        MirrorFilter.r2MosaicC0460 => 'Mosaic 8',
        MirrorFilter.r2HalftoneC0029 => 'Halftone 1',
        MirrorFilter.r2HalftoneC0031 => 'Halftone 2',
        MirrorFilter.r2HalftoneC0136 => 'Halftone 3',
        MirrorFilter.r2HalftoneC0182 => 'Halftone 4',
        MirrorFilter.r2HalftoneC0284 => 'Halftone 5',
        MirrorFilter.r2HalftoneC0368 => 'Halftone 6',
        MirrorFilter.r2HalftoneC0370 => 'Halftone 7',
        MirrorFilter.r2HalftoneC0376 => 'Halftone 8',
        MirrorFilter.r2SketchC0021 => 'Sketch 1',
        MirrorFilter.r2SketchC0104 => 'Sketch 2',
        MirrorFilter.r2SketchC0155 => 'Sketch 3',
        MirrorFilter.r2SketchC0310 => 'Sketch 4',
        MirrorFilter.r2SketchC0311 => 'Sketch 5',
        MirrorFilter.r2SketchC0360 => 'Sketch 6',
        MirrorFilter.r2SketchC0382 => 'Sketch 7',
        MirrorFilter.r2SketchC0388 => 'Sketch 8',
        MirrorFilter.r2OpticsC0056 => 'Optics 1',
        MirrorFilter.r2OpticsC0060 => 'Optics 2',
        MirrorFilter.r2OpticsC0068 => 'Optics 3',
        MirrorFilter.r2OpticsC0262 => 'Optics 4',
        MirrorFilter.r2OpticsC0376 => 'Optics 5',
        MirrorFilter.r2OpticsC0411 => 'Optics 6',
        MirrorFilter.r2OpticsC0415 => 'Optics 7',
        MirrorFilter.r2OpticsC0437 => 'Optics 8',
        MirrorFilter.r2KaleidoC0027 => 'Kaleido 1',
        MirrorFilter.r2KaleidoC0051 => 'Kaleido 2',
        MirrorFilter.r2KaleidoC0097 => 'Kaleido 3',
        MirrorFilter.r2KaleidoC0242 => 'Kaleido 4',
        MirrorFilter.r2KaleidoC0276 => 'Kaleido 5',
        MirrorFilter.r2KaleidoC0281 => 'Kaleido 6',
        MirrorFilter.r2KaleidoC0438 => 'Kaleido 7',
        MirrorFilter.r2KaleidoC0486 => 'Kaleido 8',
        MirrorFilter.r2TilesC0020 => 'Tiles 1',
        MirrorFilter.r2TilesC0180 => 'Tiles 2',
        MirrorFilter.r2TilesC0198 => 'Tiles 3',
        MirrorFilter.r2TilesC0218 => 'Tiles 4',
        MirrorFilter.r2TilesC0273 => 'Tiles 5',
        MirrorFilter.r2TilesC0298 => 'Tiles 6',
        MirrorFilter.r2TilesC0401 => 'Tiles 7',
        MirrorFilter.r2TilesC0498 => 'Tiles 8',
        MirrorFilter.r2GlitchC0036 => 'Glitch 1',
        MirrorFilter.r2GlitchC0098 => 'Glitch 2',
        MirrorFilter.r2GlitchC0394 => 'Glitch 3',
        MirrorFilter.r2VhsC0291 => 'VHS 1',
        MirrorFilter.r2VhsC0336 => 'VHS 2',
        MirrorFilter.r2VhsC0497 => 'VHS 3',
        MirrorFilter.r2FaceC0165 => 'Face 1',
        MirrorFilter.r2FaceC0184 => 'Face 2',
        MirrorFilter.r2FaceC0227 => 'Face 3',
        MirrorFilter.r2FaceC0232 => 'Face 4',
        MirrorFilter.r2FaceC0240 => 'Face 5',
        MirrorFilter.r2FaceC0258 => 'Face 6',
        MirrorFilter.r2FaceC0327 => 'Face 7',
        MirrorFilter.r2FaceC0417 => 'Face 8',
        MirrorFilter.r2LayersC0006 => 'Layers 1',
        MirrorFilter.r2LayersC0009 => 'Layers 2',
        MirrorFilter.r2LayersC0033 => 'Layers 3',
        MirrorFilter.r2LayersC0110 => 'Layers 4',
        MirrorFilter.r2LayersC0144 => 'Layers 5',
        MirrorFilter.r2LayersC0304 => 'Layers 6',
        MirrorFilter.r2LayersC0441 => 'Layers 7',
        MirrorFilter.r2LayersC0473 => 'Layers 8',
        MirrorFilter.r2PaintC0048 => 'Paint 1',
        MirrorFilter.r2PaintC0052 => 'Paint 2',
        MirrorFilter.r2PaintC0101 => 'Paint 3',
        MirrorFilter.r2PaintC0126 => 'Paint 4',
        MirrorFilter.r2PaintC0170 => 'Paint 5',
        MirrorFilter.r2PaintC0173 => 'Paint 6',
        MirrorFilter.r2PaintC0189 => 'Paint 7',
        MirrorFilter.r2PaintC0194 => 'Paint 8',
        MirrorFilter.r2ColorC0008 => 'Color 1',
        MirrorFilter.r2ColorC0015 => 'Color 2',
        MirrorFilter.r2ColorC0039 => 'Color 3',
        MirrorFilter.r2ColorC0065 => 'Color 4',
        MirrorFilter.r2ColorC0069 => 'Color 5',
        MirrorFilter.r2ColorC0073 => 'Color 6',
        MirrorFilter.r2ColorC0097 => 'Color 7',
        MirrorFilter.r2ColorC0181 => 'Color 8',
        MirrorFilter.r2LightC0003 => 'Light 1',
        MirrorFilter.r2LightC0011 => 'Light 2',
        MirrorFilter.r2LightC0012 => 'Light 3',
        MirrorFilter.r2LightC0044 => 'Light 4',
        MirrorFilter.r2LightC0050 => 'Light 5',
        MirrorFilter.r2LightC0156 => 'Light 6',
        MirrorFilter.r2LightC0163 => 'Light 7',
        MirrorFilter.r2LightC0176 => 'Light 8',
        MirrorFilter.r2GlitchC0190 => 'Glitch 4',
        MirrorFilter.r2GlitchC0412 => 'Glitch 5',
        MirrorFilter.r2GlitchC0430 => 'Glitch 6',
        MirrorFilter.r2VhsC0004 => 'VHS 4',
        MirrorFilter.r2VhsC0057 => 'VHS 5',
        MirrorFilter.r2VhsC0206 => 'VHS 6',
        MirrorFilter.r2VhsC0413 => 'VHS 7',
        MirrorFilter.r2VhsC0437 => 'VHS 8',
        MirrorFilter.r2VhsC0446 => 'VHS 9',
        MirrorFilter.r2VhsC0483 => 'VHS 10',
        MirrorFilter.r2VhsC0496 => 'VHS 11',
        MirrorFilter.r3EyesC0230 => 'Eyes 1',
        MirrorFilter.r3EyesC0016 => 'Eyes 2',
        MirrorFilter.r3EyesC0010 => 'Eyes 3',
        MirrorFilter.r3EyesC0294 => 'Eyes 4',
        MirrorFilter.r3EyesC0254 => 'Eyes 5',
        MirrorFilter.r3LipsC0276 => 'Lips 1',
        MirrorFilter.r3LipsC0110 => 'Lips 2',
        MirrorFilter.r3LipsC0261 => 'Lips 3',
        MirrorFilter.r3LipsC0024 => 'Lips 4',
        MirrorFilter.r3LipsC0080 => 'Lips 5',
        MirrorFilter.r3LipsC0165 => 'Lips 6',
        MirrorFilter.r3LipsC0290 => 'Lips 7',
        MirrorFilter.r3LipsC0142 => 'Lips 8',
        MirrorFilter.r3GlowC0015 => 'Glow 1',
        MirrorFilter.r3GlowC0080 => 'Glow 2',
        MirrorFilter.r3GlowC0230 => 'Glow 3',
        MirrorFilter.r3GlowC0165 => 'Glow 4',
        MirrorFilter.r3GlowC0016 => 'Glow 5',
        MirrorFilter.r3GlowC0264 => 'Glow 6',
        MirrorFilter.r3HairC0200 => 'Hair 1',
        MirrorFilter.r3HairC0273 => 'Hair 2',
        MirrorFilter.r3HairC0089 => 'Hair 3',
        MirrorFilter.r3HairC0122 => 'Hair 4',
        MirrorFilter.r3HairC0287 => 'Hair 5',
        MirrorFilter.r3HairC0173 => 'Hair 6',
        MirrorFilter.r3HairC0192 => 'Hair 7',
        MirrorFilter.r3HairC0030 => 'Hair 8',
        MirrorFilter.r3SculptC0232 => 'Sculpt 1',
        MirrorFilter.r3SculptC0048 => 'Sculpt 2',
        MirrorFilter.r3SculptC0126 => 'Sculpt 3',
        MirrorFilter.r3SculptC0040 => 'Sculpt 4',
        MirrorFilter.r3SculptC0246 => 'Sculpt 5',
        MirrorFilter.r3SculptC0282 => 'Sculpt 6',
        MirrorFilter.r3SculptC0004 => 'Sculpt 7',
        MirrorFilter.r3SculptC0111 => 'Sculpt 8',
        MirrorFilter.r3ScarsC0034 => 'Scars 1',
        MirrorFilter.r3ScarsC0239 => 'Scars 2',
        MirrorFilter.r3ScarsC0212 => 'Scars 3',
        MirrorFilter.r3ScarsC0166 => 'Scars 4',
        MirrorFilter.r3ScarsC0228 => 'Scars 5',
        MirrorFilter.r3ScarsC0113 => 'Scars 6',
        MirrorFilter.r3ScarsC0019 => 'Scars 7',
        MirrorFilter.r3ScarsC0081 => 'Scars 8',
        MirrorFilter.r3FacepaintC0113 => 'Face paint 1',
        MirrorFilter.r3FacepaintC0025 => 'Face paint 2',
        MirrorFilter.r3FacepaintC0149 => 'Face paint 3',
        MirrorFilter.r3FacepaintC0268 => 'Face paint 4',
        MirrorFilter.r3FacepaintC0245 => 'Face paint 5',
        MirrorFilter.r3FacepaintC0247 => 'Face paint 6',
        MirrorFilter.r3FacepaintC0288 => 'Face paint 7',
        MirrorFilter.r3FacepaintC0272 => 'Face paint 8',
        MirrorFilter.r3AlienC0003 => 'Alien 1',
        MirrorFilter.r3AlienC0030 => 'Alien 2',
        MirrorFilter.r3AlienC0112 => 'Alien 3',
        MirrorFilter.r3AlienC0020 => 'Alien 4',
        MirrorFilter.r3AlienC0012 => 'Alien 5',
        MirrorFilter.r3AlienC0027 => 'Alien 6',
        MirrorFilter.r3AlienC0015 => 'Alien 7',
        MirrorFilter.r3AnimalC0234 => 'Animal 1',
        MirrorFilter.r3AnimalC0202 => 'Animal 2',
        MirrorFilter.r3AnimalC0239 => 'Animal 3',
        MirrorFilter.r3AnimalC0258 => 'Animal 4',
        MirrorFilter.r3AnimalC0282 => 'Animal 5',
        MirrorFilter.r3AnimalC0216 => 'Animal 6',
        MirrorFilter.r3AnimalC0169 => 'Animal 7',
        MirrorFilter.r3AnimalC0186 => 'Animal 8',
        MirrorFilter.r3FeaturesC0267 => 'Features 1',
        MirrorFilter.r3FeaturesC0287 => 'Features 2',
        MirrorFilter.r3FeaturesC0174 => 'Features 3',
        MirrorFilter.r3FeaturesC0233 => 'Features 4',
        MirrorFilter.r3FeaturesC0001 => 'Features 5',
        MirrorFilter.r3FeaturesC0072 => 'Features 6',
        MirrorFilter.r3FeaturesC0154 => 'Features 7',
        MirrorFilter.r3FeaturesC0232 => 'Features 8',
        MirrorFilter.r3MoviefxC0288 => 'Movie FX 1',
        MirrorFilter.r3MoviefxC0254 => 'Movie FX 2',
        MirrorFilter.r3MoviefxC0145 => 'Movie FX 3',
        MirrorFilter.r3MoviefxC0280 => 'Movie FX 4',
        MirrorFilter.r3MoviefxC0070 => 'Movie FX 5',
        MirrorFilter.r3MoviefxC0222 => 'Movie FX 6',
        MirrorFilter.r3MoviefxC0240 => 'Movie FX 7',
        MirrorFilter.r3MoviefxC0117 => 'Movie FX 8',
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
        MirrorFilter.r2OpticsTunnel => '▣',
        MirrorFilter.r2VhsNight => '▣',
        MirrorFilter.r2MosaicC0025 => '◇',
        MirrorFilter.r2MosaicC0041 => '◇',
        MirrorFilter.r2MosaicC0042 => '◇',
        MirrorFilter.r2MosaicC0133 => '◇',
        MirrorFilter.r2MosaicC0289 => '◇',
        MirrorFilter.r2MosaicC0331 => '◇',
        MirrorFilter.r2MosaicC0366 => '◇',
        MirrorFilter.r2MosaicC0460 => '◇',
        MirrorFilter.r2HalftoneC0029 => '◇',
        MirrorFilter.r2HalftoneC0031 => '◇',
        MirrorFilter.r2HalftoneC0136 => '◇',
        MirrorFilter.r2HalftoneC0182 => '◇',
        MirrorFilter.r2HalftoneC0284 => '◇',
        MirrorFilter.r2HalftoneC0368 => '◇',
        MirrorFilter.r2HalftoneC0370 => '◇',
        MirrorFilter.r2HalftoneC0376 => '◇',
        MirrorFilter.r2SketchC0021 => '◇',
        MirrorFilter.r2SketchC0104 => '◇',
        MirrorFilter.r2SketchC0155 => '◇',
        MirrorFilter.r2SketchC0310 => '◇',
        MirrorFilter.r2SketchC0311 => '◇',
        MirrorFilter.r2SketchC0360 => '◇',
        MirrorFilter.r2SketchC0382 => '◇',
        MirrorFilter.r2SketchC0388 => '◇',
        MirrorFilter.r2OpticsC0056 => '◇',
        MirrorFilter.r2OpticsC0060 => '◇',
        MirrorFilter.r2OpticsC0068 => '◇',
        MirrorFilter.r2OpticsC0262 => '◇',
        MirrorFilter.r2OpticsC0376 => '◇',
        MirrorFilter.r2OpticsC0411 => '◇',
        MirrorFilter.r2OpticsC0415 => '◇',
        MirrorFilter.r2OpticsC0437 => '◇',
        MirrorFilter.r2KaleidoC0027 => '◇',
        MirrorFilter.r2KaleidoC0051 => '◇',
        MirrorFilter.r2KaleidoC0097 => '◇',
        MirrorFilter.r2KaleidoC0242 => '◇',
        MirrorFilter.r2KaleidoC0276 => '◇',
        MirrorFilter.r2KaleidoC0281 => '◇',
        MirrorFilter.r2KaleidoC0438 => '◇',
        MirrorFilter.r2KaleidoC0486 => '◇',
        MirrorFilter.r2TilesC0020 => '◇',
        MirrorFilter.r2TilesC0180 => '◇',
        MirrorFilter.r2TilesC0198 => '◇',
        MirrorFilter.r2TilesC0218 => '◇',
        MirrorFilter.r2TilesC0273 => '◇',
        MirrorFilter.r2TilesC0298 => '◇',
        MirrorFilter.r2TilesC0401 => '◇',
        MirrorFilter.r2TilesC0498 => '◇',
        MirrorFilter.r2GlitchC0036 => '◇',
        MirrorFilter.r2GlitchC0098 => '◇',
        MirrorFilter.r2GlitchC0394 => '◇',
        MirrorFilter.r2VhsC0291 => '◇',
        MirrorFilter.r2VhsC0336 => '◇',
        MirrorFilter.r2VhsC0497 => '◇',
        MirrorFilter.r2FaceC0165 => '◇',
        MirrorFilter.r2FaceC0184 => '◇',
        MirrorFilter.r2FaceC0227 => '◇',
        MirrorFilter.r2FaceC0232 => '◇',
        MirrorFilter.r2FaceC0240 => '◇',
        MirrorFilter.r2FaceC0258 => '◇',
        MirrorFilter.r2FaceC0327 => '◇',
        MirrorFilter.r2FaceC0417 => '◇',
        MirrorFilter.r2LayersC0006 => '◇',
        MirrorFilter.r2LayersC0009 => '◇',
        MirrorFilter.r2LayersC0033 => '◇',
        MirrorFilter.r2LayersC0110 => '◇',
        MirrorFilter.r2LayersC0144 => '◇',
        MirrorFilter.r2LayersC0304 => '◇',
        MirrorFilter.r2LayersC0441 => '◇',
        MirrorFilter.r2LayersC0473 => '◇',
        MirrorFilter.r2PaintC0048 => '◇',
        MirrorFilter.r2PaintC0052 => '◇',
        MirrorFilter.r2PaintC0101 => '◇',
        MirrorFilter.r2PaintC0126 => '◇',
        MirrorFilter.r2PaintC0170 => '◇',
        MirrorFilter.r2PaintC0173 => '◇',
        MirrorFilter.r2PaintC0189 => '◇',
        MirrorFilter.r2PaintC0194 => '◇',
        MirrorFilter.r2ColorC0008 => '◇',
        MirrorFilter.r2ColorC0015 => '◇',
        MirrorFilter.r2ColorC0039 => '◇',
        MirrorFilter.r2ColorC0065 => '◇',
        MirrorFilter.r2ColorC0069 => '◇',
        MirrorFilter.r2ColorC0073 => '◇',
        MirrorFilter.r2ColorC0097 => '◇',
        MirrorFilter.r2ColorC0181 => '◇',
        MirrorFilter.r2LightC0003 => '◇',
        MirrorFilter.r2LightC0011 => '◇',
        MirrorFilter.r2LightC0012 => '◇',
        MirrorFilter.r2LightC0044 => '◇',
        MirrorFilter.r2LightC0050 => '◇',
        MirrorFilter.r2LightC0156 => '◇',
        MirrorFilter.r2LightC0163 => '◇',
        MirrorFilter.r2LightC0176 => '◇',
        MirrorFilter.r2GlitchC0190 => '◇',
        MirrorFilter.r2GlitchC0412 => '◇',
        MirrorFilter.r2GlitchC0430 => '◇',
        MirrorFilter.r2VhsC0004 => '◇',
        MirrorFilter.r2VhsC0057 => '◇',
        MirrorFilter.r2VhsC0206 => '◇',
        MirrorFilter.r2VhsC0413 => '◇',
        MirrorFilter.r2VhsC0437 => '◇',
        MirrorFilter.r2VhsC0446 => '◇',
        MirrorFilter.r2VhsC0483 => '◇',
        MirrorFilter.r2VhsC0496 => '◇',
        MirrorFilter.r3EyesC0230 => '◉',
        MirrorFilter.r3EyesC0016 => '◉',
        MirrorFilter.r3EyesC0010 => '◉',
        MirrorFilter.r3EyesC0294 => '◉',
        MirrorFilter.r3EyesC0254 => '◉',
        MirrorFilter.r3LipsC0276 => 'ω',
        MirrorFilter.r3LipsC0110 => 'ω',
        MirrorFilter.r3LipsC0261 => 'ω',
        MirrorFilter.r3LipsC0024 => 'ω',
        MirrorFilter.r3LipsC0080 => 'ω',
        MirrorFilter.r3LipsC0165 => 'ω',
        MirrorFilter.r3LipsC0290 => 'ω',
        MirrorFilter.r3LipsC0142 => 'ω',
        MirrorFilter.r3GlowC0015 => '✧',
        MirrorFilter.r3GlowC0080 => '✧',
        MirrorFilter.r3GlowC0230 => '✧',
        MirrorFilter.r3GlowC0165 => '✧',
        MirrorFilter.r3GlowC0016 => '✧',
        MirrorFilter.r3GlowC0264 => '✧',
        MirrorFilter.r3HairC0200 => '≋',
        MirrorFilter.r3HairC0273 => '≋',
        MirrorFilter.r3HairC0089 => '≋',
        MirrorFilter.r3HairC0122 => '≋',
        MirrorFilter.r3HairC0287 => '≋',
        MirrorFilter.r3HairC0173 => '≋',
        MirrorFilter.r3HairC0192 => '≋',
        MirrorFilter.r3HairC0030 => '≋',
        MirrorFilter.r3SculptC0232 => '◐',
        MirrorFilter.r3SculptC0048 => '◐',
        MirrorFilter.r3SculptC0126 => '◐',
        MirrorFilter.r3SculptC0040 => '◐',
        MirrorFilter.r3SculptC0246 => '◐',
        MirrorFilter.r3SculptC0282 => '◐',
        MirrorFilter.r3SculptC0004 => '◐',
        MirrorFilter.r3SculptC0111 => '◐',
        MirrorFilter.r3ScarsC0034 => '⚡',
        MirrorFilter.r3ScarsC0239 => '⚡',
        MirrorFilter.r3ScarsC0212 => '⚡',
        MirrorFilter.r3ScarsC0166 => '⚡',
        MirrorFilter.r3ScarsC0228 => '⚡',
        MirrorFilter.r3ScarsC0113 => '⚡',
        MirrorFilter.r3ScarsC0019 => '⚡',
        MirrorFilter.r3ScarsC0081 => '⚡',
        MirrorFilter.r3FacepaintC0113 => '✎',
        MirrorFilter.r3FacepaintC0025 => '✎',
        MirrorFilter.r3FacepaintC0149 => '✎',
        MirrorFilter.r3FacepaintC0268 => '✎',
        MirrorFilter.r3FacepaintC0245 => '✎',
        MirrorFilter.r3FacepaintC0247 => '✎',
        MirrorFilter.r3FacepaintC0288 => '✎',
        MirrorFilter.r3FacepaintC0272 => '✎',
        MirrorFilter.r3AlienC0003 => 'Λ',
        MirrorFilter.r3AlienC0030 => 'Λ',
        MirrorFilter.r3AlienC0112 => 'Λ',
        MirrorFilter.r3AlienC0020 => 'Λ',
        MirrorFilter.r3AlienC0012 => 'Λ',
        MirrorFilter.r3AlienC0027 => 'Λ',
        MirrorFilter.r3AlienC0015 => 'Λ',
        MirrorFilter.r3AnimalC0234 => 'ᴥ',
        MirrorFilter.r3AnimalC0202 => 'ᴥ',
        MirrorFilter.r3AnimalC0239 => 'ᴥ',
        MirrorFilter.r3AnimalC0258 => 'ᴥ',
        MirrorFilter.r3AnimalC0282 => 'ᴥ',
        MirrorFilter.r3AnimalC0216 => 'ᴥ',
        MirrorFilter.r3AnimalC0169 => 'ᴥ',
        MirrorFilter.r3AnimalC0186 => 'ᴥ',
        MirrorFilter.r3FeaturesC0267 => '△',
        MirrorFilter.r3FeaturesC0287 => '△',
        MirrorFilter.r3FeaturesC0174 => '△',
        MirrorFilter.r3FeaturesC0233 => '△',
        MirrorFilter.r3FeaturesC0001 => '△',
        MirrorFilter.r3FeaturesC0072 => '△',
        MirrorFilter.r3FeaturesC0154 => '△',
        MirrorFilter.r3FeaturesC0232 => '△',
        MirrorFilter.r3MoviefxC0288 => '▣',
        MirrorFilter.r3MoviefxC0254 => '▣',
        MirrorFilter.r3MoviefxC0145 => '▣',
        MirrorFilter.r3MoviefxC0280 => '▣',
        MirrorFilter.r3MoviefxC0070 => '▣',
        MirrorFilter.r3MoviefxC0222 => '▣',
        MirrorFilter.r3MoviefxC0240 => '▣',
        MirrorFilter.r3MoviefxC0117 => '▣',
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
        MirrorFilter.r2OpticsTunnel => true,
        MirrorFilter.r2VhsNight => true,
        MirrorFilter.r2MosaicC0025 => true,
        MirrorFilter.r2MosaicC0041 => true,
        MirrorFilter.r2MosaicC0042 => true,
        MirrorFilter.r2MosaicC0133 => true,
        MirrorFilter.r2MosaicC0289 => true,
        MirrorFilter.r2MosaicC0331 => true,
        MirrorFilter.r2MosaicC0366 => true,
        MirrorFilter.r2MosaicC0460 => true,
        MirrorFilter.r2HalftoneC0029 => true,
        MirrorFilter.r2HalftoneC0136 => true,
        MirrorFilter.r2HalftoneC0182 => true,
        MirrorFilter.r2HalftoneC0284 => true,
        MirrorFilter.r2HalftoneC0368 => true,
        MirrorFilter.r2HalftoneC0370 => true,
        MirrorFilter.r2HalftoneC0376 => true,
        MirrorFilter.r2SketchC0104 => true,
        MirrorFilter.r2SketchC0155 => true,
        MirrorFilter.r2SketchC0311 => true,
        MirrorFilter.r2SketchC0360 => true,
        MirrorFilter.r2SketchC0382 => true,
        MirrorFilter.r2SketchC0388 => true,
        MirrorFilter.r2OpticsC0068 => true,
        MirrorFilter.r2OpticsC0262 => true,
        MirrorFilter.r2OpticsC0376 => true,
        MirrorFilter.r2OpticsC0411 => true,
        MirrorFilter.r2OpticsC0415 => true,
        MirrorFilter.r2OpticsC0437 => true,
        MirrorFilter.r2KaleidoC0027 => true,
        MirrorFilter.r2KaleidoC0051 => true,
        MirrorFilter.r2KaleidoC0097 => true,
        MirrorFilter.r2KaleidoC0242 => true,
        MirrorFilter.r2KaleidoC0276 => true,
        MirrorFilter.r2KaleidoC0281 => true,
        MirrorFilter.r2KaleidoC0438 => true,
        MirrorFilter.r2KaleidoC0486 => true,
        MirrorFilter.r2TilesC0020 => true,
        MirrorFilter.r2TilesC0180 => true,
        MirrorFilter.r2TilesC0198 => true,
        MirrorFilter.r2TilesC0218 => true,
        MirrorFilter.r2TilesC0273 => true,
        MirrorFilter.r2TilesC0298 => true,
        MirrorFilter.r2TilesC0401 => true,
        MirrorFilter.r2TilesC0498 => true,
        MirrorFilter.r2GlitchC0036 => true,
        MirrorFilter.r2GlitchC0098 => true,
        MirrorFilter.r2GlitchC0394 => true,
        MirrorFilter.r2VhsC0291 => true,
        MirrorFilter.r2VhsC0336 => true,
        MirrorFilter.r2VhsC0497 => true,
        MirrorFilter.r2LayersC0006 => true,
        MirrorFilter.r2LayersC0009 => true,
        MirrorFilter.r2LayersC0033 => true,
        MirrorFilter.r2LayersC0110 => true,
        MirrorFilter.r2LayersC0144 => true,
        MirrorFilter.r2LayersC0304 => true,
        MirrorFilter.r2LayersC0441 => true,
        MirrorFilter.r2LayersC0473 => true,
        MirrorFilter.r2PaintC0052 => true,
        MirrorFilter.r2PaintC0101 => true,
        MirrorFilter.r2PaintC0170 => true,
        MirrorFilter.r2PaintC0173 => true,
        MirrorFilter.r2PaintC0189 => true,
        MirrorFilter.r2PaintC0194 => true,
        MirrorFilter.r2ColorC0008 => true,
        MirrorFilter.r2ColorC0039 => true,
        MirrorFilter.r2ColorC0065 => true,
        MirrorFilter.r2ColorC0069 => true,
        MirrorFilter.r2ColorC0073 => true,
        MirrorFilter.r2ColorC0097 => true,
        MirrorFilter.r2ColorC0181 => true,
        MirrorFilter.r2LightC0044 => true,
        MirrorFilter.r2LightC0050 => true,
        MirrorFilter.r2LightC0156 => true,
        MirrorFilter.r2LightC0163 => true,
        MirrorFilter.r2LightC0176 => true,
        MirrorFilter.r2GlitchC0190 => true,
        MirrorFilter.r2GlitchC0412 => true,
        MirrorFilter.r2GlitchC0430 => true,
        MirrorFilter.r2VhsC0004 => true,
        MirrorFilter.r2VhsC0057 => true,
        MirrorFilter.r2VhsC0206 => true,
        MirrorFilter.r2VhsC0413 => true,
        MirrorFilter.r2VhsC0437 => true,
        MirrorFilter.r2VhsC0446 => true,
        MirrorFilter.r2VhsC0483 => true,
        MirrorFilter.r2VhsC0496 => true,
        MirrorFilter.r3HairC0200 => true,
        MirrorFilter.r3HairC0273 => true,
        MirrorFilter.r3HairC0089 => true,
        MirrorFilter.r3HairC0122 => true,
        MirrorFilter.r3HairC0287 => true,
        MirrorFilter.r3HairC0173 => true,
        MirrorFilter.r3HairC0192 => true,
        MirrorFilter.r3HairC0030 => true,
        MirrorFilter.r3AlienC0030 => true,
        MirrorFilter.r3AlienC0112 => true,
        MirrorFilter.r3AlienC0020 => true,
        MirrorFilter.r3AlienC0015 => true,
        MirrorFilter.r3MoviefxC0145 => true,
        MirrorFilter.r3MoviefxC0222 => true,
        MirrorFilter.r3MoviefxC0240 => true,
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
        MirrorFilter.r2MosaicC0041 => true,
        MirrorFilter.r2MosaicC0042 => true,
        MirrorFilter.r2MosaicC0133 => true,
        MirrorFilter.r2MosaicC0289 => true,
        MirrorFilter.r2MosaicC0331 => true,
        MirrorFilter.r2MosaicC0366 => true,
        MirrorFilter.r2MosaicC0460 => true,
        MirrorFilter.r2HalftoneC0029 => true,
        MirrorFilter.r2HalftoneC0182 => true,
        MirrorFilter.r2HalftoneC0284 => true,
        MirrorFilter.r2HalftoneC0368 => true,
        MirrorFilter.r2HalftoneC0370 => true,
        MirrorFilter.r2HalftoneC0376 => true,
        MirrorFilter.r2SketchC0104 => true,
        MirrorFilter.r2SketchC0155 => true,
        MirrorFilter.r2SketchC0310 => true,
        MirrorFilter.r2SketchC0311 => true,
        MirrorFilter.r2SketchC0360 => true,
        MirrorFilter.r2SketchC0382 => true,
        MirrorFilter.r2SketchC0388 => true,
        MirrorFilter.r2OpticsC0056 => true,
        MirrorFilter.r2OpticsC0060 => true,
        MirrorFilter.r2OpticsC0068 => true,
        MirrorFilter.r2OpticsC0262 => true,
        MirrorFilter.r2OpticsC0376 => true,
        MirrorFilter.r2OpticsC0411 => true,
        MirrorFilter.r2OpticsC0415 => true,
        MirrorFilter.r2OpticsC0437 => true,
        MirrorFilter.r2KaleidoC0027 => true,
        MirrorFilter.r2KaleidoC0097 => true,
        MirrorFilter.r2KaleidoC0242 => true,
        MirrorFilter.r2KaleidoC0276 => true,
        MirrorFilter.r2KaleidoC0281 => true,
        MirrorFilter.r2KaleidoC0438 => true,
        MirrorFilter.r2KaleidoC0486 => true,
        MirrorFilter.r2TilesC0020 => true,
        MirrorFilter.r2TilesC0180 => true,
        MirrorFilter.r2TilesC0198 => true,
        MirrorFilter.r2TilesC0218 => true,
        MirrorFilter.r2TilesC0273 => true,
        MirrorFilter.r2TilesC0298 => true,
        MirrorFilter.r2TilesC0401 => true,
        MirrorFilter.r2TilesC0498 => true,
        MirrorFilter.r2GlitchC0036 => true,
        MirrorFilter.r2GlitchC0098 => true,
        MirrorFilter.r2GlitchC0394 => true,
        MirrorFilter.r2VhsC0291 => true,
        MirrorFilter.r2VhsC0336 => true,
        MirrorFilter.r2VhsC0497 => true,
        MirrorFilter.r2FaceC0165 => true,
        MirrorFilter.r2FaceC0184 => true,
        MirrorFilter.r2FaceC0227 => true,
        MirrorFilter.r2FaceC0232 => true,
        MirrorFilter.r2FaceC0240 => true,
        MirrorFilter.r2FaceC0258 => true,
        MirrorFilter.r2FaceC0327 => true,
        MirrorFilter.r2FaceC0417 => true,
        MirrorFilter.r2LayersC0304 => true,
        MirrorFilter.r2LayersC0441 => true,
        MirrorFilter.r2LayersC0473 => true,
        MirrorFilter.r2PaintC0101 => true,
        MirrorFilter.r2PaintC0170 => true,
        MirrorFilter.r2PaintC0173 => true,
        MirrorFilter.r2PaintC0189 => true,
        MirrorFilter.r2PaintC0194 => true,
        MirrorFilter.r2ColorC0069 => true,
        MirrorFilter.r2ColorC0097 => true,
        MirrorFilter.r2ColorC0181 => true,
        MirrorFilter.r2LightC0003 => true,
        MirrorFilter.r2LightC0011 => true,
        MirrorFilter.r2LightC0012 => true,
        MirrorFilter.r2LightC0156 => true,
        MirrorFilter.r2LightC0176 => true,
        MirrorFilter.r2GlitchC0190 => true,
        MirrorFilter.r2GlitchC0412 => true,
        MirrorFilter.r2GlitchC0430 => true,
        MirrorFilter.r2VhsC0004 => true,
        MirrorFilter.r2VhsC0057 => true,
        MirrorFilter.r2VhsC0206 => true,
        MirrorFilter.r2VhsC0413 => true,
        MirrorFilter.r2VhsC0437 => true,
        MirrorFilter.r2VhsC0446 => true,
        MirrorFilter.r2VhsC0483 => true,
        MirrorFilter.r2VhsC0496 => true,
        MirrorFilter.r3EyesC0230 => true,
        MirrorFilter.r3EyesC0016 => true,
        MirrorFilter.r3EyesC0010 => true,
        MirrorFilter.r3EyesC0294 => true,
        MirrorFilter.r3EyesC0254 => true,
        MirrorFilter.r3LipsC0276 => true,
        MirrorFilter.r3LipsC0110 => true,
        MirrorFilter.r3LipsC0261 => true,
        MirrorFilter.r3LipsC0024 => true,
        MirrorFilter.r3LipsC0080 => true,
        MirrorFilter.r3LipsC0165 => true,
        MirrorFilter.r3LipsC0290 => true,
        MirrorFilter.r3LipsC0142 => true,
        MirrorFilter.r3GlowC0015 => true,
        MirrorFilter.r3GlowC0080 => true,
        MirrorFilter.r3GlowC0230 => true,
        MirrorFilter.r3GlowC0165 => true,
        MirrorFilter.r3GlowC0016 => true,
        MirrorFilter.r3GlowC0264 => true,
        MirrorFilter.r3HairC0200 => true,
        MirrorFilter.r3HairC0273 => true,
        MirrorFilter.r3HairC0089 => true,
        MirrorFilter.r3HairC0122 => true,
        MirrorFilter.r3HairC0287 => true,
        MirrorFilter.r3HairC0173 => true,
        MirrorFilter.r3HairC0192 => true,
        MirrorFilter.r3HairC0030 => true,
        MirrorFilter.r3SculptC0232 => true,
        MirrorFilter.r3SculptC0048 => true,
        MirrorFilter.r3SculptC0126 => true,
        MirrorFilter.r3SculptC0040 => true,
        MirrorFilter.r3SculptC0246 => true,
        MirrorFilter.r3SculptC0282 => true,
        MirrorFilter.r3SculptC0004 => true,
        MirrorFilter.r3SculptC0111 => true,
        MirrorFilter.r3ScarsC0034 => true,
        MirrorFilter.r3ScarsC0239 => true,
        MirrorFilter.r3ScarsC0212 => true,
        MirrorFilter.r3ScarsC0166 => true,
        MirrorFilter.r3ScarsC0228 => true,
        MirrorFilter.r3ScarsC0113 => true,
        MirrorFilter.r3ScarsC0019 => true,
        MirrorFilter.r3ScarsC0081 => true,
        MirrorFilter.r3FacepaintC0113 => true,
        MirrorFilter.r3FacepaintC0025 => true,
        MirrorFilter.r3FacepaintC0149 => true,
        MirrorFilter.r3FacepaintC0268 => true,
        MirrorFilter.r3FacepaintC0245 => true,
        MirrorFilter.r3FacepaintC0247 => true,
        MirrorFilter.r3FacepaintC0288 => true,
        MirrorFilter.r3FacepaintC0272 => true,
        MirrorFilter.r3AlienC0003 => true,
        MirrorFilter.r3AlienC0030 => true,
        MirrorFilter.r3AlienC0112 => true,
        MirrorFilter.r3AlienC0020 => true,
        MirrorFilter.r3AlienC0012 => true,
        MirrorFilter.r3AlienC0027 => true,
        MirrorFilter.r3AlienC0015 => true,
        MirrorFilter.r3AnimalC0234 => true,
        MirrorFilter.r3AnimalC0202 => true,
        MirrorFilter.r3AnimalC0239 => true,
        MirrorFilter.r3AnimalC0258 => true,
        MirrorFilter.r3AnimalC0282 => true,
        MirrorFilter.r3AnimalC0216 => true,
        MirrorFilter.r3AnimalC0169 => true,
        MirrorFilter.r3AnimalC0186 => true,
        MirrorFilter.r3FeaturesC0267 => true,
        MirrorFilter.r3FeaturesC0287 => true,
        MirrorFilter.r3FeaturesC0174 => true,
        MirrorFilter.r3FeaturesC0233 => true,
        MirrorFilter.r3FeaturesC0001 => true,
        MirrorFilter.r3FeaturesC0072 => true,
        MirrorFilter.r3FeaturesC0154 => true,
        MirrorFilter.r3FeaturesC0232 => true,
        MirrorFilter.r3MoviefxC0288 => true,
        MirrorFilter.r3MoviefxC0254 => true,
        MirrorFilter.r3MoviefxC0145 => true,
        MirrorFilter.r3MoviefxC0280 => true,
        MirrorFilter.r3MoviefxC0070 => true,
        MirrorFilter.r3MoviefxC0222 => true,
        MirrorFilter.r3MoviefxC0240 => true,
        MirrorFilter.r3MoviefxC0117 => true,
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
        MirrorFilter.lips => FilterCollection.pretty,
        // @shadergen:collection:ugly
        MirrorFilter.bigNose ||
        MirrorFilter.alien ||
        MirrorFilter.melt ||
        MirrorFilter.bigEars ||
        MirrorFilter.longNeck => FilterCollection.ugly,
        // @shadergen:collection:art
        MirrorFilter.pencil ||
        MirrorFilter.comic ||
        MirrorFilter.glitch ||
        MirrorFilter.neon ||
        MirrorFilter.thermal ||
        MirrorFilter.oil ||
        MirrorFilter.crt ||
        MirrorFilter.popArt => FilterCollection.art,
        // @shadergen:collection:fantasy
        MirrorFilter.vampire ||
        MirrorFilter.zombie ||
        MirrorFilter.ghost ||
        MirrorFilter.demon ||
        MirrorFilter.cyborg ||
        MirrorFilter.frozen => FilterCollection.fantasy,
        // @shadergen:collection:experimental
        MirrorFilter.r3EyesC0230 ||
        MirrorFilter.r3EyesC0016 ||
        MirrorFilter.r3EyesC0010 ||
        MirrorFilter.r3EyesC0294 ||
        MirrorFilter.r3EyesC0254 ||
        MirrorFilter.r3LipsC0276 ||
        MirrorFilter.r3LipsC0110 ||
        MirrorFilter.r3LipsC0261 ||
        MirrorFilter.r3LipsC0024 ||
        MirrorFilter.r3LipsC0080 ||
        MirrorFilter.r3LipsC0165 ||
        MirrorFilter.r3LipsC0290 ||
        MirrorFilter.r3LipsC0142 ||
        MirrorFilter.r3GlowC0015 ||
        MirrorFilter.r3GlowC0080 ||
        MirrorFilter.r3GlowC0230 ||
        MirrorFilter.r3GlowC0165 ||
        MirrorFilter.r3GlowC0016 ||
        MirrorFilter.r3GlowC0264 ||
        MirrorFilter.r3HairC0200 ||
        MirrorFilter.r3HairC0273 ||
        MirrorFilter.r3HairC0089 ||
        MirrorFilter.r3HairC0122 ||
        MirrorFilter.r3HairC0287 ||
        MirrorFilter.r3HairC0173 ||
        MirrorFilter.r3HairC0192 ||
        MirrorFilter.r3HairC0030 ||
        MirrorFilter.r3SculptC0232 ||
        MirrorFilter.r3SculptC0048 ||
        MirrorFilter.r3SculptC0126 ||
        MirrorFilter.r3SculptC0040 ||
        MirrorFilter.r3SculptC0246 ||
        MirrorFilter.r3SculptC0282 ||
        MirrorFilter.r3SculptC0004 ||
        MirrorFilter.r3SculptC0111 ||
        MirrorFilter.r3ScarsC0034 ||
        MirrorFilter.r3ScarsC0239 ||
        MirrorFilter.r3ScarsC0212 ||
        MirrorFilter.r3ScarsC0166 ||
        MirrorFilter.r3ScarsC0228 ||
        MirrorFilter.r3ScarsC0113 ||
        MirrorFilter.r3ScarsC0019 ||
        MirrorFilter.r3ScarsC0081 ||
        MirrorFilter.r3FacepaintC0113 ||
        MirrorFilter.r3FacepaintC0025 ||
        MirrorFilter.r3FacepaintC0149 ||
        MirrorFilter.r3FacepaintC0268 ||
        MirrorFilter.r3FacepaintC0245 ||
        MirrorFilter.r3FacepaintC0247 ||
        MirrorFilter.r3FacepaintC0288 ||
        MirrorFilter.r3FacepaintC0272 ||
        MirrorFilter.r3AlienC0003 ||
        MirrorFilter.r3AlienC0030 ||
        MirrorFilter.r3AlienC0112 ||
        MirrorFilter.r3AlienC0020 ||
        MirrorFilter.r3AlienC0012 ||
        MirrorFilter.r3AlienC0027 ||
        MirrorFilter.r3AlienC0015 ||
        MirrorFilter.r3AnimalC0234 ||
        MirrorFilter.r3AnimalC0202 ||
        MirrorFilter.r3AnimalC0239 ||
        MirrorFilter.r3AnimalC0258 ||
        MirrorFilter.r3AnimalC0282 ||
        MirrorFilter.r3AnimalC0216 ||
        MirrorFilter.r3AnimalC0169 ||
        MirrorFilter.r3AnimalC0186 ||
        MirrorFilter.r3FeaturesC0267 ||
        MirrorFilter.r3FeaturesC0287 ||
        MirrorFilter.r3FeaturesC0174 ||
        MirrorFilter.r3FeaturesC0233 ||
        MirrorFilter.r3FeaturesC0001 ||
        MirrorFilter.r3FeaturesC0072 ||
        MirrorFilter.r3FeaturesC0154 ||
        MirrorFilter.r3FeaturesC0232 ||
        MirrorFilter.r3MoviefxC0288 ||
        MirrorFilter.r3MoviefxC0254 ||
        MirrorFilter.r3MoviefxC0145 ||
        MirrorFilter.r3MoviefxC0280 ||
        MirrorFilter.r3MoviefxC0070 ||
        MirrorFilter.r3MoviefxC0222 ||
        MirrorFilter.r3MoviefxC0240 ||
        MirrorFilter.r3MoviefxC0117 =>
          FilterCollection.experimental,
        MirrorFilter.r2MosaicC0025 ||
        MirrorFilter.r2MosaicC0041 ||
        MirrorFilter.r2MosaicC0042 ||
        MirrorFilter.r2MosaicC0133 ||
        MirrorFilter.r2MosaicC0289 ||
        MirrorFilter.r2MosaicC0331 ||
        MirrorFilter.r2MosaicC0366 ||
        MirrorFilter.r2MosaicC0460 => FilterCollection.mosaic,
        MirrorFilter.r2HalftoneC0029 ||
        MirrorFilter.r2HalftoneC0031 ||
        MirrorFilter.r2HalftoneC0136 ||
        MirrorFilter.r2HalftoneC0182 ||
        MirrorFilter.r2HalftoneC0284 ||
        MirrorFilter.r2HalftoneC0368 ||
        MirrorFilter.r2HalftoneC0370 ||
        MirrorFilter.r2HalftoneC0376 => FilterCollection.halftone,
        MirrorFilter.r2SketchC0021 ||
        MirrorFilter.r2SketchC0104 ||
        MirrorFilter.r2SketchC0155 ||
        MirrorFilter.r2SketchC0310 ||
        MirrorFilter.r2SketchC0311 ||
        MirrorFilter.r2SketchC0360 ||
        MirrorFilter.r2SketchC0382 ||
        MirrorFilter.r2SketchC0388 => FilterCollection.sketch,
        MirrorFilter.r2OpticsC0056 ||
        MirrorFilter.r2OpticsC0060 ||
        MirrorFilter.r2OpticsC0068 ||
        MirrorFilter.r2OpticsC0262 ||
        MirrorFilter.r2OpticsC0376 ||
        MirrorFilter.r2OpticsC0411 ||
        MirrorFilter.r2OpticsC0415 ||
        MirrorFilter.r2OpticsC0437 ||
        MirrorFilter.r2OpticsTunnel => FilterCollection.optics,
        MirrorFilter.r2KaleidoC0027 ||
        MirrorFilter.r2KaleidoC0051 ||
        MirrorFilter.r2KaleidoC0097 ||
        MirrorFilter.r2KaleidoC0242 ||
        MirrorFilter.r2KaleidoC0276 ||
        MirrorFilter.r2KaleidoC0281 ||
        MirrorFilter.r2KaleidoC0438 ||
        MirrorFilter.r2KaleidoC0486 => FilterCollection.kaleido,
        MirrorFilter.r2TilesC0020 ||
        MirrorFilter.r2TilesC0180 ||
        MirrorFilter.r2TilesC0198 ||
        MirrorFilter.r2TilesC0218 ||
        MirrorFilter.r2TilesC0273 ||
        MirrorFilter.r2TilesC0298 ||
        MirrorFilter.r2TilesC0401 ||
        MirrorFilter.r2TilesC0498 => FilterCollection.tiles,
        MirrorFilter.r2GlitchC0036 ||
        MirrorFilter.r2GlitchC0098 ||
        MirrorFilter.r2GlitchC0394 ||
        MirrorFilter.r2GlitchC0190 ||
        MirrorFilter.r2GlitchC0412 ||
        MirrorFilter.r2GlitchC0430 => FilterCollection.glitch,
        MirrorFilter.r2VhsC0291 ||
        MirrorFilter.r2VhsC0336 ||
        MirrorFilter.r2VhsC0497 ||
        MirrorFilter.r2VhsC0004 ||
        MirrorFilter.r2VhsC0057 ||
        MirrorFilter.r2VhsC0206 ||
        MirrorFilter.r2VhsC0413 ||
        MirrorFilter.r2VhsC0437 ||
        MirrorFilter.r2VhsC0446 ||
        MirrorFilter.r2VhsC0483 ||
        MirrorFilter.r2VhsC0496 ||
        MirrorFilter.r2VhsNight => FilterCollection.vhs,
        MirrorFilter.r2FaceC0165 ||
        MirrorFilter.r2FaceC0184 ||
        MirrorFilter.r2FaceC0227 ||
        MirrorFilter.r2FaceC0232 ||
        MirrorFilter.r2FaceC0240 ||
        MirrorFilter.r2FaceC0258 ||
        MirrorFilter.r2FaceC0327 ||
        MirrorFilter.r2FaceC0417 => FilterCollection.face,
        MirrorFilter.r2LayersC0006 ||
        MirrorFilter.r2LayersC0009 ||
        MirrorFilter.r2LayersC0033 ||
        MirrorFilter.r2LayersC0110 ||
        MirrorFilter.r2LayersC0144 ||
        MirrorFilter.r2LayersC0304 ||
        MirrorFilter.r2LayersC0441 ||
        MirrorFilter.r2LayersC0473 => FilterCollection.layers,
        MirrorFilter.r2PaintC0048 ||
        MirrorFilter.r2PaintC0052 ||
        MirrorFilter.r2PaintC0101 ||
        MirrorFilter.r2PaintC0126 ||
        MirrorFilter.r2PaintC0170 ||
        MirrorFilter.r2PaintC0173 ||
        MirrorFilter.r2PaintC0189 ||
        MirrorFilter.r2PaintC0194 => FilterCollection.paint,
        MirrorFilter.r2ColorC0008 ||
        MirrorFilter.r2ColorC0015 ||
        MirrorFilter.r2ColorC0039 ||
        MirrorFilter.r2ColorC0065 ||
        MirrorFilter.r2ColorC0069 ||
        MirrorFilter.r2ColorC0073 ||
        MirrorFilter.r2ColorC0097 ||
        MirrorFilter.r2ColorC0181 => FilterCollection.color,
        MirrorFilter.r2LightC0003 ||
        MirrorFilter.r2LightC0011 ||
        MirrorFilter.r2LightC0012 ||
        MirrorFilter.r2LightC0044 ||
        MirrorFilter.r2LightC0050 ||
        MirrorFilter.r2LightC0156 ||
        MirrorFilter.r2LightC0163 ||
        MirrorFilter.r2LightC0176 => FilterCollection.light,
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
        MirrorFilter.r2OpticsTunnel => 'shaders/filter_r2_optics_tunnel.frag',
        MirrorFilter.r2VhsNight => 'shaders/filter_r2_vhs_night.frag',
        MirrorFilter.r2MosaicC0025 => 'shaders/filter_r2_mosaic_c0025.frag',
        MirrorFilter.r2MosaicC0041 => 'shaders/filter_r2_mosaic_c0041.frag',
        MirrorFilter.r2MosaicC0042 => 'shaders/filter_r2_mosaic_c0042.frag',
        MirrorFilter.r2MosaicC0133 => 'shaders/filter_r2_mosaic_c0133.frag',
        MirrorFilter.r2MosaicC0289 => 'shaders/filter_r2_mosaic_c0289.frag',
        MirrorFilter.r2MosaicC0331 => 'shaders/filter_r2_mosaic_c0331.frag',
        MirrorFilter.r2MosaicC0366 => 'shaders/filter_r2_mosaic_c0366.frag',
        MirrorFilter.r2MosaicC0460 => 'shaders/filter_r2_mosaic_c0460.frag',
        MirrorFilter.r2HalftoneC0029 => 'shaders/filter_r2_halftone_c0029.frag',
        MirrorFilter.r2HalftoneC0031 => 'shaders/filter_r2_halftone_c0031.frag',
        MirrorFilter.r2HalftoneC0136 => 'shaders/filter_r2_halftone_c0136.frag',
        MirrorFilter.r2HalftoneC0182 => 'shaders/filter_r2_halftone_c0182.frag',
        MirrorFilter.r2HalftoneC0284 => 'shaders/filter_r2_halftone_c0284.frag',
        MirrorFilter.r2HalftoneC0368 => 'shaders/filter_r2_halftone_c0368.frag',
        MirrorFilter.r2HalftoneC0370 => 'shaders/filter_r2_halftone_c0370.frag',
        MirrorFilter.r2HalftoneC0376 => 'shaders/filter_r2_halftone_c0376.frag',
        MirrorFilter.r2SketchC0021 => 'shaders/filter_r2_sketch_c0021.frag',
        MirrorFilter.r2SketchC0104 => 'shaders/filter_r2_sketch_c0104.frag',
        MirrorFilter.r2SketchC0155 => 'shaders/filter_r2_sketch_c0155.frag',
        MirrorFilter.r2SketchC0310 => 'shaders/filter_r2_sketch_c0310.frag',
        MirrorFilter.r2SketchC0311 => 'shaders/filter_r2_sketch_c0311.frag',
        MirrorFilter.r2SketchC0360 => 'shaders/filter_r2_sketch_c0360.frag',
        MirrorFilter.r2SketchC0382 => 'shaders/filter_r2_sketch_c0382.frag',
        MirrorFilter.r2SketchC0388 => 'shaders/filter_r2_sketch_c0388.frag',
        MirrorFilter.r2OpticsC0056 => 'shaders/filter_r2_optics_c0056.frag',
        MirrorFilter.r2OpticsC0060 => 'shaders/filter_r2_optics_c0060.frag',
        MirrorFilter.r2OpticsC0068 => 'shaders/filter_r2_optics_c0068.frag',
        MirrorFilter.r2OpticsC0262 => 'shaders/filter_r2_optics_c0262.frag',
        MirrorFilter.r2OpticsC0376 => 'shaders/filter_r2_optics_c0376.frag',
        MirrorFilter.r2OpticsC0411 => 'shaders/filter_r2_optics_c0411.frag',
        MirrorFilter.r2OpticsC0415 => 'shaders/filter_r2_optics_c0415.frag',
        MirrorFilter.r2OpticsC0437 => 'shaders/filter_r2_optics_c0437.frag',
        MirrorFilter.r2KaleidoC0027 => 'shaders/filter_r2_kaleido_c0027.frag',
        MirrorFilter.r2KaleidoC0051 => 'shaders/filter_r2_kaleido_c0051.frag',
        MirrorFilter.r2KaleidoC0097 => 'shaders/filter_r2_kaleido_c0097.frag',
        MirrorFilter.r2KaleidoC0242 => 'shaders/filter_r2_kaleido_c0242.frag',
        MirrorFilter.r2KaleidoC0276 => 'shaders/filter_r2_kaleido_c0276.frag',
        MirrorFilter.r2KaleidoC0281 => 'shaders/filter_r2_kaleido_c0281.frag',
        MirrorFilter.r2KaleidoC0438 => 'shaders/filter_r2_kaleido_c0438.frag',
        MirrorFilter.r2KaleidoC0486 => 'shaders/filter_r2_kaleido_c0486.frag',
        MirrorFilter.r2TilesC0020 => 'shaders/filter_r2_tiles_c0020.frag',
        MirrorFilter.r2TilesC0180 => 'shaders/filter_r2_tiles_c0180.frag',
        MirrorFilter.r2TilesC0198 => 'shaders/filter_r2_tiles_c0198.frag',
        MirrorFilter.r2TilesC0218 => 'shaders/filter_r2_tiles_c0218.frag',
        MirrorFilter.r2TilesC0273 => 'shaders/filter_r2_tiles_c0273.frag',
        MirrorFilter.r2TilesC0298 => 'shaders/filter_r2_tiles_c0298.frag',
        MirrorFilter.r2TilesC0401 => 'shaders/filter_r2_tiles_c0401.frag',
        MirrorFilter.r2TilesC0498 => 'shaders/filter_r2_tiles_c0498.frag',
        MirrorFilter.r2GlitchC0036 => 'shaders/filter_r2_glitch_c0036.frag',
        MirrorFilter.r2GlitchC0098 => 'shaders/filter_r2_glitch_c0098.frag',
        MirrorFilter.r2GlitchC0394 => 'shaders/filter_r2_glitch_c0394.frag',
        MirrorFilter.r2VhsC0291 => 'shaders/filter_r2_vhs_c0291.frag',
        MirrorFilter.r2VhsC0336 => 'shaders/filter_r2_vhs_c0336.frag',
        MirrorFilter.r2VhsC0497 => 'shaders/filter_r2_vhs_c0497.frag',
        MirrorFilter.r2FaceC0165 => 'shaders/filter_r2_face_c0165.frag',
        MirrorFilter.r2FaceC0184 => 'shaders/filter_r2_face_c0184.frag',
        MirrorFilter.r2FaceC0227 => 'shaders/filter_r2_face_c0227.frag',
        MirrorFilter.r2FaceC0232 => 'shaders/filter_r2_face_c0232.frag',
        MirrorFilter.r2FaceC0240 => 'shaders/filter_r2_face_c0240.frag',
        MirrorFilter.r2FaceC0258 => 'shaders/filter_r2_face_c0258.frag',
        MirrorFilter.r2FaceC0327 => 'shaders/filter_r2_face_c0327.frag',
        MirrorFilter.r2FaceC0417 => 'shaders/filter_r2_face_c0417.frag',
        MirrorFilter.r2LayersC0006 => 'shaders/filter_r2_layers_c0006.frag',
        MirrorFilter.r2LayersC0009 => 'shaders/filter_r2_layers_c0009.frag',
        MirrorFilter.r2LayersC0033 => 'shaders/filter_r2_layers_c0033.frag',
        MirrorFilter.r2LayersC0110 => 'shaders/filter_r2_layers_c0110.frag',
        MirrorFilter.r2LayersC0144 => 'shaders/filter_r2_layers_c0144.frag',
        MirrorFilter.r2LayersC0304 => 'shaders/filter_r2_layers_c0304.frag',
        MirrorFilter.r2LayersC0441 => 'shaders/filter_r2_layers_c0441.frag',
        MirrorFilter.r2LayersC0473 => 'shaders/filter_r2_layers_c0473.frag',
        MirrorFilter.r2PaintC0048 => 'shaders/filter_r2_paint_c0048.frag',
        MirrorFilter.r2PaintC0052 => 'shaders/filter_r2_paint_c0052.frag',
        MirrorFilter.r2PaintC0101 => 'shaders/filter_r2_paint_c0101.frag',
        MirrorFilter.r2PaintC0126 => 'shaders/filter_r2_paint_c0126.frag',
        MirrorFilter.r2PaintC0170 => 'shaders/filter_r2_paint_c0170.frag',
        MirrorFilter.r2PaintC0173 => 'shaders/filter_r2_paint_c0173.frag',
        MirrorFilter.r2PaintC0189 => 'shaders/filter_r2_paint_c0189.frag',
        MirrorFilter.r2PaintC0194 => 'shaders/filter_r2_paint_c0194.frag',
        MirrorFilter.r2ColorC0008 => 'shaders/filter_r2_color_c0008.frag',
        MirrorFilter.r2ColorC0015 => 'shaders/filter_r2_color_c0015.frag',
        MirrorFilter.r2ColorC0039 => 'shaders/filter_r2_color_c0039.frag',
        MirrorFilter.r2ColorC0065 => 'shaders/filter_r2_color_c0065.frag',
        MirrorFilter.r2ColorC0069 => 'shaders/filter_r2_color_c0069.frag',
        MirrorFilter.r2ColorC0073 => 'shaders/filter_r2_color_c0073.frag',
        MirrorFilter.r2ColorC0097 => 'shaders/filter_r2_color_c0097.frag',
        MirrorFilter.r2ColorC0181 => 'shaders/filter_r2_color_c0181.frag',
        MirrorFilter.r2LightC0003 => 'shaders/filter_r2_light_c0003.frag',
        MirrorFilter.r2LightC0011 => 'shaders/filter_r2_light_c0011.frag',
        MirrorFilter.r2LightC0012 => 'shaders/filter_r2_light_c0012.frag',
        MirrorFilter.r2LightC0044 => 'shaders/filter_r2_light_c0044.frag',
        MirrorFilter.r2LightC0050 => 'shaders/filter_r2_light_c0050.frag',
        MirrorFilter.r2LightC0156 => 'shaders/filter_r2_light_c0156.frag',
        MirrorFilter.r2LightC0163 => 'shaders/filter_r2_light_c0163.frag',
        MirrorFilter.r2LightC0176 => 'shaders/filter_r2_light_c0176.frag',
        MirrorFilter.r2GlitchC0190 => 'shaders/filter_r2_glitch_c0190.frag',
        MirrorFilter.r2GlitchC0412 => 'shaders/filter_r2_glitch_c0412.frag',
        MirrorFilter.r2GlitchC0430 => 'shaders/filter_r2_glitch_c0430.frag',
        MirrorFilter.r2VhsC0004 => 'shaders/filter_r2_vhs_c0004.frag',
        MirrorFilter.r2VhsC0057 => 'shaders/filter_r2_vhs_c0057.frag',
        MirrorFilter.r2VhsC0206 => 'shaders/filter_r2_vhs_c0206.frag',
        MirrorFilter.r2VhsC0413 => 'shaders/filter_r2_vhs_c0413.frag',
        MirrorFilter.r2VhsC0437 => 'shaders/filter_r2_vhs_c0437.frag',
        MirrorFilter.r2VhsC0446 => 'shaders/filter_r2_vhs_c0446.frag',
        MirrorFilter.r2VhsC0483 => 'shaders/filter_r2_vhs_c0483.frag',
        MirrorFilter.r2VhsC0496 => 'shaders/filter_r2_vhs_c0496.frag',
        MirrorFilter.r3EyesC0230 => 'shaders/filter_r3_eyes_c0230.frag',
        MirrorFilter.r3EyesC0016 => 'shaders/filter_r3_eyes_c0016.frag',
        MirrorFilter.r3EyesC0010 => 'shaders/filter_r3_eyes_c0010.frag',
        MirrorFilter.r3EyesC0294 => 'shaders/filter_r3_eyes_c0294.frag',
        MirrorFilter.r3EyesC0254 => 'shaders/filter_r3_eyes_c0254.frag',
        MirrorFilter.r3LipsC0276 => 'shaders/filter_r3_lips_makeup_c0276.frag',
        MirrorFilter.r3LipsC0110 => 'shaders/filter_r3_lips_makeup_c0110.frag',
        MirrorFilter.r3LipsC0261 => 'shaders/filter_r3_lips_makeup_c0261.frag',
        MirrorFilter.r3LipsC0024 => 'shaders/filter_r3_lips_makeup_c0024.frag',
        MirrorFilter.r3LipsC0080 => 'shaders/filter_r3_lips_makeup_c0080.frag',
        MirrorFilter.r3LipsC0165 => 'shaders/filter_r3_lips_makeup_c0165.frag',
        MirrorFilter.r3LipsC0290 => 'shaders/filter_r3_lips_makeup_c0290.frag',
        MirrorFilter.r3LipsC0142 => 'shaders/filter_r3_lips_makeup_c0142.frag',
        MirrorFilter.r3GlowC0015 => 'shaders/filter_r3_skin_glow_c0015.frag',
        MirrorFilter.r3GlowC0080 => 'shaders/filter_r3_skin_glow_c0080.frag',
        MirrorFilter.r3GlowC0230 => 'shaders/filter_r3_skin_glow_c0230.frag',
        MirrorFilter.r3GlowC0165 => 'shaders/filter_r3_skin_glow_c0165.frag',
        MirrorFilter.r3GlowC0016 => 'shaders/filter_r3_skin_glow_c0016.frag',
        MirrorFilter.r3GlowC0264 => 'shaders/filter_r3_skin_glow_c0264.frag',
        MirrorFilter.r3HairC0200 => 'shaders/filter_r3_hair_halo_c0200.frag',
        MirrorFilter.r3HairC0273 => 'shaders/filter_r3_hair_halo_c0273.frag',
        MirrorFilter.r3HairC0089 => 'shaders/filter_r3_hair_halo_c0089.frag',
        MirrorFilter.r3HairC0122 => 'shaders/filter_r3_hair_halo_c0122.frag',
        MirrorFilter.r3HairC0287 => 'shaders/filter_r3_hair_halo_c0287.frag',
        MirrorFilter.r3HairC0173 => 'shaders/filter_r3_hair_halo_c0173.frag',
        MirrorFilter.r3HairC0192 => 'shaders/filter_r3_hair_halo_c0192.frag',
        MirrorFilter.r3HairC0030 => 'shaders/filter_r3_hair_halo_c0030.frag',
        MirrorFilter.r3SculptC0232 => 'shaders/filter_r3_sculpt_c0232.frag',
        MirrorFilter.r3SculptC0048 => 'shaders/filter_r3_sculpt_c0048.frag',
        MirrorFilter.r3SculptC0126 => 'shaders/filter_r3_sculpt_c0126.frag',
        MirrorFilter.r3SculptC0040 => 'shaders/filter_r3_sculpt_c0040.frag',
        MirrorFilter.r3SculptC0246 => 'shaders/filter_r3_sculpt_c0246.frag',
        MirrorFilter.r3SculptC0282 => 'shaders/filter_r3_sculpt_c0282.frag',
        MirrorFilter.r3SculptC0004 => 'shaders/filter_r3_sculpt_c0004.frag',
        MirrorFilter.r3SculptC0111 => 'shaders/filter_r3_sculpt_c0111.frag',
        MirrorFilter.r3ScarsC0034 => 'shaders/filter_r3_scars_c0034.frag',
        MirrorFilter.r3ScarsC0239 => 'shaders/filter_r3_scars_c0239.frag',
        MirrorFilter.r3ScarsC0212 => 'shaders/filter_r3_scars_c0212.frag',
        MirrorFilter.r3ScarsC0166 => 'shaders/filter_r3_scars_c0166.frag',
        MirrorFilter.r3ScarsC0228 => 'shaders/filter_r3_scars_c0228.frag',
        MirrorFilter.r3ScarsC0113 => 'shaders/filter_r3_scars_c0113.frag',
        MirrorFilter.r3ScarsC0019 => 'shaders/filter_r3_scars_c0019.frag',
        MirrorFilter.r3ScarsC0081 => 'shaders/filter_r3_scars_c0081.frag',
        MirrorFilter.r3FacepaintC0113 => 'shaders/filter_r3_face_paint_c0113.frag',
        MirrorFilter.r3FacepaintC0025 => 'shaders/filter_r3_face_paint_c0025.frag',
        MirrorFilter.r3FacepaintC0149 => 'shaders/filter_r3_face_paint_c0149.frag',
        MirrorFilter.r3FacepaintC0268 => 'shaders/filter_r3_face_paint_c0268.frag',
        MirrorFilter.r3FacepaintC0245 => 'shaders/filter_r3_face_paint_c0245.frag',
        MirrorFilter.r3FacepaintC0247 => 'shaders/filter_r3_face_paint_c0247.frag',
        MirrorFilter.r3FacepaintC0288 => 'shaders/filter_r3_face_paint_c0288.frag',
        MirrorFilter.r3FacepaintC0272 => 'shaders/filter_r3_face_paint_c0272.frag',
        MirrorFilter.r3AlienC0003 => 'shaders/filter_r3_alien_c0003.frag',
        MirrorFilter.r3AlienC0030 => 'shaders/filter_r3_alien_c0030.frag',
        MirrorFilter.r3AlienC0112 => 'shaders/filter_r3_alien_c0112.frag',
        MirrorFilter.r3AlienC0020 => 'shaders/filter_r3_alien_c0020.frag',
        MirrorFilter.r3AlienC0012 => 'shaders/filter_r3_alien_c0012.frag',
        MirrorFilter.r3AlienC0027 => 'shaders/filter_r3_alien_c0027.frag',
        MirrorFilter.r3AlienC0015 => 'shaders/filter_r3_alien_c0015.frag',
        MirrorFilter.r3AnimalC0234 => 'shaders/filter_r3_animal_c0234.frag',
        MirrorFilter.r3AnimalC0202 => 'shaders/filter_r3_animal_c0202.frag',
        MirrorFilter.r3AnimalC0239 => 'shaders/filter_r3_animal_c0239.frag',
        MirrorFilter.r3AnimalC0258 => 'shaders/filter_r3_animal_c0258.frag',
        MirrorFilter.r3AnimalC0282 => 'shaders/filter_r3_animal_c0282.frag',
        MirrorFilter.r3AnimalC0216 => 'shaders/filter_r3_animal_c0216.frag',
        MirrorFilter.r3AnimalC0169 => 'shaders/filter_r3_animal_c0169.frag',
        MirrorFilter.r3AnimalC0186 => 'shaders/filter_r3_animal_c0186.frag',
        MirrorFilter.r3FeaturesC0267 => 'shaders/filter_r3_features_c0267.frag',
        MirrorFilter.r3FeaturesC0287 => 'shaders/filter_r3_features_c0287.frag',
        MirrorFilter.r3FeaturesC0174 => 'shaders/filter_r3_features_c0174.frag',
        MirrorFilter.r3FeaturesC0233 => 'shaders/filter_r3_features_c0233.frag',
        MirrorFilter.r3FeaturesC0001 => 'shaders/filter_r3_features_c0001.frag',
        MirrorFilter.r3FeaturesC0072 => 'shaders/filter_r3_features_c0072.frag',
        MirrorFilter.r3FeaturesC0154 => 'shaders/filter_r3_features_c0154.frag',
        MirrorFilter.r3FeaturesC0232 => 'shaders/filter_r3_features_c0232.frag',
        MirrorFilter.r3MoviefxC0288 => 'shaders/filter_r3_movie_fx_c0288.frag',
        MirrorFilter.r3MoviefxC0254 => 'shaders/filter_r3_movie_fx_c0254.frag',
        MirrorFilter.r3MoviefxC0145 => 'shaders/filter_r3_movie_fx_c0145.frag',
        MirrorFilter.r3MoviefxC0280 => 'shaders/filter_r3_movie_fx_c0280.frag',
        MirrorFilter.r3MoviefxC0070 => 'shaders/filter_r3_movie_fx_c0070.frag',
        MirrorFilter.r3MoviefxC0222 => 'shaders/filter_r3_movie_fx_c0222.frag',
        MirrorFilter.r3MoviefxC0240 => 'shaders/filter_r3_movie_fx_c0240.frag',
        MirrorFilter.r3MoviefxC0117 => 'shaders/filter_r3_movie_fx_c0117.frag',
        // @shadergen:shaderAsset
      };
}
