import '../models/workshop_model.dart';

abstract class WorkshopRemoteDataSource {
  Future<List<WorkshopModel>> getWorkshops();

  Future<WorkshopModel?> getWorkshopById(String id);
}
