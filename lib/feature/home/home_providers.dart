import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../domain/scheduler.dart';

final deckSummariesProvider = FutureProvider<List<DeckSummary>>((ref) async {
  final DeckRepository repository = ref.watch(deckRepositoryProvider);
  final int today = todayEpochDayUtc();
  return repository.fetchDeckSummaries(today);
});
