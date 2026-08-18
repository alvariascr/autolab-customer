abstract interface class HomeServicePopularityStore {
  Future<Map<String, int>> loadClickCounts();

  Future<int> recordClick(String serviceKey);
}

List<T> sortByServicePopularity<T>({
  required List<T> items,
  required String Function(T item) serviceKeyOf,
  required Map<String, int> clickCounts,
}) {
  final originalPositions = <String, int>{
    for (var index = 0; index < items.length; index++)
      serviceKeyOf(items[index]): index,
  };
  final sortedItems = List<T>.of(items);

  sortedItems.sort((left, right) {
    final leftKey = serviceKeyOf(left);
    final rightKey = serviceKeyOf(right);
    final countComparison = (clickCounts[rightKey] ?? 0).compareTo(
      clickCounts[leftKey] ?? 0,
    );
    if (countComparison != 0) return countComparison;

    return originalPositions[leftKey]!.compareTo(originalPositions[rightKey]!);
  });

  return sortedItems;
}
