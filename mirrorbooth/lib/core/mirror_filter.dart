enum MirrorFilter {
  none,
  pencil,
  comic,
  celShade,
  glitch,
  pixelArt;

  String get label => switch (this) {
        MirrorFilter.none => 'None',
        MirrorFilter.pencil => 'Pencil',
        MirrorFilter.comic => 'Comic',
        MirrorFilter.celShade => 'Cel',
        MirrorFilter.glitch => 'Glitch',
        MirrorFilter.pixelArt => 'Pixel',
      };

  String get icon => switch (this) {
        MirrorFilter.none => 'O',
        MirrorFilter.pencil => '/',
        MirrorFilter.comic => '!',
        MirrorFilter.celShade => '*',
        MirrorFilter.glitch => '~',
        MirrorFilter.pixelArt => '#',
      };

  String? get shaderAsset => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.pencil => 'shaders/filter_pencil.frag',
        MirrorFilter.comic => 'shaders/filter_comic.frag',
        MirrorFilter.celShade => 'shaders/filter_cel_shade.frag',
        MirrorFilter.glitch => 'shaders/filter_glitch.frag',
        MirrorFilter.pixelArt => 'shaders/filter_pixel_art.frag',
      };
}
