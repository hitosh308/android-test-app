import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../home/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _ensureSeedData();
  }

  Future<void> _ensureSeedData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SeedRepository seedRepository = ref.read(seedRepositoryProvider);
      final bool imported = await seedRepository.importIfEmpty();
      if (!mounted) {
        return;
      }
      if (imported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.importSuccess)),
        );
        ref.invalidate(deckSummariesProvider);
      }
    });
  }

  Future<void> _createDeck() async {
    final Deck? result = await AppRouter.goToDeckEditor(context);
    if (result != null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckSaved)),
      );
      ref.invalidate(deckSummariesProvider);
    }
  }

  Future<void> _editDeck(Deck deck) async {
    final Deck? result = await AppRouter.goToDeckEditor(context, deck: deck);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckSaved)),
      );
      ref.invalidate(deckSummariesProvider);
    }
  }

  Future<void> _deleteDeck(Deck deck) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteDeck),
          content: Text(l10n.deleteDeckConfirm),
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
        await ref.read(deckRepositoryProvider).deleteDeck(deck.id);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deckDeleted)),
        );
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<DeckSummary>> deckSummaries = ref.watch(deckSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppRouter.goToSettings(context),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDeck,
        tooltip: l10n.addDeck,
        child: const Icon(Icons.add),
      ),
      body: deckSummaries.when(
        data: (List<DeckSummary> decks) {
          if (decks.isEmpty) {
            return Center(
              child: Text(
                l10n.addDeck,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: decks.length,
            itemBuilder: (BuildContext context, int index) {
              final DeckSummary summary = decks[index];
              return _DeckTile(
                summary: summary,
                onEdit: () => _editDeck(summary.deck),
                onDelete: () => _deleteDeck(summary.deck),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return Center(child: Text(error.toString()));
        },
      ),
    );
  }
}

class _DeckTile extends ConsumerWidget {
  const _DeckTile({
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  final DeckSummary summary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(summary.deck.name),
        subtitle: Text(
          l10n.deckDueSummary(
            due: summary.dueCount,
            total: summary.totalCount,
          ),
        ),
        onTap: () => AppRouter.goToDeck(context, summary.deck),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => AppRouter.goToStudy(context, summary.deck),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 48),
                ),
                child: Text(l10n.startStudy),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text(l10n.editDeck),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(l10n.deleteDeck),
                ),
              ],
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
