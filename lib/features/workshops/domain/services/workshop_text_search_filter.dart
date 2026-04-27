import '../entities/workshop.dart';

class WorkshopTextSearchFilter {
  const WorkshopTextSearchFilter();

  List<Workshop> filter({
    required List<Workshop> workshops,
    required String query,
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return workshops;
    }

    return workshops
        .where((workshop) {
          return _normalize(workshop.name).contains(normalizedQuery) ||
              _normalize(workshop.description).contains(normalizedQuery) ||
              _normalize(workshop.locationAddress).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
