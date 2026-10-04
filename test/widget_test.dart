import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenverse_sim/main.dart';
import 'package:zenverse_sim/models/zenverse_model.dart';
import 'package:zenverse_sim/screens/coconut_simulator_screen.dart';

void main() {
  testWidgets(
      'App smoke test - launches menu, tests quick selector & preview controls, and navigates to Coconut Simulator',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ZenVerseApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ZENVERSE: CHILL OBJECT SIM'), findsOneWidget);
    expect(find.text('Coconut Simulator'), findsOneWidget);

    // Test live preview atmosphere toggle on the Main Menu
    expect(find.text('Atmosfer: 🌅 Gün Batımı'), findsOneWidget);
    await tester.tap(find.text('Atmosfer: 🌅 Gün Batımı'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Atmosfer: 🌙 Gece'), findsOneWidget);

    // Test switching to simulator #6 (Cologne Christmas Tree) via quick-select pill
    expect(find.text('6. 🎄 Noel Ağacı'), findsOneWidget);
    await tester.tap(find.text('6. 🎄 Noel Ağacı'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('1 / 6 DÜNYA'), findsNothing);
    expect(find.text('6 / 6 DÜNYA'), findsOneWidget);

    // Switch back to simulator #1 (Coconut) via quick-select pill
    await tester.tap(find.text('1. 🥥 Coconut'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('1 / 6 DÜNYA'), findsOneWidget);

    final enterButton = find.text('SİMÜLASYONA BAŞLA (HİNDİSTAN CEVİZİ OL)');
    expect(enterButton, findsOneWidget);
    await tester.tap(enterButton);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CoconutSimulatorScreen), findsOneWidget);
    expect(find.text('🥥 Realistic'), findsOneWidget);
    expect(find.text('360° Oto'), findsOneWidget);

    // Toggle to Arcade Mode
    await tester.tap(find.text('🥥 Realistic'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('🕶️ Arcade'), findsOneWidget);

    // Toggle 360° Oto
    await tester.tap(find.text('360° Oto'));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap quick look chip inside CoconutSimulatorScreen
    final sunsetChip = find.descendant(
      of: find.byType(CoconutSimulatorScreen),
      matching: find.text('🌅 Gün Batımı (0°)'),
    );
    expect(sunsetChip, findsOneWidget);
    await tester.tap(sunsetChip);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets(
      'All 6 simulators render their 360 worlds, styles, atmospheres, and display modes without errors',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(availableSimulators.length, 6);
    for (final sim in availableSimulators) {
      expect(sim.isUnlocked, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          home: CoconutSimulatorScreen(simulator: sim),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify scenic chips exist and test rotating to scenic points
      for (final point in sim.scenicPoints) {
        expect(find.text(point.label), findsOneWidget);
        await tester.tap(find.text(point.label));
        await tester.pump(const Duration(milliseconds: 120));
      }

      // Cycle through all 5 styles and 4 atmospheres
      for (int s = 0; s < 5; s++) {
        await tester.tap(find.text(sim.styleLabels[s]));
        await tester.pump(const Duration(milliseconds: 80));
      }
      for (int a = 0; a < 4; a++) {
        await tester.tap(find.text(sim.atmosphereLabels[a]));
        await tester.pump(const Duration(milliseconds: 80));
      }

      // Toggle Display mode on and off
      await tester.tap(find.text('🖥️ Display'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.tv_off_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tv_off_rounded));
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
