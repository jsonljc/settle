import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tantrum_card.dart';
import 'tantrum_module_providers.dart';

/// Free tier includes the base pack cards.
const tantrumFreeTierCardCount = 20;

/// Placeholder entitlement source for v1 monetization scaffolding.
/// Uses locally toggled purchased pack IDs until billing integration is added.
final premiumUnlockedPackIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(deckPurchasedPackIdsProvider);
});

final unlockedPackIdsProvider = Provider<Set<String>>((ref) {
  final premium = ref.watch(premiumUnlockedPackIdsProvider);
  return {'base', ...premium};
});

final hasCardAccessProvider = Provider.family<bool, TantrumCard>((ref, card) {
  if (!card.isPremium) return true;
  final unlocked = ref.watch(unlockedPackIdsProvider);
  return unlocked.contains(card.packId);
});
