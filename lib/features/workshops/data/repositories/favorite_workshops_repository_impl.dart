import '../../domain/entities/workshop.dart';
import '../../domain/repositories/favorite_workshops_repository.dart';
import '../datasources/favorite_workshops_remote_data_source.dart';

class FavoriteWorkshopsRepositoryImpl implements FavoriteWorkshopsRepository {
  const FavoriteWorkshopsRepositoryImpl(this._remoteDataSource);

  final FavoriteWorkshopsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Workshop>> getFavoriteWorkshops() async {
    try {
      return await _remoteDataSource.getFavoriteWorkshops();
    } on FavoriteWorkshopAuthRequiredException {
      throw const FavoriteWorkshopAuthException();
    } on FavoriteWorkshopStorageException catch (error) {
      throw FavoriteWorkshopStorageFailure(error.error, error.stackTrace);
    }
  }

  @override
  Future<bool> isFavoriteWorkshop(String workshopId) async {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return false;
    }

    try {
      return await _remoteDataSource.isFavoriteWorkshop(trimmedWorkshopId);
    } on FavoriteWorkshopAuthRequiredException {
      throw const FavoriteWorkshopAuthException();
    } on FavoriteWorkshopStorageException catch (error) {
      throw FavoriteWorkshopStorageFailure(error.error, error.stackTrace);
    }
  }

  @override
  Future<bool> toggleFavoriteWorkshop(String workshopId) async {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return false;
    }

    try {
      return await _remoteDataSource.toggleFavoriteWorkshop(trimmedWorkshopId);
    } on FavoriteWorkshopAuthRequiredException {
      throw const FavoriteWorkshopAuthException();
    } on FavoriteWorkshopStorageException catch (error) {
      throw FavoriteWorkshopStorageFailure(error.error, error.stackTrace);
    }
  }

  @override
  Future<void> removeFavoriteWorkshop(String workshopId) async {
    final trimmedWorkshopId = workshopId.trim();
    if (trimmedWorkshopId.isEmpty) {
      return;
    }

    try {
      await _remoteDataSource.removeFavoriteWorkshop(trimmedWorkshopId);
    } on FavoriteWorkshopAuthRequiredException {
      throw const FavoriteWorkshopAuthException();
    } on FavoriteWorkshopStorageException catch (error) {
      throw FavoriteWorkshopStorageFailure(error.error, error.stackTrace);
    }
  }
}
