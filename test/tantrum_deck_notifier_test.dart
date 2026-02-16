import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/tantrum/providers/tantrum_module_providers.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_tantrum_deck');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> settleLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }

  test('pin enforces max 3 cards', () async {
    final notifier = TantrumDeckNotifier();
    await settleLoad();

    final a = await notifier.pin('a');
    final b = await notifier.pin('b');
    final c = await notifier.pin('c');
    final d = await notifier.pin('d');

    expect(a, isTrue);
    expect(b, isTrue);
    expect(c, isTrue);
    expect(d, isFalse);
    expect(notifier.state.pinnedIds, ['a', 'b', 'c']);
    expect(notifier.state.savedIds, ['a', 'b', 'c']);
  });

  test('unsave removes card from favorites and pinned', () async {
    final notifier = TantrumDeckNotifier();
    await settleLoad();

    await notifier.save('card_1');
    await notifier.toggleFavorite('card_1');
    await notifier.pin('card_1');
    await notifier.unsave('card_1');

    expect(notifier.state.savedIds.contains('card_1'), isFalse);
    expect(notifier.state.favoriteIds.contains('card_1'), isFalse);
    expect(notifier.state.pinnedIds.contains('card_1'), isFalse);
  });

  test('reorderPinned updates order', () async {
    final notifier = TantrumDeckNotifier();
    await settleLoad();

    await notifier.pin('a');
    await notifier.pin('b');
    await notifier.pin('c');
    await notifier.reorderPinned(2, 0);

    expect(notifier.state.pinnedIds, ['c', 'a', 'b']);
  });

  test('migrates legacy protocol pinned ids on first load', () async {
    final legacy = await Hive.openBox<dynamic>('tantrum_protocol');
    await legacy.put('pinned_ids', jsonEncode(['x', 'y', 'z', 'extra']));

    final notifier = TantrumDeckNotifier();
    await settleLoad();

    expect(notifier.state.savedIds, ['x', 'y', 'z', 'extra']);
    expect(notifier.state.pinnedIds, ['x', 'y', 'z']);
  });

  test('togglePackPurchased adds and removes pack', () async {
    final notifier = TantrumDeckNotifier();
    await settleLoad();

    await notifier.togglePackPurchased('boundaries_pack');
    expect(notifier.state.purchasedPackIds.contains('boundaries_pack'), isTrue);

    await notifier.togglePackPurchased('boundaries_pack');
    expect(
      notifier.state.purchasedPackIds.contains('boundaries_pack'),
      isFalse,
    );
  });
}
