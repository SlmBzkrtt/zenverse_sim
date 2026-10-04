# ZenVerse: Chill Object Sim (v1.0.0)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Release-v1.0.0-4CAF50)](#)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20macOS-FF8C42)](#platform-support)

**ZenVerse: Chill Object Sim** is an ambient, interactive **6-in-1 360° chill object simulation & meditation experience** built entirely with Flutter's hardware-accelerated Skia/Impeller `Canvas` engine and procedural PCM audio synthesis.

> *"No quests. No scores. No timers to beat. Simply become a grounded object in the center of a living 360° world and watch life unfold around you."*

---

## 🌍 The 6 Living 360° Simulation Worlds

Each world features a full **360° spherical-projected horizon**, **5 distinct character styles**, **4 dynamic weather/time-of-day atmospheres**, **5 camera orbit modes**, **interactive scenic Point-of-Interest (POI) quick-look chips**, **20 contemplative thoughts**, and a **Cinematic Desk Clock Display Mode**.

| # | World | Object Identity | 360° Landmarks & Living Details | Styles (5) | Atmospheres (4) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | **Coconut Simulator** | 🥥 Pacific Beach Coconut | Two-story beach village, campfire guitarist & 7 friends, lively Tiki Bar, wooden pier, jumping dolphins, wishing lanterns, volleyball match, lighthouse & volcanic islands. | Realistic, Arcade, Cocktail, Island King, Lo-Fi Chill | Sunset, Bioluminescent Night, Tropical Noon, Lo-Fi Rain |
| **2** | **Pine Tree Simulator** | 🌲 Lapland Alpine Pine | Stone viaduct bridge with steaming Polar Express train, frozen glacier lake ice skaters & igloo, Norwegian Stavkirke wooden church, ski slope, husky sled camp, cable car & dancing Aurora Borealis. | Realistic, Ski Goggles, Christmas Pine, Wise Ent, Lo-Fi Pine | Aurora Twilight, Polar Night, Alpine Sun, Blizzard |
| **3** | **Mossy Rock Simulator** | 🪨 Kyoto Zen Temple Rock | Snow-capped Mount Fuji, Floating Lake Torii gate, Golden Pavilion (*Kinkaku-ji*), bamboo water spout (*Kakei*) & *Shishi-odoshi*, vermilion arched bridge, Wisteria tunnel, 5-story Pagoda, steaming Onsen with Capybara & snow monkeys. | Realistic, Karate Rock, Sacred Shimenawa, Sakura Spirit, Lo-Fi Zen | Crimson Kyoto, Lantern Night, Zen Noon, Bamboo Rain |
| **4** | **Street Lamp Simulator** | 🏮 European Plaza Street Lamp | Wet cobblestone plaza reflections, stone river bridge, illuminated panoramic tower, sparking vintage yellow tram, street painter, fountain musicians, *Café de Nuit* saxophonist, jazz club, ramen stall, *Metropolitain* arch & carousel. | Realistic, Cyberpunk, Jazz Lantern, Royal Gold, Lo-Fi Cat | Twilight, Midnight, City Noon, Lo-Fi Rain |
| **5** | **Cactus Simulator** | 🌵 Red Canyon Saguaro Cactus | Red sandstone canyon buttes, 16 rising hot air balloons, high timber trestle Wild West steam train, canyon waterfall & emerald oasis with flamingos, 6-camel caravan, carved Petra Treasury (*Al-Khazneh*), Bedouin fire, pyramid & observatory. | Realistic, Cowboy Sheriff, Mariachi, Oasis King, Lo-Fi Mirage | Red Canyon Sunset, Milky Way Night, Desert Sun, Desert Monsoon |
| **6** | **Christmas Tree Simulator** | 🎄 Cologne Christmas Market Tree | Twin-spired Gothic Cologne Cathedral (*Kölner Dom*), *Sternenzelt* starlight canopy, Heumarkt open-air ice rink, Altstadt timbered houses, diverse Christmas market stalls (*Glühwein*, *Bratwurst* Schwenkgrill, sweets, crafts), spinning Christmas pyramid, Ferris wheel & Hohenzollern Bridge with ICE train over the Rhine. | Realistic, Santa Claus, Glühwein Fiesta, Royal Gold, Lo-Fi Winter | Christmas Twilight, New Year's Eve, Winter Sun, Heavy Snowfall |

---

## 🏗️ Architecture & Performance Engineering

```text
lib/
├── main.dart                                      # App entry point, Portrait lock, Edge-to-Edge UI, asset pre-warming
├── core/
│   └── game_constants.dart                        # Centralized constants, physics parameters & ResponsiveViewport
├── controllers/
│   └── zenverse_controller.dart                   # ChangeNotifier 60-120 FPS render controller & camera physics
├── models/
│   └── zenverse_model.dart                        # ZenVerseModel, ScenicPoint, DirectionZone & 6 world definitions
├── painters/
│   ├── coconut_world_painter.dart                 # World 1: Pacific Beach Village 360° CustomPainter
│   ├── pine_forest_world_painter.dart             # World 2: Lapland & Polar Express 360° CustomPainter
│   ├── zen_valley_world_painter.dart              # World 3: Kyoto Zen Valley & Onsen 360° CustomPainter
│   ├── street_lamp_world_painter.dart             # World 4: European Night Plaza 360° CustomPainter
│   ├── desert_cactus_world_painter.dart           # World 5: Red Canyon & Petra 360° CustomPainter
│   └── cologne_christmas_world_painter.dart       # World 6: Cologne Cathedral & Market 360° Hybrid Texture/Vector Painter
├── screens/
│   ├── main_menu_screen.dart                      # Interactive 360° live preview stage & swipeable world selector
│   └── coconut_simulator_screen.dart              # Fullscreen 360° simulator HUD, POI chips & Cinematic Display Mode
└── services/
    ├── audio_service.dart                         # Procedural 16-bit PCM WAV ambient drone & harmonic chime synthesizer
    └── storage_service.dart                       # SharedPreferences persistence for world, style, atmosphere & meditation time
```

### Key Technical Highlights
1. **Zero-Widget-Rebuild 60–120 FPS Render Loop:**
   - `ZenVerseController` (`ChangeNotifier`) is passed directly to `CustomPainter(repaint: controller)` inside an isolated `RepaintBoundary`.
   - `Ticker` frame updates never trigger `setState()` on `MainMenuScreen` or `CoconutSimulatorScreen`. Glassmorphic `BackdropFilter` HUD layers remain completely static while only the canvas layer repaints.
   - HUD telemetry badges (`roundedYawNotifier` and `elapsedSecondsNotifier`) use coarse integer `ValueNotifier<int>` instances so text labels update only when an integer degree or second changes.
2. **FOV Frustum Culling & Reusable Paint Objects:**
   - Every 360° landmark is projected through `_worldAngleToScreenX()`, immediately culling off-screen geometry outside the active field of view.
   - Class-level reusable `Paint` instances avoid per-frame allocations and garbage collection pauses on mobile devices.
3. **Lifecycle-Aware Resource Management:**
   - Both screens implement `WidgetsBindingObserver` (`didChangeAppLifecycleState`) to automatically pause `Ticker` loops, timers, and ambient audio when backgrounded, preventing battery drain and thermal throttling.
4. **Responsive & Adaptive Layout (`ResponsiveViewport`):**
   - Built with `LayoutBuilder`, `SafeArea`, `FittedBox`, and `AspectRatio` to scale seamlessly across compact phones, foldables, tablets, and desktop windows without pixel overflows.
5. **Procedural Ambient Audio Engine (`AudioService`):**
   - Synthesizes warm, looping stereo WAV soundscapes and harmonic interaction chimes directly in memory via `audioplayers` (`BytesSource`), requiring zero external MP3/OGG downloads.

---

## 📱 Platform Support & Store Readiness

- **App Name:** `ZenVerse: Chill Object Sim`
- **Package / Bundle ID:** `com.selimbozkurt.zenverse_sim`
- **Version:** `1.0.0+1`
- **Orientation:** Portrait (`DeviceOrientation.portraitUp`)
- **Supported Targets:**
  - **Android:** API 21+ (`minSdk >= 21`), R8 code shrinking & ProGuard rules configured (`android/app/proguard-rules.pro`).
  - **iOS:** iOS 12.0+, `CADisableMinimumFrameDurationOnPhone` enabled for 120Hz ProMotion displays, `ITSAppUsesNonExemptEncryption = false`.
  - **macOS:** Native desktop window & trackpad/keyboard navigation support.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.13.3` (or latest stable Flutter 3.x)
- Xcode (for iOS / macOS builds) or Android Studio (for Android builds)

### Installation & Run
```bash
# 1. Clean and fetch dependencies
flutter clean && flutter pub get

# 2. Run static analysis & widget test suite
flutter analyze
flutter test

# 3. Launch on your target device
flutter run -d macos     # macOS Desktop
flutter run -d ios       # iOS Simulator / Device
flutter run -d android   # Android Emulator / Device
```

### Generating Store Icons & Native Splash (Optional)
Configuration templates for `flutter_launcher_icons` and `flutter_native_splash` are pre-configured in `pubspec.yaml`:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Production Store Builds
```bash
# Android App Bundle (Google Play)
flutter build appbundle --release

# iOS Archive (App Store Connect)
flutter build ipa --release
```

---

## 📄 License

Copyright © 2026 Selim Bozkurt (`com.selimbozkurt.zenverse_sim`). All rights reserved.
