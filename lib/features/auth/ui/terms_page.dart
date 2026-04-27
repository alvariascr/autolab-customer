import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTermsPageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            l10n.authTermsPageBody,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}
