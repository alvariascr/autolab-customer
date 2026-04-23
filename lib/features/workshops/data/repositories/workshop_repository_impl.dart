import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../domain/entities/workshop.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../datasources/workshop_remote_data_source.dart';

class WorkshopRepositoryImpl implements WorkshopRepository {
  WorkshopRepositoryImpl({
    required this.remoteDataSource,
    required this.errorHandler,
  });

  final WorkshopRemoteDataSource remoteDataSource;
  final GlobalErrorHandler errorHandler;

  @override
  Future<Either<Failure, List<Workshop>>> getWorkshops() async {
    try {
      final workshops = await remoteDataSource.getWorkshops();
      return Right(workshops);
    } on TimeoutException catch (error, stackTrace) {
      return Left(
        TimeoutFailure.fromErrorItem(
          CustomerErrorCatalog.workshopNetworkError,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on SocketException catch (error, stackTrace) {
      return Left(
        NetworkFailure.fromErrorItem(
          CustomerErrorCatalog.workshopNetworkError,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on PostgrestException catch (error, stackTrace) {
      return Left(
        ServerFailure.fromErrorItem(
          CustomerErrorCatalog.workshopLoadFailed,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return Left(errorHandler.handle(error, stackTrace));
    }
  }
}
