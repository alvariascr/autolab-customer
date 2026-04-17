import 'package:autolab_customer/core/location/location_permission_client.dart';
import 'package:autolab_customer/core/location/location_permission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationPermissionClient extends Mock
    implements LocationPermissionClient {}

void main() {
  group('GeolocatorLocationPermissionService', () {
    late MockLocationPermissionClient client;
    late LocationPermissionService service;

    setUp(() {
      client = MockLocationPermissionClient();
      service = GeolocatorLocationPermissionService(client);
    });

    test('retorna granted cuando ya existe autorizacion valida', () async {
      when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(
        () => client.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      final status = await service.getPermissionStatus();
      final result = await service.requestWhileInUsePermission();

      expect(status, LocationPermissionStatus.granted);
      expect(result, LocationPermissionRequestResult.granted);
      verifyNever(() => client.requestPermission());
    });

    test('solicita permiso cuando el estado actual es denied', () async {
      when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(
        () => client.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => client.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      final result = await service.requestWhileInUsePermission();

      expect(result, LocationPermissionRequestResult.granted);
      verify(() => client.requestPermission()).called(1);
    });

    test('identifica denied correctamente', () async {
      when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(
        () => client.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => client.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      final status = await service.getPermissionStatus();
      final result = await service.requestWhileInUsePermission();

      expect(status, LocationPermissionStatus.denied);
      expect(result, LocationPermissionRequestResult.denied);
    });

    test('identifica deniedForever correctamente', () async {
      when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(
        () => client.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      final status = await service.getPermissionStatus();
      final result = await service.requestWhileInUsePermission();

      expect(status, LocationPermissionStatus.deniedForever);
      expect(result, LocationPermissionRequestResult.deniedForever);
      verifyNever(() => client.requestPermission());
    });

    test('identifica restricted mediante unableToDetermine', () async {
      when(() => client.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(
        () => client.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.unableToDetermine);

      final status = await service.getPermissionStatus();
      final result = await service.requestWhileInUsePermission();

      expect(status, LocationPermissionStatus.restricted);
      expect(result, LocationPermissionRequestResult.restricted);
    });

    test('no intenta solicitar permiso si el servicio esta deshabilitado', () async {
      when(
        () => client.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      final status = await service.getPermissionStatus();
      final result = await service.requestWhileInUsePermission();

      expect(status, LocationPermissionStatus.serviceDisabled);
      expect(result, LocationPermissionRequestResult.serviceDisabled);
      verifyNever(() => client.checkPermission());
      verifyNever(() => client.requestPermission());
    });
  });
}
