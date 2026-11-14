import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ol1n_telemetry/ol1n_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/mirror_preview/mirror_preview_screen.dart';
import 'features/paywall/entitlement_controller.dart';
import 'features/video_call/room_entry_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/deep_link.dart';
import 'services/review_prompter.dart';
import 'telemetry/telemetry_dictionary.dart';
import 'telemetry/telemetry_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  // Preloaded so cached entitlements are readable synchronously on first
  // build — owners never see a locked-badge flash.
  final prefs = await SharedPreferences.getInstance();
  // Before the first prefs write of this launch (the review prompter's
  // launch counter), so a returning user is not counted as a new install.
  startTelemetry(prefs);
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MirrorBoothApp(),
  ));
}

class MirrorBoothApp extends ConsumerStatefulWidget {
  const MirrorBoothApp({super.key});

  @override
  ConsumerState<MirrorBoothApp> createState() => _MirrorBoothAppState();
}

class _MirrorBoothAppState extends ConsumerState<MirrorBoothApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _screens = TelemetryNavigatorObserver(kScreenRoutes);
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    ref.read(reviewPrompterProvider).recordLaunch();
    // Emits the link that launched the app first, then any later ones.
    _links = AppLinks().uriLinkStream.listen(
      _open,
      onError: (Object e) => debugPrint('deep link: $e'),
    );
  }

  void _open(Uri uri) {
    debugPrint('deep link: $uri');
    final link = DeepLink.parse(uri);
    Telemetry.track('link_open', {'filter': link.filter != null});
    // Back to the camera from playback or the call screen.
    _navigator.currentState?.popUntil((route) => route.isFirst);
    ref.read(pendingDeepLinkProvider.notifier).state = link;
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      navigatorObservers: [_screens],
      title: 'MirrorBooth',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const MirrorPreviewScreen(),
        '/call': (_) => const RoomEntryScreen(),
      },
    );
  }
}
