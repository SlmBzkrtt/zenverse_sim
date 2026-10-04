import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/game_constants.dart';
import 'painters/cologne_christmas_world_painter.dart';
import 'screens/main_menu_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local persistence & pre-warm Cologne Christmas texture assets
  await StorageService.instance.init();
  CologneChristmasAssets.ensureLoaded();

  // Lock preferred orientation to Portrait (portraitUp)
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  // Configure edge-to-edge immersive system UI overlay for iOS & Android
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ZenVerseApp());
}

class ZenVerseApp extends StatelessWidget {
  const ZenVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF8C42),
        scaffoldBackgroundColor: const Color(0xFF0E1124),
      ),
      home: const MainMenuScreen(),
    );
  }
}
