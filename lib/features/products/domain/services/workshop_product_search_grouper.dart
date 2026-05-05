import '../../../workshops/domain/entities/workshop.dart';
import '../entities/product.dart';

class WorkshopProductSearchResult {
  const WorkshopProductSearchResult({
    required this.workshop,
    required this.products,
  });

  final Workshop workshop;
  final List<Product> products;

  int get count => products.length;
}

class WorkshopProductSearchGrouper {
  const WorkshopProductSearchGrouper();

  List<WorkshopProductSearchResult> group({
    required List<Product> products,
    required List<Workshop> workshops,
  }) {
    final workshopsById = {
      for (final workshop in workshops) workshop.id: workshop,
    };
    final groupedProducts = <String, List<Product>>{};

    for (final product in products) {
      final workshopId = product.workshopId.trim();

      if (workshopId.isEmpty || !workshopsById.containsKey(workshopId)) {
        continue;
      }

      groupedProducts.putIfAbsent(workshopId, () => <Product>[]).add(product);
    }

    final results = groupedProducts.entries.map((entry) {
      return WorkshopProductSearchResult(
        workshop: workshopsById[entry.key]!,
        products: entry.value,
      );
    }).toList();

    results.sort((left, right) {
      final countComparison = right.count.compareTo(left.count);

      if (countComparison != 0) {
        return countComparison;
      }

      return left.workshop.name.compareTo(right.workshop.name);
    });

    return results;
  }
}
