import 'dart:io';

import 'package:autolab_customer/core/di/app_injection.dart';
import 'package:autolab_customer/features/profile/domain/repositories/garage_vehicle_repository.dart';
import 'package:autolab_customer/features/profile/presentation/widgets/garage_vehicle_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGarageVehicleRepository extends Mock
    implements GarageVehicleRepository {}

/// Every request fails immediately, so any [Image.network] under test
/// deterministically hits its `errorBuilder`, regardless of the CI
/// runner's actual network access.
class _AlwaysFailingHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    throw const SocketException('network disabled for this test');
  }
}

class _AlwaysFailingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _AlwaysFailingHttpClient();
}

void main() {
  late _MockGarageVehicleRepository repository;

  setUp(() {
    repository = _MockGarageVehicleRepository();
    sl.registerSingleton<GarageVehicleRepository>(repository);
  });

  tearDown(() async {
    await sl.unregister<GarageVehicleRepository>();
  });

  testWidgets(
    'refreshes the signed URL exactly once after the current one fails to '
    'load, and does not retry again for the same failure',
    (tester) async {
      when(
        () => repository.refreshVehicleImageUrl('vehicles/car-1/photo.jpg'),
      ).thenAnswer((_) async => 'https://cdn.example.com/fresh-signed-url');

      HttpOverrides.global = _AlwaysFailingHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(
        MaterialApp(
          home: GarageVehicleNetworkImage(
            imagePath: 'vehicles/car-1/photo.jpg',
            imageUrl: 'https://cdn.example.com/stale-signed-url',
            errorBuilder: (context) => const Text('placeholder'),
          ),
        ),
      );

      // Let the failed network image settle, its errorBuilder run, and the
      // post-frame callback trigger the refresh.
      await tester.pumpAndSettle();

      verify(
        () => repository.refreshVehicleImageUrl('vehicles/car-1/photo.jpg'),
      ).called(1);
    },
  );

  testWidgets(
    'never calls refreshVehicleImageUrl when no imagePath is available',
    (tester) async {
      HttpOverrides.global = _AlwaysFailingHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(
        MaterialApp(
          home: GarageVehicleNetworkImage(
            imagePath: null,
            imageUrl: 'https://cdn.example.com/stale-signed-url',
            errorBuilder: (context) => const Text('placeholder'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      verifyNever(() => repository.refreshVehicleImageUrl(any()));
      expect(find.text('placeholder'), findsOneWidget);
    },
  );
}
