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
  // Lab 53-82: hand-written round B, one technique each (no polar warp)
  labMosaic,
  labHex,
  labGlass,
  labHalftone,
  labDither,
  labAscii,
  labSketch,
  labEmboss,
  labEngrave,
  labFisheye,
  labTwirl,
  labBlackHole,
  labTiles,
  labQuad,
  labBlinds,
  labBlocks,
  labVhs,
  labGameboy,
  labLed,
  labKuwahara,
  labAquarelle,
  labDuotone,
  labCutout,
  labRays,
  labTilt,
  labRain,
  labSnow,
  labMatrix,
  labTunnel,
  labNight,
  // Lab 83+: round 2, 13 technique families (chips by family)
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
        MirrorFilter.labMosaic => '53 Mosaic',
        MirrorFilter.labHex => '54 Hex',
        MirrorFilter.labGlass => '55 Glass',
        MirrorFilter.labHalftone => '56 Halftone',
        MirrorFilter.labDither => '57 Dither',
        MirrorFilter.labAscii => '58 Ascii',
        MirrorFilter.labSketch => '59 Sketch',
        MirrorFilter.labEmboss => '60 Emboss',
        MirrorFilter.labEngrave => '61 Engrave',
        MirrorFilter.labFisheye => '62 Fisheye',
        MirrorFilter.labTwirl => '63 Twirl',
        MirrorFilter.labBlackHole => '64 BlackHole',
        MirrorFilter.labTiles => '65 Tiles',
        MirrorFilter.labQuad => '66 Quad',
        MirrorFilter.labBlinds => '67 Blinds',
        MirrorFilter.labBlocks => '68 Blocks',
        MirrorFilter.labVhs => '69 Vhs',
        MirrorFilter.labGameboy => '70 Gameboy',
        MirrorFilter.labLed => '71 Led',
        MirrorFilter.labKuwahara => '72 Kuwahara',
        MirrorFilter.labAquarelle => '73 Aquarelle',
        MirrorFilter.labDuotone => '74 Duotone',
        MirrorFilter.labCutout => '75 Cutout',
        MirrorFilter.labRays => '76 Rays',
        MirrorFilter.labTilt => '77 Tilt',
        MirrorFilter.labRain => '78 Rain',
        MirrorFilter.labSnow => '79 Snow',
        MirrorFilter.labMatrix => '80 Matrix',
        MirrorFilter.labTunnel => '81 Tunnel',
        MirrorFilter.labNight => '82 Night',
        MirrorFilter.r2MosaicC0025 => '83 Mos',
        MirrorFilter.r2MosaicC0041 => '84 Mos',
        MirrorFilter.r2MosaicC0042 => '85 Mos',
        MirrorFilter.r2MosaicC0133 => '86 Mos',
        MirrorFilter.r2MosaicC0289 => '87 Mos',
        MirrorFilter.r2MosaicC0331 => '88 Mos',
        MirrorFilter.r2MosaicC0366 => '89 Mos',
        MirrorFilter.r2MosaicC0460 => '90 Mos',
        MirrorFilter.r2HalftoneC0029 => '91 Half',
        MirrorFilter.r2HalftoneC0031 => '92 Half',
        MirrorFilter.r2HalftoneC0136 => '93 Half',
        MirrorFilter.r2HalftoneC0182 => '94 Half',
        MirrorFilter.r2HalftoneC0284 => '95 Half',
        MirrorFilter.r2HalftoneC0368 => '96 Half',
        MirrorFilter.r2HalftoneC0370 => '97 Half',
        MirrorFilter.r2HalftoneC0376 => '98 Half',
        MirrorFilter.r2SketchC0021 => '99 Skt',
        MirrorFilter.r2SketchC0104 => '100 Skt',
        MirrorFilter.r2SketchC0155 => '101 Skt',
        MirrorFilter.r2SketchC0310 => '102 Skt',
        MirrorFilter.r2SketchC0311 => '103 Skt',
        MirrorFilter.r2SketchC0360 => '104 Skt',
        MirrorFilter.r2SketchC0382 => '105 Skt',
        MirrorFilter.r2SketchC0388 => '106 Skt',
        MirrorFilter.r2OpticsC0056 => '107 Opt',
        MirrorFilter.r2OpticsC0060 => '108 Opt',
        MirrorFilter.r2OpticsC0068 => '109 Opt',
        MirrorFilter.r2OpticsC0262 => '110 Opt',
        MirrorFilter.r2OpticsC0376 => '111 Opt',
        MirrorFilter.r2OpticsC0411 => '112 Opt',
        MirrorFilter.r2OpticsC0415 => '113 Opt',
        MirrorFilter.r2OpticsC0437 => '114 Opt',
        MirrorFilter.r2KaleidoC0027 => '115 Kal',
        MirrorFilter.r2KaleidoC0051 => '116 Kal',
        MirrorFilter.r2KaleidoC0097 => '117 Kal',
        MirrorFilter.r2KaleidoC0242 => '118 Kal',
        MirrorFilter.r2KaleidoC0276 => '119 Kal',
        MirrorFilter.r2KaleidoC0281 => '120 Kal',
        MirrorFilter.r2KaleidoC0438 => '121 Kal',
        MirrorFilter.r2KaleidoC0486 => '122 Kal',
        MirrorFilter.r2TilesC0020 => '123 Tile',
        MirrorFilter.r2TilesC0180 => '124 Tile',
        MirrorFilter.r2TilesC0198 => '125 Tile',
        MirrorFilter.r2TilesC0218 => '126 Tile',
        MirrorFilter.r2TilesC0273 => '127 Tile',
        MirrorFilter.r2TilesC0298 => '128 Tile',
        MirrorFilter.r2TilesC0401 => '129 Tile',
        MirrorFilter.r2TilesC0498 => '130 Tile',
        MirrorFilter.r2GlitchC0036 => '131 Gli',
        MirrorFilter.r2GlitchC0098 => '132 Gli',
        MirrorFilter.r2GlitchC0394 => '133 Gli',
        MirrorFilter.r2VhsC0291 => '134 VHS',
        MirrorFilter.r2VhsC0336 => '135 VHS',
        MirrorFilter.r2VhsC0497 => '136 VHS',
        MirrorFilter.r2FaceC0165 => '137 Face',
        MirrorFilter.r2FaceC0184 => '138 Face',
        MirrorFilter.r2FaceC0227 => '139 Face',
        MirrorFilter.r2FaceC0232 => '140 Face',
        MirrorFilter.r2FaceC0240 => '141 Face',
        MirrorFilter.r2FaceC0258 => '142 Face',
        MirrorFilter.r2FaceC0327 => '143 Face',
        MirrorFilter.r2FaceC0417 => '144 Face',
        MirrorFilter.r2LayersC0006 => '145 Lay',
        MirrorFilter.r2LayersC0009 => '146 Lay',
        MirrorFilter.r2LayersC0033 => '147 Lay',
        MirrorFilter.r2LayersC0110 => '148 Lay',
        MirrorFilter.r2LayersC0144 => '149 Lay',
        MirrorFilter.r2LayersC0304 => '150 Lay',
        MirrorFilter.r2LayersC0441 => '151 Lay',
        MirrorFilter.r2LayersC0473 => '152 Lay',
        MirrorFilter.r2PaintC0048 => '153 Pnt',
        MirrorFilter.r2PaintC0052 => '154 Pnt',
        MirrorFilter.r2PaintC0101 => '155 Pnt',
        MirrorFilter.r2PaintC0126 => '156 Pnt',
        MirrorFilter.r2PaintC0170 => '157 Pnt',
        MirrorFilter.r2PaintC0173 => '158 Pnt',
        MirrorFilter.r2PaintC0189 => '159 Pnt',
        MirrorFilter.r2PaintC0194 => '160 Pnt',
        MirrorFilter.r2ColorC0008 => '161 Col',
        MirrorFilter.r2ColorC0015 => '162 Col',
        MirrorFilter.r2ColorC0039 => '163 Col',
        MirrorFilter.r2ColorC0065 => '164 Col',
        MirrorFilter.r2ColorC0069 => '165 Col',
        MirrorFilter.r2ColorC0073 => '166 Col',
        MirrorFilter.r2ColorC0097 => '167 Col',
        MirrorFilter.r2ColorC0181 => '168 Col',
        MirrorFilter.r2LightC0003 => '169 Lit',
        MirrorFilter.r2LightC0011 => '170 Lit',
        MirrorFilter.r2LightC0012 => '171 Lit',
        MirrorFilter.r2LightC0044 => '172 Lit',
        MirrorFilter.r2LightC0050 => '173 Lit',
        MirrorFilter.r2LightC0156 => '174 Lit',
        MirrorFilter.r2LightC0163 => '175 Lit',
        MirrorFilter.r2LightC0176 => '176 Lit',
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
        MirrorFilter.labMosaic => '▣',
        MirrorFilter.labHex => '▣',
        MirrorFilter.labGlass => '▣',
        MirrorFilter.labHalftone => '▣',
        MirrorFilter.labDither => '▣',
        MirrorFilter.labAscii => '▣',
        MirrorFilter.labSketch => '▣',
        MirrorFilter.labEmboss => '▣',
        MirrorFilter.labEngrave => '▣',
        MirrorFilter.labFisheye => '▣',
        MirrorFilter.labTwirl => '▣',
        MirrorFilter.labBlackHole => '▣',
        MirrorFilter.labTiles => '▣',
        MirrorFilter.labQuad => '▣',
        MirrorFilter.labBlinds => '▣',
        MirrorFilter.labBlocks => '▣',
        MirrorFilter.labVhs => '▣',
        MirrorFilter.labGameboy => '▣',
        MirrorFilter.labLed => '▣',
        MirrorFilter.labKuwahara => '▣',
        MirrorFilter.labAquarelle => '▣',
        MirrorFilter.labDuotone => '▣',
        MirrorFilter.labCutout => '▣',
        MirrorFilter.labRays => '▣',
        MirrorFilter.labTilt => '▣',
        MirrorFilter.labRain => '▣',
        MirrorFilter.labSnow => '▣',
        MirrorFilter.labMatrix => '▣',
        MirrorFilter.labTunnel => '▣',
        MirrorFilter.labNight => '▣',
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
        MirrorFilter.labGlass => true,
        MirrorFilter.labTwirl => true,
        MirrorFilter.labBlackHole => true,
        MirrorFilter.labBlinds => true,
        MirrorFilter.labBlocks => true,
        MirrorFilter.labVhs => true,
        MirrorFilter.labRain => true,
        MirrorFilter.labSnow => true,
        MirrorFilter.labMatrix => true,
        MirrorFilter.labTunnel => true,
        MirrorFilter.labNight => true,
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
        MirrorFilter.labFisheye => true,
        MirrorFilter.labTwirl => true,
        MirrorFilter.labBlackHole => true,
        MirrorFilter.labRays => true,
        MirrorFilter.labTilt => true,
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
        MirrorFilter.r2LightC0176 ||
        MirrorFilter.r2LightC0163 ||
        MirrorFilter.r2LightC0156 ||
        MirrorFilter.r2LightC0050 ||
        MirrorFilter.r2LightC0044 ||
        MirrorFilter.r2LightC0012 ||
        MirrorFilter.r2LightC0011 ||
        MirrorFilter.r2LightC0003 ||
        MirrorFilter.r2ColorC0181 ||
        MirrorFilter.r2ColorC0097 ||
        MirrorFilter.r2ColorC0073 ||
        MirrorFilter.r2ColorC0069 ||
        MirrorFilter.r2ColorC0065 ||
        MirrorFilter.r2ColorC0039 ||
        MirrorFilter.r2ColorC0015 ||
        MirrorFilter.r2ColorC0008 ||
        MirrorFilter.r2PaintC0194 ||
        MirrorFilter.r2PaintC0189 ||
        MirrorFilter.r2PaintC0173 ||
        MirrorFilter.r2PaintC0170 ||
        MirrorFilter.r2PaintC0126 ||
        MirrorFilter.r2PaintC0101 ||
        MirrorFilter.r2PaintC0052 ||
        MirrorFilter.r2PaintC0048 ||
        MirrorFilter.r2LayersC0473 ||
        MirrorFilter.r2LayersC0441 ||
        MirrorFilter.r2LayersC0304 ||
        MirrorFilter.r2LayersC0144 ||
        MirrorFilter.r2LayersC0110 ||
        MirrorFilter.r2LayersC0033 ||
        MirrorFilter.r2LayersC0009 ||
        MirrorFilter.r2LayersC0006 ||
        MirrorFilter.r2FaceC0417 ||
        MirrorFilter.r2FaceC0327 ||
        MirrorFilter.r2FaceC0258 ||
        MirrorFilter.r2FaceC0240 ||
        MirrorFilter.r2FaceC0232 ||
        MirrorFilter.r2FaceC0227 ||
        MirrorFilter.r2FaceC0184 ||
        MirrorFilter.r2FaceC0165 ||
        MirrorFilter.r2VhsC0497 ||
        MirrorFilter.r2VhsC0336 ||
        MirrorFilter.r2VhsC0291 ||
        MirrorFilter.r2GlitchC0394 ||
        MirrorFilter.r2GlitchC0098 ||
        MirrorFilter.r2GlitchC0036 ||
        MirrorFilter.r2TilesC0498 ||
        MirrorFilter.r2TilesC0401 ||
        MirrorFilter.r2TilesC0298 ||
        MirrorFilter.r2TilesC0273 ||
        MirrorFilter.r2TilesC0218 ||
        MirrorFilter.r2TilesC0198 ||
        MirrorFilter.r2TilesC0180 ||
        MirrorFilter.r2TilesC0020 ||
        MirrorFilter.r2KaleidoC0486 ||
        MirrorFilter.r2KaleidoC0438 ||
        MirrorFilter.r2KaleidoC0281 ||
        MirrorFilter.r2KaleidoC0276 ||
        MirrorFilter.r2KaleidoC0242 ||
        MirrorFilter.r2KaleidoC0097 ||
        MirrorFilter.r2KaleidoC0051 ||
        MirrorFilter.r2KaleidoC0027 ||
        MirrorFilter.r2OpticsC0437 ||
        MirrorFilter.r2OpticsC0415 ||
        MirrorFilter.r2OpticsC0411 ||
        MirrorFilter.r2OpticsC0376 ||
        MirrorFilter.r2OpticsC0262 ||
        MirrorFilter.r2OpticsC0068 ||
        MirrorFilter.r2OpticsC0060 ||
        MirrorFilter.r2OpticsC0056 ||
        MirrorFilter.r2SketchC0388 ||
        MirrorFilter.r2SketchC0382 ||
        MirrorFilter.r2SketchC0360 ||
        MirrorFilter.r2SketchC0311 ||
        MirrorFilter.r2SketchC0310 ||
        MirrorFilter.r2SketchC0155 ||
        MirrorFilter.r2SketchC0104 ||
        MirrorFilter.r2SketchC0021 ||
        MirrorFilter.r2HalftoneC0376 ||
        MirrorFilter.r2HalftoneC0370 ||
        MirrorFilter.r2HalftoneC0368 ||
        MirrorFilter.r2HalftoneC0284 ||
        MirrorFilter.r2HalftoneC0182 ||
        MirrorFilter.r2HalftoneC0136 ||
        MirrorFilter.r2HalftoneC0031 ||
        MirrorFilter.r2HalftoneC0029 ||
        MirrorFilter.r2MosaicC0460 ||
        MirrorFilter.r2MosaicC0366 ||
        MirrorFilter.r2MosaicC0331 ||
        MirrorFilter.r2MosaicC0289 ||
        MirrorFilter.r2MosaicC0133 ||
        MirrorFilter.r2MosaicC0042 ||
        MirrorFilter.r2MosaicC0041 ||
        MirrorFilter.r2MosaicC0025 ||
        MirrorFilter.labNight ||
        MirrorFilter.labTunnel ||
        MirrorFilter.labMatrix ||
        MirrorFilter.labSnow ||
        MirrorFilter.labRain ||
        MirrorFilter.labTilt ||
        MirrorFilter.labRays ||
        MirrorFilter.labCutout ||
        MirrorFilter.labDuotone ||
        MirrorFilter.labAquarelle ||
        MirrorFilter.labKuwahara ||
        MirrorFilter.labLed ||
        MirrorFilter.labGameboy ||
        MirrorFilter.labVhs ||
        MirrorFilter.labBlocks ||
        MirrorFilter.labBlinds ||
        MirrorFilter.labQuad ||
        MirrorFilter.labTiles ||
        MirrorFilter.labBlackHole ||
        MirrorFilter.labTwirl ||
        MirrorFilter.labFisheye ||
        MirrorFilter.labEngrave ||
        MirrorFilter.labEmboss ||
        MirrorFilter.labSketch ||
        MirrorFilter.labAscii ||
        MirrorFilter.labDither ||
        MirrorFilter.labHalftone ||
        MirrorFilter.labGlass ||
        MirrorFilter.labHex ||
        MirrorFilter.labMosaic ||
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

  /// Round 2 technique families, in chip order. Members are named
  /// `r2<Family><id>`, e.g. `r2KaleidoC0027`.
  static const labFamilies = [
    'Mosaic',
    'Halftone',
    'Sketch',
    'Optics',
    'Kaleido',
    'Tiles',
    'Glitch',
    'Vhs',
    'Face',
    'Layers',
    'Paint',
    'Color',
    'Light',
  ];

  /// Lab sub-chips: earlier rounds paged by [FilterCollection.labGroupSize],
  /// then one chip per round 2 family.
  static final List<({String label, List<MirrorFilter> filters})> labGroups =
      () {
    final lab = inCollection(FilterCollection.experimental);
    final older = lab.where((f) => !f.name.startsWith('r2')).toList();
    const size = FilterCollection.labGroupSize;
    return [
      for (var s = 0; s < older.length; s += size)
        (
          label: '${s + 1}–${(s + size).clamp(0, older.length)}',
          filters: older.sublist(s, (s + size).clamp(0, older.length)),
        ),
      for (final fam in labFamilies)
        if (lab.where((f) => f.name.startsWith('r2$fam')).toList()
            case final fs when fs.isNotEmpty)
          (label: fam == 'Vhs' ? 'VHS' : fam, filters: fs),
    ];
  }();

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
        MirrorFilter.labMosaic => 'shaders/filter_lab_mosaic.frag',
        MirrorFilter.labHex => 'shaders/filter_lab_hex.frag',
        MirrorFilter.labGlass => 'shaders/filter_lab_glass.frag',
        MirrorFilter.labHalftone => 'shaders/filter_lab_halftone.frag',
        MirrorFilter.labDither => 'shaders/filter_lab_dither.frag',
        MirrorFilter.labAscii => 'shaders/filter_lab_ascii.frag',
        MirrorFilter.labSketch => 'shaders/filter_lab_sketch.frag',
        MirrorFilter.labEmboss => 'shaders/filter_lab_emboss.frag',
        MirrorFilter.labEngrave => 'shaders/filter_lab_engrave.frag',
        MirrorFilter.labFisheye => 'shaders/filter_lab_fisheye.frag',
        MirrorFilter.labTwirl => 'shaders/filter_lab_twirl.frag',
        MirrorFilter.labBlackHole => 'shaders/filter_lab_black_hole.frag',
        MirrorFilter.labTiles => 'shaders/filter_lab_tiles.frag',
        MirrorFilter.labQuad => 'shaders/filter_lab_quad.frag',
        MirrorFilter.labBlinds => 'shaders/filter_lab_blinds.frag',
        MirrorFilter.labBlocks => 'shaders/filter_lab_blocks.frag',
        MirrorFilter.labVhs => 'shaders/filter_lab_vhs.frag',
        MirrorFilter.labGameboy => 'shaders/filter_lab_gameboy.frag',
        MirrorFilter.labLed => 'shaders/filter_lab_led.frag',
        MirrorFilter.labKuwahara => 'shaders/filter_lab_kuwahara.frag',
        MirrorFilter.labAquarelle => 'shaders/filter_lab_aquarelle.frag',
        MirrorFilter.labDuotone => 'shaders/filter_lab_duotone.frag',
        MirrorFilter.labCutout => 'shaders/filter_lab_cutout.frag',
        MirrorFilter.labRays => 'shaders/filter_lab_rays.frag',
        MirrorFilter.labTilt => 'shaders/filter_lab_tilt.frag',
        MirrorFilter.labRain => 'shaders/filter_lab_rain.frag',
        MirrorFilter.labSnow => 'shaders/filter_lab_snow.frag',
        MirrorFilter.labMatrix => 'shaders/filter_lab_matrix.frag',
        MirrorFilter.labTunnel => 'shaders/filter_lab_tunnel.frag',
        MirrorFilter.labNight => 'shaders/filter_lab_night.frag',
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
        // @shadergen:shaderAsset
      };
}
