import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../home/home_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const String _appVersion = '1.0.0';
  bool _dbEmpty = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final SeedRepository repository = ref.read(seedRepositoryProvider);
    final bool empty = await repository.isDatabaseEmpty();
    if (!mounted) {
      return;
    }
    setState(() {
      _dbEmpty = empty;
      _loading = false;
    });
  }

  Future<void> _importSeed() async {
    setState(() {
      _loading = true;
    });
    final SeedRepository repository = ref.read(seedRepositoryProvider);
    final bool success = await repository.importSeed();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _dbEmpty = false;
    });
    if (success) {
      ref.invalidate(deckSummariesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importFailure)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: <Widget>[
                  Text(l10n.settingsNote),
                  const SizedBox(height: 24),
                  if (_dbEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _importSeed,
                        child: Text(l10n.importSeed),
                      ),
                    )
                  else
                    Text(l10n.importSeedDescription),
                  const SizedBox(height: 24),
                  Text(l10n.versionLabel(version: _appVersion)),
                ],
              ),
            ),
    );
  }
}
