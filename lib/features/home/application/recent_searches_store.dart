import 'package:shared_preferences/shared_preferences.dart';

abstract class RecentSearchesStore {
  Future<List<String>> load();

  Future<List<String>> save(String query);
}

class SharedPreferencesRecentSearchesStore implements RecentSearchesStore {
  SharedPreferencesRecentSearchesStore(this._preferences, {this.maxItems = 6});

  static const _key = 'home.search.recent_queries';

  final SharedPreferences _preferences;
  final int maxItems;

  @override
  Future<List<String>> load() async {
    return _preferences.getStringList(_key) ?? const <String>[];
  }

  @override
  Future<List<String>> save(String query) async {
    final normalizedQuery = query.trim();
    final currentSearches = await load();

    if (normalizedQuery.isEmpty) {
      return currentSearches;
    }

    final searches = <String>[
      normalizedQuery,
      ...currentSearches.where(
        (item) => item.toLowerCase() != normalizedQuery.toLowerCase(),
      ),
    ];
    final limitedSearches = searches.take(maxItems).toList(growable: false);

    await _preferences.setStringList(_key, limitedSearches);

    return limitedSearches;
  }
}

class MemoryRecentSearchesStore implements RecentSearchesStore {
  MemoryRecentSearchesStore({this.maxItems = 6});

  final int maxItems;
  final List<String> _searches = <String>[];

  @override
  Future<List<String>> load() async => List.unmodifiable(_searches);

  @override
  Future<List<String>> save(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(_searches);
    }

    _searches.removeWhere(
      (item) => item.toLowerCase() == normalizedQuery.toLowerCase(),
    );
    _searches.insert(0, normalizedQuery);

    if (_searches.length > maxItems) {
      _searches.removeRange(maxItems, _searches.length);
    }

    return List.unmodifiable(_searches);
  }
}
