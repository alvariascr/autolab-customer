import '../../domain/entities/workshop.dart';
import '../../domain/repositories/favorite_workshops_repository.dart';
import '../datasources/favorite_workshops_remote_data_source.dart';

class FavoriteWorkshopsRepositoryImpl implements FavoriteWorkshopsRepository {
  const FavoriteWorkshopsRepositoryImpl(this._remoteDataSource);

  final FavoriteWorkshopsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Workshop>> getFavoriteWorkshops() {
    return _remoteDataSource.getFavoriteWorkshops();
  }

  @override
  Future<bool> isFavoriteWorkshop(String workshopId) {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return Future.value(false);
    }

    return _remoteDataSource.isFavoriteWorkshop(trimmedWorkshopId);
  }

  @override
  Future<bool> toggleFavoriteWorkshop(String workshopId) {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return Future.value(false);
    }

    return _remoteDataSource.toggleFavoriteWorkshop(trimmedWorkshopId);
  }

  @override
  Future<void> removeFavoriteWorkshop(String workshopId) {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return Future.value();
    }

    return _remoteDataSource.removeFavoriteWorkshop(trimmedWorkshopId);
  }
}
