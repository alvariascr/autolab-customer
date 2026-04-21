import '../entities/workshop.dart';

abstract class WorkshopRepository {
  Future<List<Workshop>> getWorkshops();
}