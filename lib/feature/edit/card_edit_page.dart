import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';

class CardEditPage extends ConsumerStatefulWidget {
  const CardEditPage({required this.deck, this.card, super.key});

  final Deck deck;
  final Flashcard? card;

  @override
  ConsumerState<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends ConsumerState<CardEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _tagsController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front ?? '');
    _backController = TextEditingController(text: widget.card?.back ?? '');
    _tagsController = TextEditingController(
      text: widget.card?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final CardRepository repository = ref.read(cardRepositoryProvider);
      final List<String> tags = _parseTags(_tagsController.text);
      if (widget.card == null) {
        await repository.createCard(
          deckId: widget.deck.id,
          front: _frontController.text.trim(),
          back: _backController.text.trim(),
          tags: tags,
        );
      } else {
        final Flashcard updated = widget.card!.copyWith(
          front: _frontController.text.trim(),
          back: _backController.text.trim(),
          tags: tags,
        );
        await repository.updateCard(updated);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isEdit = widget.card != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editCard : l10n.addCard),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _frontController,
                decoration: InputDecoration(
                  labelText: l10n.frontLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.frontLabel;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backController,
                decoration: InputDecoration(
                  labelText: l10n.backLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.backLabel;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: l10n.tagsLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _save,
                  child: _submitting
                      ? const CircularProgressIndicator.adaptive()
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
