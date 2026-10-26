import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/mirror_side.dart';
import '../../l10n/l10n.dart';
import 'call_controller.dart';
import 'call_screen.dart';

class RoomEntryScreen extends ConsumerStatefulWidget {
  const RoomEntryScreen({super.key});

  @override
  ConsumerState<RoomEntryScreen> createState() => _RoomEntryScreenState();
}

class _RoomEntryScreenState extends ConsumerState<RoomEntryScreen> {
  final _controller = TextEditingController();
  MirrorSide _side = MirrorSide.left;
  bool _joining = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final room = _controller.text.trim();
    if (room.isEmpty) return;

    setState(() => _joining = true);
    try {
      await ref.read(callProvider.notifier).joinCall(room, _side);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CallScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToJoin('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('FaceTimeMirrorBooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.roomEntryPrompt,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.l10n.roomIdHint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.mirrorSideTitle,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MirrorSide>(
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.white,
                selectedForegroundColor: Colors.black,
                selectedBackgroundColor: Colors.white,
              ),
              segments: [
                ButtonSegment(
                    value: MirrorSide.left, label: Text(context.l10n.mirrorSideLeft)),
                ButtonSegment(
                    value: MirrorSide.right, label: Text(context.l10n.mirrorSideRight)),
              ],
              selected: {_side},
              onSelectionChanged: (s) => setState(() => _side = s.first),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _joining ? null : _join,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _joining
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.joinCall,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
