import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SearchBarOverlay extends StatelessWidget {
  const SearchBarOverlay({
    super.key,
    required this.showSearchBar,
    required this.controller,
  });

  final bool showSearchBar;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      top: showSearchBar ? 16 : -100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            autofocus: showSearchBar,
            decoration: InputDecoration(
              icon: const Icon(Icons.search),
              hintText: l10n.searchBarHint,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
