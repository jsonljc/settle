import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_repository.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository.instance;
});
