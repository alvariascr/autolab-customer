import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl({
    required this.remoteDataSource,
    required this.errorHandler,
    required this.featureLogger,
    required this.currentUserIdProvider,
  });

  final AppointmentRemoteDataSource remoteDataSource;
  final GlobalErrorHandler errorHandler;
  final FeatureLogger featureLogger;
  final String? Function() currentUserIdProvider;

  @override
  Future<Either<Failure, Appointment>> createAppointment(
    AppointmentDraft draft,
  ) {
    return _guard(
      action: 'create_appointment',
      context: {'workshopId': draft.workshopId, 'serviceId': draft.serviceId},
      loader: () => remoteDataSource.createAppointment(draft),
    );
  }

  @override
  Future<Either<Failure, List<Appointment>>> getAppointmentsByWorkshop(
    String workshopId,
  ) {
    return _guard(
      action: 'get_appointments_by_workshop',
      context: {'workshopId': workshopId},
      loader: () async {
        final customerId = currentUserIdProvider();
        if (customerId == null || customerId.isEmpty) {
          return const <Appointment>[];
        }

        final appointments = await remoteDataSource.getAppointmentsByWorkshop(
          workshopId,
        );

        return appointments
            .where((appointment) => appointment.customerId == customerId)
            .toList();
      },
    );
  }

  Future<Either<Failure, T>> _guard<T>({
    required String action,
    required Future<T> Function() loader,
    Map<String, Object?> context = const {},
  }) async {
    try {
      featureLogger.info(
        feature: 'appointments',
        action: '${action}_started',
        context: context,
      );
      final result = await loader();
      featureLogger.info(
        feature: 'appointments',
        action: '${action}_succeeded',
        context: context,
      );
      return Right(result);
    } on TimeoutException catch (error, stackTrace) {
      final failure = TimeoutFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'appointments',
        action: '${action}_timeout',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } on SocketException catch (error, stackTrace) {
      final failure = NetworkFailure.fromErrorItem(
        CustomerErrorCatalog.workshopNetworkError,
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'appointments',
        action: '${action}_network_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } on PostgrestException catch (error, stackTrace) {
      final failure = ServerFailure.fromErrorItem(
        _serverErrorItemFor(action),
        cause: error,
        stackTrace: stackTrace,
      );
      featureLogger.warn(
        feature: 'appointments',
        action: '${action}_server_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    } catch (error, stackTrace) {
      final failure = errorHandler.handle(error, stackTrace);
      featureLogger.error(
        feature: 'appointments',
        action: '${action}_unhandled_failed',
        code: failure.code,
        context: context,
        error: error,
        stackTrace: stackTrace,
      );
      return Left(failure);
    }
  }

  ErrorItem _serverErrorItemFor(String action) {
    return switch (action) {
      'create_appointment' => CustomerErrorCatalog.createAppointmentFailed,
      _ => CustomerErrorCatalog.workshopLoadFailed,
    };
  }
}
