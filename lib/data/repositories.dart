import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/scheduler.dart';
import 'db.dart';
import 'models.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  final Future<Database> databaseFuture = ref.watch(dbProvider.future);
  return DeckRepository(databaseFuture);
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final Future<Database> databaseFuture = ref.watch(dbProvider.future);
  return CardRepository(databaseFuture);
});

final seedRepositoryProvider = Provider<SeedRepository>((ref) {
  final Future<Database> databaseFuture = ref.watch(dbProvider.future);
  return SeedRepository(databaseFuture: databaseFuture);
});

class DeckRepository {
  DeckRepository(this._databaseFuture);

  final Future<Database> _databaseFuture;
  final Uuid _uuid = const Uuid();

  Future<List<DeckSummary>> fetchDeckSummaries(int todayEpochDay) async {
    try {
      final Database db = await _databaseFuture;
      final List<Map<String, Object?>> rows = await db.rawQuery(
        '''
        SELECT d.*, 
          (SELECT COUNT(*) FROM cards c WHERE c.deck_id = d.id) AS total_count,
          (SELECT COUNT(*) FROM cards c WHERE c.deck_id = d.id AND c.due <= ?) AS due_count
        FROM decks d
        ORDER BY d.updated_at DESC;
        ''',
        <Object?>[todayEpochDay],
      );
      return rows.map((Map<String, Object?> row) {
        final Deck deck = Deck.fromMap(row);
        final int totalCount = (row['total_count'] as int?) ?? 0;
        final int dueCount = (row['due_count'] as int?) ?? 0;
        return DeckSummary(deck: deck, dueCount: dueCount, totalCount: totalCount);
      }).toList();
    } catch (error) {
      throw Exception('Failed to load decks: $error');
    }
  }

  Future<Deck> createDeck(String name) async {
    final int timestamp = nowUtcMillis();
    final Deck deck = Deck(
      id: _uuid.v4(),
      name: name,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    try {
      final Database db = await _databaseFuture;
      await db.insert('decks', deck.toMap());
      return deck;
    } catch (error) {
      throw Exception('Failed to create deck: $error');
    }
  }

  Future<void> updateDeck(Deck deck) async {
    final Deck updatedDeck = deck.copyWith(updatedAt: nowUtcMillis());
    try {
      final Database db = await _databaseFuture;
      await db.update(
        'decks',
        updatedDeck.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[deck.id],
      );
    } catch (error) {
      throw Exception('Failed to update deck: $error');
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      final Database db = await _databaseFuture;
      await db.delete(
        'decks',
        where: 'id = ?',
        whereArgs: <Object?>[deckId],
      );
    } catch (error) {
      throw Exception('Failed to delete deck: $error');
    }
  }

  Future<List<Deck>> fetchDecks() async {
    try {
      final Database db = await _databaseFuture;
      final List<Map<String, Object?>> rows = await db.query(
        'decks',
        orderBy: 'updated_at DESC',
      );
      return rows.map(Deck.fromMap).toList();
    } catch (error) {
      throw Exception('Failed to fetch decks: $error');
    }
  }
}

class CardRepository {
  CardRepository(this._databaseFuture);

  final Future<Database> _databaseFuture;
  final Uuid _uuid = const Uuid();

  Future<List<Flashcard>> fetchCards(String deckId, {String? query}) async {
    try {
      final Database db = await _databaseFuture;
      final String? likeQuery = query != null && query.isNotEmpty ? '%$query%' : null;
      final List<Map<String, Object?>> rows = await db.query(
        'cards',
        where: likeQuery != null ? 'deck_id = ? AND (front LIKE ? OR back LIKE ?)' : 'deck_id = ?',
        whereArgs: likeQuery != null
            ? <Object?>[deckId, likeQuery, likeQuery]
            : <Object?>[deckId],
        orderBy: 'updated_at DESC',
      );
      return rows.map(Flashcard.fromMap).toList();
    } catch (error) {
      throw Exception('Failed to fetch cards: $error');
    }
  }

  Future<List<Flashcard>> fetchDueCards(String deckId, int todayEpochDay) async {
    try {
      final Database db = await _databaseFuture;
      final List<Map<String, Object?>> rows = await db.query(
        'cards',
        where: 'deck_id = ? AND due <= ?',
        whereArgs: <Object?>[deckId, todayEpochDay],
        orderBy: 'due ASC, updated_at ASC',
      );
      return rows.map(Flashcard.fromMap).toList();
    } catch (error) {
      throw Exception('Failed to fetch due cards: $error');
    }
  }

  Future<Flashcard> createCard({
    required String deckId,
    required String front,
    required String back,
    required List<String> tags,
  }) async {
    final int timestamp = nowUtcMillis();
    final int today = todayEpochDayUtc();
    final Flashcard card = Flashcard(
      id: _uuid.v4(),
      deckId: deckId,
      front: front,
      back: back,
      tags: tags,
      ease: 2.5,
      interval: 0,
      due: today,
      reps: 0,
      lapses: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    try {
      final Database db = await _databaseFuture;
      await db.insert('cards', card.toMap());
      return card;
    } catch (error) {
      throw Exception('Failed to create card: $error');
    }
  }

  Future<void> updateCard(Flashcard card) async {
    try {
      final Database db = await _databaseFuture;
      await db.update(
        'cards',
        card.copyWith(updatedAt: nowUtcMillis()).toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[card.id],
      );
    } catch (error) {
      throw Exception('Failed to update card: $error');
    }
  }

  Future<void> saveScheduledCard(Flashcard card) async {
    try {
      final Database db = await _databaseFuture;
      await db.update(
        'cards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[card.id],
      );
    } catch (error) {
      throw Exception('Failed to update schedule: $error');
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      final Database db = await _databaseFuture;
      await db.delete(
        'cards',
        where: 'id = ?',
        whereArgs: <Object?>[cardId],
      );
    } catch (error) {
      throw Exception('Failed to delete card: $error');
    }
  }
}

class SeedRepository {
  SeedRepository({required Future<Database> databaseFuture})
      : _databaseFuture = databaseFuture;

  final Future<Database> _databaseFuture;

  Future<bool> importIfEmpty() async {
    if (await isDatabaseEmpty()) {
      return importSeed();
    }
    return false;
  }

  Future<bool> importSeed() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/seed/deck_basic.json');
      final Map<String, dynamic> payload = jsonDecode(jsonString) as Map<String, dynamic>;
      final List<dynamic> decks = payload['decks'] as List<dynamic>? ?? <dynamic>[];
      final Database db = await _databaseFuture;
      return await db.transaction((Transaction txn) async {
        for (final dynamic deckData in decks) {
          final Map<String, dynamic> deckMap = deckData as Map<String, dynamic>;
          final String deckId = deckMap['id'] as String? ?? const Uuid().v4();
          final String deckName = deckMap['name'] as String? ?? 'Deck';
          final int timestamp = nowUtcMillis();
          await txn.insert(
            'decks',
            Deck(
              id: deckId,
              name: deckName,
              createdAt: timestamp,
              updatedAt: timestamp,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          final List<dynamic> cards = deckMap['cards'] as List<dynamic>? ?? <dynamic>[];
          for (final dynamic cardData in cards) {
            final Map<String, dynamic> cardMap = cardData as Map<String, dynamic>;
            final List<String> tags = (cardMap['tags'] as List<dynamic>? ?? <dynamic>[])
                .map((dynamic e) => e.toString())
                .toList();
            final Flashcard card = Flashcard(
              id: const Uuid().v4(),
              deckId: deckId,
              front: cardMap['front'] as String? ?? '',
              back: cardMap['back'] as String? ?? '',
              tags: tags,
              ease: 2.5,
              interval: 0,
              due: todayEpochDayUtc(),
              reps: 0,
              lapses: 0,
              createdAt: timestamp,
              updatedAt: timestamp,
            );
            await txn.insert('cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        return true;
      });
    } catch (error) {
      return false;
    }
  }

  Future<bool> isDatabaseEmpty() async {
    final Database db = await _databaseFuture;
    final int? count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM decks'),
    );
    return (count ?? 0) == 0;
  }
}

// TODO: Add SAF export/import hooks when platform support is required.
