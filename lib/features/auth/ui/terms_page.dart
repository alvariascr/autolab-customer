import 'package:flutter/material.dart';

import '../../../core/theme/autolab_customer.dart';
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
            style: AutolabCustomer.body.copyWith(
              color: AutolabCustomer.customerTextColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
