import 'package:autolab_core/autolab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../workshops/domain/entities/workshop.dart';
import '../../workshops/domain/services/workshop_proximity_filter.dart';
import '../../workshops/domain/services/workshop_text_search_filter.dart';
import '../../workshops/presentation/widgets/workshop_card.dart';
import '../../workshops/presentation/workshop_empty_state_resolver.dart';

class SearchBarOverlay extends StatefulWidget {
  const SearchBarOverlay({
    super.key,
    required this.showSearchBar,
    required this.controller,
    required this.workshops,
    required this.currentLocation,
    required this.isLoading,
    required this.workshopFailure,
    required this.onClose,
  });

  static const _textSearchFilter = WorkshopTextSearchFilter();
  static const _proximityFilter = WorkshopProximityFilter();

  final bool showSearchBar;
  final TextEditingController controller;
  final List<Workshop> workshops;
  final CurrentLocation? currentLocation;
  final bool isLoading;
  final Failure? workshopFailure;
  final VoidCallback onClose;

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  static const _maxRecentSearches = 6;
  static const _suggestedSearches = <String>[
    'Talleres',
    'Frenos',
    'Suspensión',
    'Escazú',
  ];

  final List<String> _recentSearches = <String>[];

  void _saveRecentSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == query.toLowerCase(),
      );
      _recentSearches.insert(0, query);

      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches.removeRange(_maxRecentSearches, _recentSearches.length);
      }
    });
  }

  void _selectRecentSearch(String query) {
    widget.controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchableWorkshops = widget.currentLocation == null
        ? widget.workshops
        : SearchBarOverlay._proximityFilter.filterNearby(
            workshops: widget.workshops,
            currentLocation: widget.currentLocation,
          );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      top: widget.showSearchBar ? 0 : MediaQuery.sizeOf(context).height,
      left: 0,
      right: 0,
      bottom: widget.showSearchBar ? 0 : -MediaQuery.sizeOf(context).height,
      child: IgnorePointer(
        ignoring: !widget.showSearchBar,
        child: Material(
          color: const Color(0xFFF8F4EF),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('workshop-search-close-button'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _saveRecentSearch(widget.controller.text);
                          widget.controller.clear();
                          widget.onClose();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.controller,
                          builder: (context, value, child) {
                            return TextField(
                              key: const ValueKey(
                                'workshop-search-overlay-field',
                              ),
                              controller: widget.controller,
                              autofocus: widget.showSearchBar,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _saveRecentSearch,
                              decoration: InputDecoration(
                                hintText: l10n.searchBarHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: value.text.isEmpty
                                    ? null
                                    : IconButton(
                                        key: const ValueKey(
                                          'workshop-search-clear-button',
                                        ),
                                        tooltip:
                                            l10n.workshopSearchClearTooltip,
                                        onPressed: () {
                                          _saveRecentSearch(value.text);
                                          widget.controller.clear();
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.workshopSearchTitle,
                    style: const TextStyle(
                      color: Color(0xFF181411),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, child) {
                      final query = value.text.trim();

                      if (query.isEmpty) {
                        return _RecentSearches(
                          recentSearches: _recentSearches,
                          suggestedSearches: _suggestedSearches,
                          onSelected: _selectRecentSearch,
                        );
                      }

                      final results = SearchBarOverlay._textSearchFilter.filter(
                        workshops: searchableWorkshops,
                        query: query,
                      );

                      return _WorkshopSearchResults(
                        workshops: results,
                        query: query,
                        currentLocation: widget.currentLocation,
                        isLoading: widget.isLoading,
                        failure: widget.workshopFailure,
                        onSearchCommitted: _saveRecentSearch,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopSearchResults extends StatelessWidget {
  const _WorkshopSearchResults({
    required this.workshops,
    required this.query,
    required this.currentLocation,
    required this.isLoading,
    required this.failure,
    required this.onSearchCommitted,
  });

  final List<Workshop> workshops;
  final String query;
  final CurrentLocation? currentLocation;
  final bool isLoading;
  final Failure? failure;
  final ValueChanged<String> onSearchCommitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (failure != null) {
      return _SearchEmptyMessage(
        message: _SearchBarOverlayFailureResolver.resolve(failure!, l10n),
      );
    }

    if (workshops.isEmpty) {
      return _SearchEmptyMessage(
        message: query.isEmpty
            ? l10n.workshopSearchStartMessage
            : l10n.workshopSearchNoResults,
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
      itemCount: workshops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final workshop = workshops[index];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            onSearchCommitted(query);
            _showWorkshopDetails(context, workshop);
          },
          child: WorkshopCard(
            workshop: workshop,
            referenceLocation: currentLocation,
            compact: true,
          ),
        );
      },
    );
  }

  void _showWorkshopDetails(BuildContext context, Workshop workshop) {
    context.push('/workshops/${workshop.id}');
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.recentSearches,
    required this.suggestedSearches,
    required this.onSelected,
  });

  final List<String> recentSearches;
  final List<String> suggestedSearches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final hasRecentSearches = recentSearches.isNotEmpty;
    final chips = hasRecentSearches ? recentSearches : suggestedSearches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          hasRecentSearches
              ? l10n.workshopSearchRecentTitle
              : l10n.workshopSearchSuggestedTitle,
          style: const TextStyle(
            color: Color(0xFF181411),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((query) {
            return ActionChip(
              key: ValueKey(
                hasRecentSearches
                    ? 'recent-search-$query'
                    : 'suggested-search-$query',
              ),
              avatar: Icon(
                hasRecentSearches
                    ? Icons.history_rounded
                    : Icons.search_rounded,
                size: 17,
              ),
              label: Text(query),
              onPressed: () => onSelected(query),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE9DDD2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF181411),
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchEmptyMessage extends StatelessWidget {
  const _SearchEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B5F57),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _SearchBarOverlayFailureResolver {
  const _SearchBarOverlayFailureResolver._();

  static const _resolver = WorkshopEmptyStateResolver();

  static String resolve(Failure failure, AppLocalizations l10n) {
    return _resolver.resolveLoadError(failure, l10n);
  }
}
