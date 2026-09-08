import '../entities/workshop.dart';

abstract interface class FavoriteWorkshopsRepository {
  Future<List<Workshop>> getFavoriteWorkshops();

  Future<bool> isFavoriteWorkshop(String workshopId);

  Future<bool> toggleFavoriteWorkshop(String workshopId);

  Future<void> removeFavoriteWorkshop(String workshopId);
}

class FavoriteWorkshopAuthException implements Exception {
  const FavoriteWorkshopAuthException();
}

class FavoriteWorkshopStorageFailure implements Exception {
  const FavoriteWorkshopStorageFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => error.toString();
}
