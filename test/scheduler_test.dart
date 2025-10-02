import 'package:flutter_test/flutter_test.dart';
import 'package:offline_cards/data/models.dart';
import 'package:offline_cards/domain/scheduler.dart';

void main() {
  final Flashcard baseCard = Flashcard(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'front',
    back: 'back',
    tags: const <String>[],
    ease: 2.5,
    interval: 0,
    due: 0,
    reps: 0,
    lapses: 0,
    createdAt: 0,
    updatedAt: 0,
  );

  test('applyReview increases interval and ease when correct', () {
    final DateTime now = DateTime.utc(2024, 1, 1, 12);
    final Flashcard result = applyReview(card: baseCard, isCorrect: true, now: now);

    expect(result.reps, 1);
    expect(result.lapses, 0);
    expect(result.interval, 1);
    expect(result.ease, closeTo(2.55, 0.0001));
    expect(result.due, epochDayFromDate(now) + 1);
  });

  test('applyReview resets interval and lowers ease when incorrect', () {
    final Flashcard difficultCard = baseCard.copyWith(interval: 6, ease: 2.8, reps: 2);
    final DateTime now = DateTime.utc(2024, 1, 1, 12);
    final Flashcard result = applyReview(card: difficultCard, isCorrect: false, now: now);

    expect(result.reps, 3);
    expect(result.lapses, difficultCard.lapses + 1);
    expect(result.interval, 1);
    expect(result.ease, closeTo(2.6, 0.0001));
    expect(result.due, epochDayFromDate(now) + 1);
  });
}
