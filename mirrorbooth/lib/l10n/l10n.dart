import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';

import '../core/mirror_filter.dart';
import '../core/mirror_side.dart';
import '../features/mirror_preview/mirror_preview_controller.dart';
import '../features/video_recording/video_recording_state.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension MirrorFilterL10n on MirrorFilter {
  /// Localized chip label. Falls back to the English [label] for filters the
  /// ShaderGen pipeline adds before they get an ARB entry.
  String localizedLabel(AppLocalizations l) => switch (this) {
        MirrorFilter.none => l.filterNone,
        MirrorFilter.glow => l.filterGlow,
        MirrorFilter.slim => l.filterSlim,
        MirrorFilter.doll => l.filterDoll,
        MirrorFilter.chibi => l.filterChibi,
        MirrorFilter.lips => l.filterLips,
        MirrorFilter.bigNose => l.filterBigNose,
        MirrorFilter.alien => l.filterAlien,
        MirrorFilter.melt => l.filterMelt,
        MirrorFilter.bigEars => l.filterBigEars,
        MirrorFilter.longNeck => l.filterLongNeck,
        MirrorFilter.pencil => l.filterPencil,
        MirrorFilter.comic => l.filterComic,
        MirrorFilter.glitch => l.filterGlitch,
        MirrorFilter.neon => l.filterNeon,
        MirrorFilter.thermal => l.filterThermal,
        MirrorFilter.oil => l.filterOil,
        MirrorFilter.crt => l.filterCrt,
        MirrorFilter.popArt => l.filterPopArt,
        MirrorFilter.vampire => l.filterVampire,
        MirrorFilter.zombie => l.filterZombie,
        MirrorFilter.ghost => l.filterGhost,
        MirrorFilter.demon => l.filterDemon,
        MirrorFilter.cyborg => l.filterCyborg,
        MirrorFilter.frozen => l.filterFrozen,
        // ignore: unreachable_switch_case
        _ => label,
      };
}

extension FilterCollectionL10n on FilterCollection {
  String localizedLabel(AppLocalizations l) => switch (this) {
        FilterCollection.pretty => l.collectionPretty,
        FilterCollection.ugly => l.collectionUgly,
        FilterCollection.art => l.collectionArt,
        FilterCollection.fantasy => l.collectionFantasy,
      };
}

extension AudioEffectL10n on AudioEffect {
  String localizedLabel(AppLocalizations l) => switch (this) {
        AudioEffect.none => l.audioEffectNone,
        AudioEffect.chiptune => l.audioEffectChiptune,
        AudioEffect.slowMo => l.audioEffectSlowMo,
        AudioEffect.chipmunk => l.audioEffectChipmunk,
        AudioEffect.echo => l.audioEffectEcho,
        AudioEffect.underwater => l.audioEffectUnderwater,
        AudioEffect.robot => l.audioEffectRobot,
        AudioEffect.reverse => l.audioEffectReverse,
      };
}

extension MirrorSideL10n on MirrorSide {
  String shortLabel(AppLocalizations l) =>
      isLeft ? l.mirrorSideLeftShort : l.mirrorSideRightShort;
}

extension PreviewErrorL10n on PreviewError {
  String message(AppLocalizations l) => switch (this) {
        PreviewError.cameraPermissionDenied => l.cameraPermissionDenied,
        PreviewError.noCameras => l.noCamerasAvailable,
        PreviewError.cameraStartFailed => l.cameraStartFailed,
      };
}

extension RecordingErrorL10n on RecordingError {
  String message(AppLocalizations l) => switch (this) {
        RecordingError.micPermission => l.micPermissionRequired,
        RecordingError.tooShort => l.recordingTooShort,
        RecordingError.assemblyFailed => l.videoAssemblyFailed,
        RecordingError.audioEffectFailed => l.audioEffectFailed,
        RecordingError.galleryAccessDenied => l.galleryAccessDenied,
        RecordingError.galleryNotEnoughSpace => l.galleryNotEnoughSpace,
        RecordingError.galleryUnsupportedFormat => l.galleryUnsupportedFormat,
        RecordingError.unexpected => l.genericError,
      };
}

String galErrorMessage(AppLocalizations l, GalExceptionType type) =>
    switch (type) {
      GalExceptionType.accessDenied => l.galleryAccessDenied,
      GalExceptionType.notEnoughSpace => l.galleryNotEnoughSpace,
      GalExceptionType.notSupportedFormat => l.galleryUnsupportedFormat,
      _ => l.genericError,
    };
