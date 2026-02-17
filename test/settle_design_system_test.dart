import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/theme/settle_design_system.dart';

void main() {
  group('Settle design system colors', () {
    test('SettleColors match spec hex values', () {
      expect(SettleColors.cream, const Color(0xFFFAFAF8));
      expect(SettleColors.stone50, const Color(0xFFF5F4F2));
      expect(SettleColors.stone100, const Color(0xFFECEAE6));
      expect(SettleColors.stone200, const Color(0xFFDDDAD4));

      expect(SettleColors.night950, const Color(0xFF0A0D12));
      expect(SettleColors.night900, const Color(0xFF0F1318));
      expect(SettleColors.night800, const Color(0xFF161C24));
      expect(SettleColors.night700, const Color(0xFF1E2630));

      expect(SettleColors.ink900, const Color(0xFF1A1A1C));
      expect(SettleColors.ink800, const Color(0xFF2C2C2E));
      expect(SettleColors.ink700, const Color(0xFF3A3A3C));
      expect(SettleColors.ink500, const Color(0xFF636366));
      expect(SettleColors.ink400, const Color(0xFF8E8E93));
      expect(SettleColors.ink300, const Color(0xFFAEAEB2));

      expect(SettleColors.nightText, const Color(0xFFECEFF4));
      expect(SettleColors.nightSoft, const Color(0xFFB0B8C8));
      expect(SettleColors.nightMuted, const Color(0xFF6B7280));
      expect(SettleColors.nightAccent, const Color(0xFF88AACC));

      expect(SettleColors.sage400, const Color(0xFF8BB89E));
      expect(SettleColors.sage600, const Color(0xFF5A8A6E));
      expect(SettleColors.sage100, const Color(0xFFE4EDE2));
      expect(SettleColors.blush400, const Color(0xFFBE8B8B));
      expect(SettleColors.blush600, const Color(0xFF946060));
      expect(SettleColors.blush100, const Color(0xFFF0E4E4));
      expect(SettleColors.dusk400, const Color(0xFF7B8FBE));
      expect(SettleColors.dusk600, const Color(0xFF4A5F94));
      expect(SettleColors.dusk100, const Color(0xFFE0E4F0));
      expect(SettleColors.warmth400, const Color(0xFFBEA070));
      expect(SettleColors.warmth600, const Color(0xFF8A7048));
      expect(SettleColors.warmth100, const Color(0xFFF0E8DC));
    });

    test('glass colors match spec hex values', () {
      expect(SettleGlassLight.background, const Color(0x7AFFFFFF));
      expect(SettleGlassLight.backgroundStrong, const Color(0x9EFFFFFF));
      expect(SettleGlassLight.backgroundSubtle, const Color(0x52FFFFFF));
      expect(SettleGlassLight.border, const Color(0x80FFFFFF));
      expect(SettleGlassLight.borderStrong, const Color(0xADFFFFFF));

      expect(SettleGlassDark.background, const Color(0x0EFFFFFF));
      expect(SettleGlassDark.backgroundStrong, const Color(0x17FFFFFF));
      expect(SettleGlassDark.border, const Color(0x14FFFFFF));
      expect(SettleGlassDark.borderStrong, const Color(0x21FFFFFF));
    });

    test('gradient colors match spec hex values', () {
      expect(SettleGradients.home.colors, const <Color>[
        Color(0xFFC8D8E8),
        Color(0xFFE0D8CC),
        Color(0xFFD4DED0),
        Color(0xFFE4DED6),
      ]);
      expect(SettleGradients.moment.colors, const <Color>[
        Color(0xFF90B8A4),
        Color(0xFFA8D0B8),
        Color(0xFFC4DED0),
        Color(0xFFE4F0E8),
      ]);
      expect(SettleGradients.sleep.colors, const <Color>[
        Color(0xFF1A2544),
        Color(0xFF253660),
        Color(0xFF344880),
        Color(0xFF4A6090),
      ]);
      expect(SettleGradients.resetDark.colors, const <Color>[
        Color(0xFF0A0D12),
        Color(0xFF0F1318),
        Color(0xFF161C24),
      ]);
      expect(SettleGradients.playbook.colors, const <Color>[
        Color(0xFFE6E2DC),
        Color(0xFFEDEBE6),
        Color(0xFFE8E4DE),
      ]);
    });
  });

  group('Settle typography source contract', () {
    test('Fraunces and Inter are imported from google_fonts', () {
      final source = File(
        'lib/theme/settle_design_system.dart',
      ).readAsStringSync();

      expect(
        source,
        contains("import 'package:google_fonts/google_fonts.dart';"),
      );
      expect(source, contains('GoogleFonts.fraunces('));
      expect(source, contains('GoogleFonts.inter('));
    });
  });

  group('SettleTheme source contract', () {
    test('light and dark theme builders are typed as ThemeData', () {
      final source = File(
        'lib/theme/settle_design_system.dart',
      ).readAsStringSync();

      expect(source, contains('static ThemeData get light => _buildLight();'));
      expect(source, contains('static ThemeData get dark => _buildDark();'));
      expect(source, contains('static ThemeData _buildLight()'));
      expect(source, contains('static ThemeData _buildDark()'));
    });

    test('app wiring uses light/dark themes with ThemeMode.system', () {
      final mainFile = File('lib/main.dart').readAsStringSync();

      expect(mainFile, contains('theme: SettleTheme.light'));
      expect(mainFile, contains('darkTheme: SettleTheme.dark'));
      expect(mainFile, contains('themeMode: ThemeMode.system'));
    });
  });
}
