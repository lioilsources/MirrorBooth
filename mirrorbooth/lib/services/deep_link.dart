import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/mirror_filter.dart';

/// Where a deep link sends the user. Links come from In-App Events, Custom
/// Product Pages, custom Play listings and shared posts, in two spellings:
///
///   mirrorbooth://collection/art          (custom scheme)
///   https://olin.now/mirror/collection/art (universal link / App Link)
///
/// Paths: `camera`, `collection/<pretty|ugly|art|fantasy>`,
/// `f/<filter>` (also `filter/<filter>`) and `event/<id>`. Anything else
/// opens the camera with nothing changed, never an error.
class DeepLink {
  /// The filter to switch to, or null to just show the camera.
  final MirrorFilter? filter;

  const DeepLink({this.filter});

  static const camera = DeepLink();

  /// In-App Event IDs and the filter each one opens on. New events add a
  /// line here; an event the build does not know yet still opens the app.
  static const events = <String, MirrorFilter>{
    'holiday': MirrorFilter.frozen,
    'newyear': MirrorFilter.glow,
    'valentine': MirrorFilter.lips,
    'artweek': MirrorFilter.pencil,
    'halloween': MirrorFilter.zombie,
  };

  static DeepLink parse(Uri uri) {
    final segments = switch (uri.scheme) {
      'mirrorbooth' => [
          if (uri.host.isNotEmpty) uri.host,
          ...uri.pathSegments,
        ],
      'https' || 'http' when uri.host == 'olin.now' =>
        uri.pathSegments.skipWhile((s) => s == 'mirror').toList(),
      _ => const <String>[],
    };
    final parts = [
      for (final s in segments)
        if (s.isNotEmpty) s.toLowerCase(),
    ];
    if (parts.length < 2) return camera;
    final arg = parts[1];
    return switch (parts.first) {
      'collection' => _collection(arg),
      'f' || 'filter' => DeepLink(filter: _filter(arg)),
      'event' => DeepLink(filter: events[arg]),
      _ => camera,
    };
  }

  static DeepLink _collection(String name) {
    for (final c in FilterCollection.visible) {
      if (c.name == name) {
        final filters = MirrorFilter.inCollection(c);
        return DeepLink(filter: filters.isEmpty ? null : filters.first);
      }
    }
    return camera;
  }

  /// Matches the enum name case-insensitively, plus snake/kebab spellings
  /// (`pop-art`, `big_nose`).
  static MirrorFilter? _filter(String name) {
    final key = name.replaceAll(RegExp('[-_]'), '');
    for (final f in MirrorFilter.values) {
      if (f != MirrorFilter.none &&
          f.collection?.isVisible != false &&
          f.name.toLowerCase() == key) {
        return f;
      }
    }
    return null;
  }
}

/// The latest deep link not yet applied; MirrorPreviewScreen consumes it.
/// A plain provider (not the autoDispose camera one) so a link that arrives
/// before the camera screen exists, on a cold start, is kept.
final pendingDeepLinkProvider = StateProvider<DeepLink?>((_) => null);
