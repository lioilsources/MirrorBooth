import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> start(String outputPath) async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: outputPath,
    );
  }

  /// Returns the final file path written by the recorder.
  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}
