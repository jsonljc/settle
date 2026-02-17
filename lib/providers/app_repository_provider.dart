import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepositoryImpl.instance;
});
