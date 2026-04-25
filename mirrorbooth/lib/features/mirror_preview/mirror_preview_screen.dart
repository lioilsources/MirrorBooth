import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mirror_canvas.dart';
import 'mirror_preview_controller.dart';
import 'side_toggle_button.dart';

class MirrorPreviewScreen extends ConsumerWidget {
  const MirrorPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mirrorPreviewProvider);
    final notifier = ref.read(mirrorPreviewProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _body(context, state, notifier),
    );
  }

  Widget _body(
    BuildContext context,
    MirrorPreviewState state,
    MirrorPreviewController notifier,
  ) {
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            state.error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!state.isReady || state.controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MirrorCanvas(
          controller: state.controller!,
          side: state.side,
        ),
        // Center seam indicator
        Center(
          child: Container(
            width: 1,
            color: Colors.white12,
          ),
        ),
        // Controls
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SideToggleButton(
                current: state.side,
                onToggle: notifier.toggleSide,
              ),
            ],
          ),
        ),
        // Call button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 20,
          child: _CallButton(),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/call'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
        ),
        child: const Icon(Icons.video_call_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
