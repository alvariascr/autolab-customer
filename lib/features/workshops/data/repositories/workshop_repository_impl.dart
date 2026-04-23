import '../../domain/entities/workshop.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../datasources/workshop_remote_data_source.dart';

class WorkshopRepositoryImpl implements WorkshopRepository {
  final WorkshopRemoteDataSource remoteDataSource;

  WorkshopRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Workshop>> getWorkshops() async {
    return await remoteDataSource.getWorkshops();
  }
}
