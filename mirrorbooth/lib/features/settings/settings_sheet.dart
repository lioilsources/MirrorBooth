import 'package:flutter/material.dart';
import 'package:ol1n_telemetry/ol1n_telemetry.dart';

import '../../l10n/l10n.dart';

/// The app's only setting so far: the anonymous statistics switch. The
/// button that opens it is shown only when the build can measure at all
/// (`Telemetry.isConfigured`).
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black26,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: SwitchListTile(
          key: const Key('stats-toggle'),
          title: Text(
            l10n.statsToggle,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            l10n.statsToggleHint,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          value: Telemetry.isEnabled,
          onChanged: (on) async {
            await Telemetry.setEnabled(on);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}
