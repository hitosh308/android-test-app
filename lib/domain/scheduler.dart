import 'package:offline_cards/data/models.dart';

const double _easeIncrement = 0.05;
const double _easeDecrement = 0.2;
const double _easeMin = 1.3;
const double _easeMax = 3.0;

int epochDayFromDate(DateTime date) {
  final DateTime utc = DateTime.utc(date.year, date.month, date.day);
  return utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

DateTime dateFromEpochDay(int epochDay) {
  return DateTime.fromMillisecondsSinceEpoch(
    epochDay * Duration.millisecondsPerDay,
    isUtc: true,
  );
}

int nowUtcMillis() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

int todayEpochDayUtc() {
  return epochDayFromDate(DateTime.now().toUtc());
}

Flashcard applyReview({
  required Flashcard card,
  required bool isCorrect,
  DateTime? now,
}) {
  final DateTime current = (now ?? DateTime.now()).toUtc();
  final int today = epochDayFromDate(current);
  final int newReps = card.reps + 1;
  double updatedEase = card.ease;
  int updatedInterval = card.interval;
  int updatedLapses = card.lapses;

  if (isCorrect) {
    updatedEase = (updatedEase + _easeIncrement).clamp(_easeMin, _easeMax);
    updatedInterval = updatedInterval <= 0 ? 1 : updatedInterval * 2;
    if (updatedInterval < 1) {
      updatedInterval = 1;
    }
  } else {
    updatedEase = (updatedEase - _easeDecrement).clamp(_easeMin, _easeMax);
    updatedInterval = 1;
    updatedLapses += 1;
  }

  final int newDue = today + updatedInterval;

  return card.copyWith(
    ease: updatedEase,
    interval: updatedInterval,
    due: newDue,
    reps: newReps,
    lapses: updatedLapses,
    updatedAt: current.millisecondsSinceEpoch,
  );
}

// TODO: Replace with full SM-2 implementation in the future.
