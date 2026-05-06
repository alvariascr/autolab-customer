import 'package:flutter/foundation.dart';

class WorkshopDiscoveryQueryStore extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void setQuery(String value) {
    final normalized = value.trim();

    if (_query == normalized) {
      return;
    }

    _query = normalized;
    notifyListeners();
  }

  void clear() {
    setQuery('');
  }
}
