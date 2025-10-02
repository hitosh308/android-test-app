import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../domain/scheduler.dart';
import '../home/home_providers.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({required this.deck, super.key});

  final Deck deck;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  List<Flashcard> _queue = <Flashcard>[];
  bool _loading = true;
  bool _showBack = false;
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _loading = true;
    });
    try {
      final CardRepository repository = ref.read(cardRepositoryProvider);
      final List<Flashcard> cards = await repository.fetchDueCards(
        widget.deck.id,
        todayEpochDayUtc(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = cards;
        _loading = false;
        _showBack = false;
        _sessionStarted = cards.isNotEmpty;
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

  Flashcard? get _currentCard => _queue.isNotEmpty ? _queue.first : null;

  void _revealAnswer() {
    setState(() {
      _showBack = true;
    });
  }

  Future<void> _submitAnswer(bool isCorrect) async {
    final Flashcard? card = _currentCard;
    if (card == null) {
      return;
    }
    try {
      final Flashcard updated = applyReview(card: card, isCorrect: isCorrect);
      await ref.read(cardRepositoryProvider).saveScheduledCard(updated);
      ref.invalidate(deckSummariesProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _queue = <Flashcard>[..._queue.skip(1)];
        _showBack = false;
      });
      if (_queue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.studyComplete)),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(l10n),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final Flashcard? card = _currentCard;
    if (card == null) {
      return Center(
        child: Text(
          _sessionStarted ? l10n.studyComplete : l10n.noCardsDue,
          textAlign: TextAlign.center,
        ),
      );
    }

    final TextStyle textStyle = Theme.of(context).textTheme.headlineMedium ??
        const TextStyle(fontSize: 24);

    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.studyHeader(count: _queue.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _showBack ? card.back : card.front,
                key: ValueKey<bool>(_showBack),
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!_showBack)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _revealAnswer,
              child: Text(l10n.showAnswer),
            ),
          )
        else
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: () => _submitAnswer(false),
                    child: Text(l10n.incorrect),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _submitAnswer(true),
                    child: Text(l10n.correct),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
