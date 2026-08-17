import 'dart:async';
import 'dart:io';

import 'package:autolab_core/autolab_core.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/customer_error_catalog.dart';
import '../../../../core/logging/feature_logger.dart';
import '../../../auth/domain/errors/auth_error_catalog.dart';
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
  Future<Either<Failure, List<Appointment>>> getAppointmentsByWorkshop(
    String workshopId,
  ) {
    return _guard(
      action: 'get_appointments_by_workshop',
      context: {'workshopId': workshopId},
      loader: () async {
        final customerId = _currentCustomerId();

        return remoteDataSource.getAppointmentsByWorkshop(
          workshopId: workshopId,
          customerId: customerId,
        );
      },
    );
  }

  @override
  Future<Either<Failure, List<Appointment>>> getCustomerAppointments() {
    return _guard(
      action: 'get_customer_appointments',
      loader: () async {
        final customerId = _currentCustomerId();

        return remoteDataSource.getCustomerAppointments(customerId: customerId);
      },
    );
  }

  @override
  Future<Either<Failure, Appointment>> cancelAppointment({
    required String appointmentId,
    required String reason,
    String? comments,
  }) {
    return _guard(
      action: 'cancel_appointment',
      context: {'appointmentId': appointmentId},
      loader: () async {
        final customerId = _currentCustomerId();

        return remoteDataSource.cancelAppointment(
          appointmentId: appointmentId,
          customerId: customerId,
          reason: reason,
          comments: comments,
        );
      },
    );
  }

  @override
  Future<Either<Failure, Appointment>> rescheduleAppointment({
    required String appointmentId,
    required DateTime scheduledAt,
  }) {
    return _guard(
      action: 'reschedule_appointment',
      context: {'appointmentId': appointmentId},
      loader: () async {
        final customerId = _currentCustomerId();

        return remoteDataSource.rescheduleAppointment(
          appointmentId: appointmentId,
          customerId: customerId,
          scheduledAt: scheduledAt,
        );
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
    } on Failure catch (failure) {
      featureLogger.warn(
        feature: 'appointments',
        action: '${action}_domain_failed',
        code: failure.code,
        context: context,
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

  String _currentCustomerId() {
    final customerId = currentUserIdProvider();
    if (customerId == null || customerId.isEmpty) {
      throw AuthFailure.fromErrorItem(AuthErrorCatalog.sessionExpired);
    }

    return customerId;
  }
}
