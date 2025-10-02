import 'package:flutter/material.dart';

import 'data/models.dart';
import 'feature/deck/deck_page.dart';
import 'feature/edit/card_edit_page.dart';
import 'feature/edit/deck_edit_page.dart';
import 'feature/settings/settings_page.dart';
import 'feature/study/study_page.dart';

class AppRouter {
  const AppRouter._();

  static Future<void> goToDeck(BuildContext context, Deck deck) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DeckPage(deck: deck),
      ),
    );
  }

  static Future<Deck?> goToDeckEditor(BuildContext context, {Deck? deck}) {
    return Navigator.of(context).push<Deck?>(
      MaterialPageRoute<Deck?>(
        builder: (BuildContext context) => DeckEditPage(deck: deck),
      ),
    );
  }

  static Future<bool?> goToCardEditor(
    BuildContext context, {
    required Deck deck,
    Flashcard? card,
  }) {
    return Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => CardEditPage(deck: deck, card: card),
      ),
    );
  }

  static Future<void> goToStudy(BuildContext context, Deck deck) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => StudyPage(deck: deck),
      ),
    );
  }

  static Future<void> goToSettings(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsPage(),
      ),
    );
  }
}
