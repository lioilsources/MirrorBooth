import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../l10n/l10n.dart';
import 'audio_effect_strip.dart';
import 'video_recording_notifier.dart';
import 'video_recording_state.dart';

class VideoPlaybackScreen extends ConsumerStatefulWidget {
  const VideoPlaybackScreen({super.key});

  @override
  ConsumerState<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends ConsumerState<VideoPlaybackScreen> {
  VideoPlayerController? _controller;
  String? _currentPath;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer(String path) async {
    if (path == _currentPath) return;
    await _controller?.dispose();
    _currentPath = path;
    final c = VideoPlayerController.file(File(path));
    _controller = c;
    await c.initialize();
    await c.setLooping(true);
    await c.play();
    if (mounted) setState(() {});
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(videoRecordingProvider);
    if (state.isSaved) {
      await ref.read(videoRecordingProvider.notifier).discardAndReturnToCamera();
      return false;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(l10n.discardVideoTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.discardVideoBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keep, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(videoRecordingProvider.notifier).discardAndReturnToCamera();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoRecordingProvider);
    final notifier = ref.read(videoRecordingProvider.notifier);
    final l10n = context.l10n;

    // Keep player in sync with video path changes.
    final path = state.playbackPath;
    if (state.phase == RecordingPhase.playback && path != null && !state.isApplyingEffect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initPlayer(path);
      });
    }

    final safeTop = MediaQuery.of(context).padding.top;
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            if (isReady)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white54)),

            // Assembling overlay
            if (state.phase == RecordingPhase.assembling)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        l10n.processing,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Effect re-encoding banner
            if (state.isApplyingEffect)
              Positioned(
                top: safeTop + 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.applyingEffect,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Back (X) button
            if (state.phase == RecordingPhase.playback)
              PositionedDirectional(
                top: safeTop + 16,
                start: 16,
                child: GestureDetector(
                  onTap: _onWillPop,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),

            // Save button + audio effect strip
            if (state.phase == RecordingPhase.playback) ...[
              // Audio effect strip
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: AudioEffectStrip(
                  selected: state.selectedEffect,
                  isProcessing: state.isApplyingEffect,
                  onSelect: notifier.applyAudioEffect,
                ),
              ),

              // Save button
              Positioned(
                bottom: 32,
                left: 40,
                right: 40,
                child: GestureDetector(
                  onTap: state.isSaved ? null : notifier.saveVideo,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 54,
                    decoration: BoxDecoration(
                      color: state.isSaved ? Colors.white24 : Colors.white,
                      borderRadius: BorderRadius.circular(27),
                    ),
                    child: Center(
                      child: Text(
                        state.isSaved ? l10n.saved : l10n.saveToCameraRoll,
                        style: TextStyle(
                          color: state.isSaved ? Colors.white54 : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Error banner
            if (state.error != null)
              Positioned(
                bottom: 180,
                left: 24,
                right: 24,
                child: Material(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!.message(l10n),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: notifier.clearError,
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
