enum MirrorFilter {
  none,
  pencil,
  comic,
  celShade,
  glitch,
  pixelArt,
  neon,
  watercolor,
  charcoal,
  halftone,
  thermal,
  psychedelic,
  oil,
  crt;

  String get label => switch (this) {
        MirrorFilter.none => 'None',
        MirrorFilter.pencil => 'Pencil',
        MirrorFilter.comic => 'Comic',
        MirrorFilter.celShade => 'Cel',
        MirrorFilter.glitch => 'Glitch',
        MirrorFilter.pixelArt => 'Pixel',
        MirrorFilter.neon => 'Neon',
        MirrorFilter.watercolor => 'Water',
        MirrorFilter.charcoal => 'Coal',
        MirrorFilter.halftone => 'Dots',
        MirrorFilter.thermal => 'Heat',
        MirrorFilter.psychedelic => 'Psych',
        MirrorFilter.oil => 'Oil',
        MirrorFilter.crt => 'CRT',
      };

  String get icon => switch (this) {
        MirrorFilter.none => 'O',
        MirrorFilter.pencil => '/',
        MirrorFilter.comic => '!',
        MirrorFilter.celShade => '*',
        MirrorFilter.glitch => '~',
        MirrorFilter.pixelArt => '#',
        MirrorFilter.neon => 'N',
        MirrorFilter.watercolor => 'W',
        MirrorFilter.charcoal => 'C',
        MirrorFilter.halftone => '.',
        MirrorFilter.thermal => 'T',
        MirrorFilter.psychedelic => 'P',
        MirrorFilter.oil => 'Q',
        MirrorFilter.crt => 'V',
      };

  bool get needsTime => switch (this) {
        MirrorFilter.glitch => true,
        MirrorFilter.neon => true,
        MirrorFilter.psychedelic => true,
        _ => false,
      };

  String? get shaderAsset => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.pencil => 'shaders/filter_pencil.frag',
        MirrorFilter.comic => 'shaders/filter_comic.frag',
        MirrorFilter.celShade => 'shaders/filter_cel_shade.frag',
        MirrorFilter.glitch => 'shaders/filter_glitch.frag',
        MirrorFilter.pixelArt => 'shaders/filter_pixel_art.frag',
        MirrorFilter.neon => 'shaders/filter_neon.frag',
        MirrorFilter.watercolor => 'shaders/filter_watercolor.frag',
        MirrorFilter.charcoal => 'shaders/filter_charcoal.frag',
        MirrorFilter.halftone => 'shaders/filter_halftone.frag',
        MirrorFilter.thermal => 'shaders/filter_thermal.frag',
        MirrorFilter.psychedelic => 'shaders/filter_psychedelic.frag',
        MirrorFilter.oil => 'shaders/filter_oil.frag',
        MirrorFilter.crt => 'shaders/filter_crt.frag',
      };
}
