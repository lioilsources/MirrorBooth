enum RecordingPhase { idle, recording, assembling, playback }

enum AudioEffect {
  none,
  chiptune,
  slowMo,
  chipmunk,
  echo,
  underwater,
  robot,
  reverse,
}

extension AudioEffectLabel on AudioEffect {
  String get label {
    switch (this) {
      case AudioEffect.none:
        return 'Normal';
      case AudioEffect.chiptune:
        return '8-bit';
      case AudioEffect.slowMo:
        return 'Slow';
      case AudioEffect.chipmunk:
        return 'Chipmunk';
      case AudioEffect.echo:
        return 'Echo';
      case AudioEffect.underwater:
        return 'Underwater';
      case AudioEffect.robot:
        return 'Robot';
      case AudioEffect.reverse:
        return 'Reverse';
    }
  }

  String get icon {
    switch (this) {
      case AudioEffect.none:
        return '▶';
      case AudioEffect.chiptune:
        return '🎮';
      case AudioEffect.slowMo:
        return '🐢';
      case AudioEffect.chipmunk:
        return '🐿';
      case AudioEffect.echo:
        return '🔁';
      case AudioEffect.underwater:
        return '🌊';
      case AudioEffect.robot:
        return '🤖';
      case AudioEffect.reverse:
        return '⏪';
    }
  }
}

class VideoRecordingState {
  final RecordingPhase phase;
  final Duration elapsed;
  final String? rawVideoPath;
  final String? finalVideoPath;
  final AudioEffect selectedEffect;
  final bool isSaved;
  final bool isApplyingEffect;
  final String? errorMessage;

  const VideoRecordingState({
    this.phase = RecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.rawVideoPath,
    this.finalVideoPath,
    this.selectedEffect = AudioEffect.none,
    this.isSaved = false,
    this.isApplyingEffect = false,
    this.errorMessage,
  });

  String? get playbackPath => finalVideoPath ?? rawVideoPath;

  VideoRecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    String? rawVideoPath,
    String? finalVideoPath,
    AudioEffect? selectedEffect,
    bool? isSaved,
    bool? isApplyingEffect,
    String? errorMessage,
  }) =>
      VideoRecordingState(
        phase: phase ?? this.phase,
        elapsed: elapsed ?? this.elapsed,
        rawVideoPath: rawVideoPath ?? this.rawVideoPath,
        finalVideoPath: finalVideoPath ?? this.finalVideoPath,
        selectedEffect: selectedEffect ?? this.selectedEffect,
        isSaved: isSaved ?? this.isSaved,
        isApplyingEffect: isApplyingEffect ?? this.isApplyingEffect,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
