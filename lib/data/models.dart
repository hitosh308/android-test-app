import 'dart:convert';

class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int createdAt;
  final int updatedAt;

  Deck copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Deck.fromMap(Map<String, Object?> map) {
    return Deck(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}

class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.tags,
    required this.ease,
    required this.interval,
    required this.due,
    required this.reps,
    required this.lapses,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final List<String> tags;
  final double ease;
  final int interval;
  final int due;
  final int reps;
  final int lapses;
  final int createdAt;
  final int updatedAt;

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    List<String>? tags,
    double? ease,
    int? interval,
    int? due,
    int? reps,
    int? lapses,
    int? createdAt,
    int? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      tags: tags ?? this.tags,
      ease: ease ?? this.ease,
      interval: interval ?? this.interval,
      due: due ?? this.due,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'tags': jsonEncode(tags),
      'ease': ease,
      'interval': interval,
      'due': due,
      'reps': reps,
      'lapses': lapses,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Flashcard.fromMap(Map<String, Object?> map) {
    final Object? rawTags = map['tags'];
    final List<dynamic> tagList;
    if (rawTags is String) {
      tagList = jsonDecode(rawTags) as List<dynamic>;
    } else if (rawTags is List<dynamic>) {
      tagList = rawTags;
    } else {
      tagList = <dynamic>[];
    }
    return Flashcard(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      front: map['front'] as String,
      back: map['back'] as String,
      tags: tagList.map((dynamic e) => e.toString()).toList(),
      ease: (map['ease'] as num).toDouble(),
      interval: map['interval'] as int,
      due: map['due'] as int,
      reps: map['reps'] as int,
      lapses: map['lapses'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}

class DeckSummary {
  const DeckSummary({
    required this.deck,
    required this.dueCount,
    required this.totalCount,
  });

  final Deck deck;
  final int dueCount;
  final int totalCount;
}
