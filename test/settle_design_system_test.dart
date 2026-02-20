import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/theme/settle_design_system.dart';

void main() {
  group('Settle design system colors', () {
    test('SettleColors match design system hex values', () {
      expect(SettleColors.cream, const Color(0xFFFFFBF7));
      expect(SettleColors.stone50, const Color(0xFFF5F3F0));
      expect(SettleColors.stone100, const Color(0xFFEBE8E4));
      expect(SettleColors.stone200, const Color(0xFFDDD9D4));

      expect(SettleColors.night950, const Color(0xFF0C0E12));
      expect(SettleColors.night900, const Color(0xFF12161C));
      expect(SettleColors.night800, const Color(0xFF1A1F28));
      expect(SettleColors.night700, const Color(0xFF242B36));

      expect(SettleColors.ink900, const Color(0xFF0F1114));
      expect(SettleColors.ink800, const Color(0xFF1C1E22));
      expect(SettleColors.ink700, const Color(0xFF2D3036));
      expect(SettleColors.ink500, const Color(0xFF5C6066));
      expect(SettleColors.ink400, const Color(0xFF73787F));
      expect(SettleColors.ink300, const Color(0xFF8E9299));

      expect(SettleColors.nightText, const Color(0xFFF0F2F5));
      expect(SettleColors.nightSoft, const Color(0xFFC2C8D0));
      expect(SettleColors.nightMuted, const Color(0xFF88909C));
      expect(SettleColors.nightAccent, const Color(0xFF7BA3C7));

      expect(SettleColors.sage400, const Color(0xFF5B9B7A));
      expect(SettleColors.sage600, const Color(0xFF3D7A5A));
      expect(SettleColors.sage100, const Color(0xFFE2EDE6));
      expect(SettleColors.blush400, const Color(0xFFC07878));
      expect(SettleColors.blush600, const Color(0xFFA05A5A));
      expect(SettleColors.blush100, const Color(0xFFF2E6E6));
      expect(SettleColors.dusk400, const Color(0xFF6B8AB8));
      expect(SettleColors.dusk600, const Color(0xFF4A6A96));
      expect(SettleColors.dusk100, const Color(0xFFE2E8F2));
      expect(SettleColors.warmth400, const Color(0xFFB8926A));
      expect(SettleColors.warmth600, const Color(0xFF96704A));
      expect(SettleColors.warmth100, const Color(0xFFF0E8DC));
    });

    test('SettleGradients are solid (single color)', () {
      expect(SettleGradients.home.colors.length, 2);
      expect(SettleGradients.home.colors.first, SettleGradients.home.colors.last);
      expect(SettleGradients.home.colors.first, SettleColors.stone50);

      expect(SettleGradients.moment.colors.length, 2);
      expect(SettleGradients.moment.colors.first, SettleColors.night900);

      expect(SettleGradients.sleep.colors.length, 2);
      expect(SettleGradients.sleep.colors.first, SettleColors.night900);

      expect(SettleGradients.playbook.colors.length, 2);
      expect(SettleGradients.playbook.colors.first, SettleColors.stone50);
    });
  });

  group('Settle typography source contract', () {
    test('DM Sans is used from google_fonts', () {
      final source = File(
        'lib/theme/settle_design_system.dart',
      ).readAsStringSync();

      expect(
        source,
        contains("import 'package:google_fonts/google_fonts.dart';"),
      );
      expect(source, contains('GoogleFonts.dmSans('));
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

    test('app wiring uses SettleTheme and theme mode', () {
      final mainFile = File('lib/main.dart').readAsStringSync();

      expect(mainFile, contains('SettleTheme'));
      expect(mainFile, contains('theme:'));
      expect(mainFile, contains('themeMode:'));
    });
  });
}
