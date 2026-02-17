import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/widgets/settle_chip.dart';

void main() {
  testWidgets('SettleChip tag variant shows label and semantics', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SettleChip(
            label: 'Tag',
            selected: false,
            onTap: () => tapped = true,
            variant: SettleChipVariant.tag,
          ),
        ),
      ),
    );

    expect(find.text('Tag'), findsOneWidget);
    expect(tapped, isFalse);
    await tester.tap(find.byType(SettleChip));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('SettleChip frequency variant selected renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SettleChip(
            label: 'Smart',
            selected: true,
            onTap: () {},
            variant: SettleChipVariant.frequency,
          ),
        ),
      ),
    );

    expect(find.text('Smart'), findsOneWidget);
    expect(find.byType(SettleChip), findsOneWidget);
  });

  testWidgets('SettleChip with count appends count to display', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SettleChip(
            label: 'Category',
            selected: false,
            onTap: () {},
            variant: SettleChipVariant.tag,
            count: 3,
          ),
        ),
      ),
    );

    expect(find.text('Category (3)'), findsOneWidget);
  });
}
