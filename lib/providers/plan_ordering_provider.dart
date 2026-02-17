import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/card_content_service.dart';
import '../services/pattern_engine.dart';
import 'patterns_provider.dart';
import 'regulation_events_provider.dart';
import 'usage_events_provider.dart';

/// Map cardId → triggerType from registry. Used for ordering and pattern engine.
final cardIdToTriggerTypeProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final cards = await CardContentService.instance.getCards();
  return {for (final c in cards) c.id: c.triggerType};
});

/// Trigger types ordered by usage frequency (most used first). Falls back to default order while loading.
final triggerOrderByUsageProvider = Provider<List<String>>((ref) {
  final usage = ref.watch(usageEventsProvider);
  final mapAsync = ref.watch(cardIdToTriggerTypeProvider);
  return mapAsync.when(
    data: (map) => PatternEngine.orderTriggersByUsage(usage, map),
    loading: () => PatternEngine.defaultTriggerOrder,
    error: (_, __) => PatternEngine.defaultTriggerOrder,
  );
});

/// Runs pattern engine and persists to [patternsProvider]. Watch to trigger refresh when events change.
final patternEngineRefreshProvider = FutureProvider<void>((ref) async {
  final usage = ref.watch(usageEventsProvider);
  final regulation = ref.watch(regulationEventsProvider);
  final map = await ref.watch(cardIdToTriggerTypeProvider.future);
  final insights = PatternEngine.compute(usage, regulation, map);
  await ref.read(patternsProvider.notifier).setInsights(insights);
});
