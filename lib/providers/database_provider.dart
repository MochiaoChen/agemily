import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be overridden at app startup');
});
