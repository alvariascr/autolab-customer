import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/workshop.dart';

abstract class WorkshopRepository {
  Future<Either<Failure, List<Workshop>>> getWorkshops();

  Future<Either<Failure, Workshop?>> getWorkshopById(String id);
}
