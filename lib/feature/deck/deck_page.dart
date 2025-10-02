import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../home/home_providers.dart';

class DeckPage extends ConsumerStatefulWidget {
  const DeckPage({required this.deck, super.key});

  final Deck deck;

  @override
  ConsumerState<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends ConsumerState<DeckPage> {
  final TextEditingController _searchController = TextEditingController();
  late Deck _currentDeck;
  List<Flashcard> _cards = <Flashcard>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck;
    _loadCards();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _loading = true;
    });
    try {
      final CardRepository repository = ref.read(cardRepositoryProvider);
      final List<Flashcard> cards = await repository.fetchCards(
        _currentDeck.id,
        query: _searchController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cards = cards;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _addCard() async {
    final bool? result = await AppRouter.goToCardEditor(
      context,
      deck: _currentDeck,
    );
    if (result == true) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cardSaved)),
      );
      await _loadCards();
      ref.invalidate(deckSummariesProvider);
    }
  }

  Future<void> _editCard(Flashcard card) async {
    final bool? result = await AppRouter.goToCardEditor(
      context,
      deck: _currentDeck,
      card: card,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cardSaved)),
      );
      await _loadCards();
      ref.invalidate(deckSummariesProvider);
    }
  }

  Future<void> _deleteCard(Flashcard card) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteCard),
          content: Text(l10n.deleteCardConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      try {
        await ref.read(cardRepositoryProvider).deleteCard(card.id);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cardDeleted)),
        );
        await _loadCards();
        ref.invalidate(deckSummariesProvider);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _editDeck() async {
    final Deck? result = await AppRouter.goToDeckEditor(context, deck: _currentDeck);
    if (result != null && mounted) {
      setState(() {
        _currentDeck = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckSaved)),
      );
      ref.invalidate(deckSummariesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDeck.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDeck,
            tooltip: l10n.editDeck,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        tooltip: l10n.addCard,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? Center(child: Text(l10n.emptyDeck))
                      : ListView.builder(
                          itemCount: _cards.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Flashcard card = _cards[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(card.front),
                                subtitle: Text(card.back),
                                onTap: () => _editCard(card),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text(l10n.editCard),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(l10n.deleteCard),
                                    ),
                                  ],
                                  onSelected: (String value) {
                                    if (value == 'edit') {
                                      _editCard(card);
                                    } else if (value == 'delete') {
                                      _deleteCard(card);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
