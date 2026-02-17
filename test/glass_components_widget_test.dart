import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:settle/theme/settle_design_system.dart';
import 'package:settle/widgets/glass_card.dart';
import 'package:settle/widgets/glass_chip.dart';
import 'package:settle/widgets/glass_nav_bar.dart';
import 'package:settle/widgets/glass_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Ensure GoogleFonts.inter(w500) can load in widget tests without network.
    const interAssetKey = 'assets/test_fonts/Inter-Medium.ttf';
    final seedPath = _existingFontSeedPath();
    final seedBytes = Uint8List.fromList(await File(seedPath).readAsBytes());

    google_fonts_base.assetManifest = _TestAssetManifest(const <String>[
      interAssetKey,
    ]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          if (message == null) {
            return null;
          }
          final key = utf8.decode(message.buffer.asUint8List());
          if (key == interAssetKey) {
            return ByteData.sublistView(seedBytes);
          }
          return null;
        });
  });

  tearDownAll(() {
    google_fonts_base.clearCache();
    google_fonts_base.assetManifest = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('GlassCard', () {
    test('source matches blur/border/highlight/shadow spec', () {
      final source = File('lib/widgets/glass_card.dart').readAsStringSync();

      expect(source, contains('static const double _blurSigma = 40;'));
      expect(source, contains('width: 0.5'));
      expect(source, contains('height: _specularHeight'));
      expect(source, contains('top: 0'));
      expect(source, contains('List<BoxShadow> _outerShadow()'));
      expect(source, contains('return ['));
      expect(source, contains('blurRadius: 3'));
      expect(source, contains('blurRadius: 16'));
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(child: SizedBox(width: 40, height: 20)),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all 4 variants switch fill appearance', (tester) async {
      final fills = <Color>{};
      for (final variant in GlassCardVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassCard(
                variant: variant,
                child: const SizedBox(width: 40, height: 20),
              ),
            ),
          ),
        );
        fills.add(_cardBoxDecoration(tester).color!);
      }

      expect(fills.length, 4);
    });
  });

  group('GlassPill', () {
    testWidgets('renders without error and has tap animation', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassPill(
                label: 'Try',
                variant: GlassPillVariant.primaryLight,
                onTap: () => tapped++,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassPill), findsOneWidget);
      expect(find.byType(AnimatedScale), findsOneWidget);

      final animatedScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(animatedScale.scale, 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassPill)),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.97,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('min height is 48 and variants render differently', (
      tester,
    ) async {
      final fills = <Color>{};

      for (final variant in GlassPillVariant.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassPill(
                  label: variant.name,
                  variant: variant,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        final container = _pillContainer(tester);
        expect(container.constraints?.minHeight, 48);
        fills.add((container.decoration! as BoxDecoration).color!);
      }

      expect(fills.length, 4);
    });
  });

  group('GlassChip', () {
    testWidgets('renders without error and switches domain variants', (
      tester,
    ) async {
      final expectedText = <GlassChipDomain, Color>{
        GlassChipDomain.general: SettleColors.sage600,
        GlassChipDomain.self: SettleColors.blush600,
        GlassChipDomain.sleep: SettleColors.dusk600,
        GlassChipDomain.tantrum: SettleColors.warmth600,
        GlassChipDomain.child: SettleColors.sage600,
      };

      for (final domain in GlassChipDomain.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassChip(label: domain.name, domain: domain),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final box = container.decoration! as BoxDecoration;
        final border = box.border! as Border;
        expect(border.top.width, 0.5);

        final text = tester.widget<Text>(find.text(domain.name));
        expect(text.style?.color, expectedText[domain]);
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('GlassNavBar', () {
    test('source matches blur spec', () {
      final source = File('lib/widgets/glass_nav_bar.dart').readAsStringSync();
      expect(source, contains('static const double _blurSigma = 48;'));
    });

    testWidgets('renders without error and active color matches light spec', (
      tester,
    ) async {
      await _pumpNavBar(tester, brightness: Brightness.light);

      final activeIcon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(activeIcon.color, SettleColors.dusk600);
      expect(tester.takeException(), isNull);
    });

    testWidgets('auto-detects dark and uses dark active color', (tester) async {
      await _pumpNavBar(tester, brightness: Brightness.dark);

      final activeIcon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(activeIcon.color, SettleColors.nightAccent);
    });

    testWidgets('explicit variant switching overrides brightness', (
      tester,
    ) async {
      await _pumpNavBar(
        tester,
        brightness: Brightness.light,
        variant: GlassNavBarVariant.dark,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home)).color,
        SettleColors.nightAccent,
      );

      await _pumpNavBar(
        tester,
        brightness: Brightness.dark,
        variant: GlassNavBarVariant.light,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home)).color,
        SettleColors.dusk600,
      );
    });
  });
}

String _existingFontSeedPath() {
  const candidates = <String>[
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Helvetica.ttf',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  throw StateError('No seed font file found on host machine.');
}

BoxDecoration _cardBoxDecoration(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    final decoration = c.decoration;
    if (decoration is BoxDecoration &&
        decoration.boxShadow?.length == 2 &&
        decoration.border != null) {
      return decoration;
    }
  }
  throw StateError('Could not locate GlassCard BoxDecoration.');
}

Container _pillContainer(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    if (c.constraints?.minHeight == 48 && c.decoration is BoxDecoration) {
      return c;
    }
  }
  throw StateError('Could not locate GlassPill container.');
}

Future<void> _pumpNavBar(
  WidgetTester tester, {
  required Brightness brightness,
  GlassNavBarVariant? variant,
}) async {
  final baseTheme = brightness == Brightness.dark
      ? ThemeData.dark()
      : ThemeData.light();

  await tester.pumpWidget(
    MaterialApp(
      theme: baseTheme,
      home: Scaffold(
        bottomNavigationBar: GlassNavBar(
          items: const [
            GlassNavBarItem(icon: Icons.home, label: 'Home'),
            GlassNavBarItem(icon: Icons.nights_stay, label: 'Sleep'),
            GlassNavBarItem(icon: Icons.menu_book, label: 'Library'),
          ],
          activeIndex: 0,
          onTap: (_) {},
          variant: variant,
        ),
      ),
    ),
  );
}

class _TestAssetManifest implements AssetManifest {
  _TestAssetManifest(this.assets);

  final List<String> assets;

  @override
  List<String> listAssets() => assets;

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
