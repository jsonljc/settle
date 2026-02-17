import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/repair_card.dart';
import '../models/user_card.dart';
import 'card_repository_provider.dart';
import 'user_cards_provider.dart';

/// One playbook entry: saved UserCard + resolved RepairCard (title/body).
class PlaybookEntry {
  const PlaybookEntry({required this.userCard, required this.repairCard});

  final UserCard userCard;
  final RepairCard repairCard;
}

/// Playbook as list of repair cards only, most recent first.
/// Cards saved from Reset (repair card ids) appear here; other saved ids are excluded.
final playbookRepairCardsProvider = FutureProvider<List<PlaybookEntry>>((
  ref,
) async {
  final userCards = ref.watch(userCardsProvider);
  final repo = ref.read(cardRepositoryProvider);
  final all = await repo.loadAll();
  final byId = {for (final c in all) c.id: c};
  final list = <PlaybookEntry>[];
  for (final uc in userCards) {
    final rc = byId[uc.cardId];
    if (rc != null) list.add(PlaybookEntry(userCard: uc, repairCard: rc));
  }
  list.sort((a, b) => b.userCard.savedAt.compareTo(a.userCard.savedAt));
  return list;
});
