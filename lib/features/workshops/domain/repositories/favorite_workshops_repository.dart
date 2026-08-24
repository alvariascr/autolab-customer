import '../entities/workshop.dart';

abstract interface class FavoriteWorkshopsRepository {
  Future<List<Workshop>> getFavoriteWorkshops();

  Future<bool> isFavoriteWorkshop(String workshopId);

  Future<bool> toggleFavoriteWorkshop(String workshopId);

  Future<void> removeFavoriteWorkshop(String workshopId);
}
