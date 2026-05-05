import '../entities/product.dart';

class ProductSearchFilter {
  const ProductSearchFilter();

  List<Product> filter({
    required List<Product> products,
    required String query,
  }) {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return products
        .where((product) {
          final searchableText = [
            product.name,
            product.description,
            product.categoryName,
            product.brandName,
            product.providerName,
            product.workshopName,
            product.skuNumber,
            product.barcode,
            _formatItemType(product.itemType),
          ].join(' ');

          return _normalize(searchableText).contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  String _formatItemType(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'service') {
      return 'servicio';
    }

    if (normalized == 'product') {
      return 'producto';
    }

    if (normalized == 'part') {
      return 'repuesto';
    }

    if (normalized == 'supply') {
      return 'insumo';
    }

    return normalized;
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
