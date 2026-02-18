import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/widgets/script_card.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 360, child: child)),
        ),
      ),
    );
  }

  testWidgets('plan context keeps one primary CTA visible', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ScriptCard(
          scenarioLabel: 'no_to_everything',
          prevent: 'Use two warnings and a visual cue.',
          say: 'It is time to leave. Hop or tiptoe?',
          doStep: 'Offer two choices once, then follow through.',
          ifEscalates: 'Acknowledge feeling and keep the same limit.',
          context: ScriptCardContext.plan,
        ),
      ),
    );

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('Save to Playbook'), findsOneWidget);
    expect(find.text('Share with partner'), findsNothing);
  });

  testWidgets('crisis context reveals Do only after primary progression tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ScriptCard(
          scenarioLabel: 'public_meltdown',
          prevent: 'Plan exits before entering crowded places.',
          say: 'You are safe with me.',
          doStep: 'Move to a quiet space and lower stimulation.',
          ifEscalates: 'Contain safely and shorten language.',
          context: ScriptCardContext.crisis,
        ),
      ),
    );

    expect(find.text('Say'), findsOneWidget);
    expect(find.text('Do'), findsNothing);
    expect(find.text('I said it →'), findsOneWidget);

    await tester.tap(find.text('I said it →'));
    await tester.pumpAndSettle();

    expect(find.text('Do'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('overflow actions are available through more actions button', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ScriptCard(
          scenarioLabel: 'transitions',
          prevent: 'Preview transition twice.',
          say: 'Two more minutes.',
          doStep: 'Guide to next step calmly.',
          context: ScriptCardContext.plan,
          onShare: () {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('More actions'), findsOneWidget);
    expect(find.text('Send to partner'), findsOneWidget);
  });
}
