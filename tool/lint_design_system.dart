// ignore_for_file: avoid_print

import 'dart:io';

/// Lint script for design system rules in lib/screens/.
///
/// Run: dart run tool/lint_design_system.dart
///
/// Rules:
/// - ERROR: GestureDetector without Semantics → use SettleTappable or add Semantics
/// - WARNING: Color(...) or Colors.* → use T.pal.*
/// - WARNING: TextStyle(...) constructor → use T.type.* or theme
/// - WARNING: SizedBox(height: N) or SizedBox(width: N) literal → use SettleGap
void main() {
  final screensDir = Directory('lib/screens');
  if (!screensDir.existsSync()) {
    print('lib/screens not found');
    exit(1);
  }

  final errors = <String>[];
  final warnings = <String>[];

  for (final entity in screensDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final content = entity.readAsStringSync();
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // ERROR: GestureDetector (call out; user should add Semantics or use SettleTappable)
      if (line.contains('GestureDetector') && !line.trim().startsWith('//')) {
        errors.add('$path:$lineNum: GestureDetector used — use SettleTappable or wrap in Semantics');
      }

      // WARNING: Color( or Colors.
      if (RegExp(r'\bColor\s*\(|\bColors\.').hasMatch(line) &&
          !line.contains('T.pal.') &&
          !line.trim().startsWith('//')) {
        warnings.add('$path:$lineNum: Color/Colors literal — prefer T.pal.*');
      }

      // WARNING: TextStyle(
      if (RegExp(r'TextStyle\s*\(').hasMatch(line) &&
          !line.contains('T.type.') &&
          !line.contains('copyWith') &&
          !line.trim().startsWith('//')) {
        warnings.add('$path:$lineNum: TextStyle( — prefer T.type.* or theme');
      }

      // WARNING: SizedBox(height: N) or SizedBox(width: N) with literal number
      final sizedBoxMatch = RegExp(r'SizedBox\s*\(\s*(?:height|width)\s*:\s*(\d+)').firstMatch(line);
      if (sizedBoxMatch != null && !line.trim().startsWith('//')) {
        warnings.add('$path:$lineNum: SizedBox with literal — prefer SettleGap');
      }
    }
  }

  var exitCode = 0;
  if (errors.isNotEmpty) {
    print('Design system ERRORS (use SettleTappable or Semantics):');
    for (final e in errors) print('  $e');
    exitCode = 1;
  }
  if (warnings.isNotEmpty) {
    print('Design system WARNINGS (prefer tokens / SettleGap):');
    for (final w in warnings) print('  $w');
    if (exitCode == 0) exitCode = 0; // warnings don't fail by default
  }
  if (errors.isEmpty && warnings.isEmpty) {
    print('No design system violations in lib/screens/');
  }
  exit(exitCode);
}
