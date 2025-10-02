import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';

class DeckEditPage extends ConsumerStatefulWidget {
  const DeckEditPage({this.deck, super.key});

  final Deck? deck;

  @override
  ConsumerState<DeckEditPage> createState() => _DeckEditPageState();
}

class _DeckEditPageState extends ConsumerState<DeckEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final DeckRepository repository = ref.read(deckRepositoryProvider);
      final String name = _nameController.text.trim();
      Deck saved;
      if (widget.deck == null) {
        saved = await repository.createDeck(name);
      } else {
        saved = widget.deck!.copyWith(name: name);
        await repository.updateDeck(saved);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(saved);
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
    final bool isEdit = widget.deck != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editDeck : l10n.addDeck),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.deckNameLabel,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.deckNameLabel;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
