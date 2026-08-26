import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/mirror_preview/mirror_preview_screen.dart';
import 'features/paywall/entitlement_controller.dart';
import 'features/video_call/room_entry_screen.dart';

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
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MirrorBoothApp(),
  ));
}

class MirrorBoothApp extends StatelessWidget {
  const MirrorBoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MirrorBooth',
      debugShowCheckedModeBanner: false,
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
