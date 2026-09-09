import 'dart:async';
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
    'load, and does not retry again even when the fresh URL also fails',
    (tester) async {
      // _AlwaysFailingHttpOverrides fails every request, so the fresh URL
      // returned here is guaranteed to also fail to load once applied —
      // that's the scenario this test is specifically about.
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

      // Let the failed network image settle, its errorBuilder run, the
      // post-frame callback trigger the refresh, and then the fresh URL
      // itself fail to load too — all within this single settle.
      await tester.pumpAndSettle();

      verify(
        () => repository.refreshVehicleImageUrl('vehicles/car-1/photo.jpg'),
      ).called(1);

      // The fresh URL failing again must not trigger a second refresh
      // attempt — _hasRetried should still be blocking it, leaving the
      // widget settled on the fallback rather than stuck retrying.
      expect(find.text('placeholder'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      verifyNoMoreInteractions(repository);
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

  testWidgets(
    'discards a stale refresh response that resolves after the widget '
    'already moved on to a newer imageUrl',
    (tester) async {
      final responses = [Completer<String?>(), Completer<String?>()];
      var callCount = 0;
      when(
        () => repository.refreshVehicleImageUrl('vehicles/car-1/photo.jpg'),
      ).thenAnswer((_) => responses[callCount++].future);

      HttpOverrides.global = _AlwaysFailingHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      Widget buildWidget(String imageUrl) {
        return MaterialApp(
          home: GarageVehicleNetworkImage(
            imagePath: 'vehicles/car-1/photo.jpg',
            imageUrl: imageUrl,
            errorBuilder: (context) => const Text('placeholder'),
          ),
        );
      }

      // First load fails and kicks off the first refresh (call #1), which
      // we keep pending via responses[0].
      await tester.pumpWidget(buildWidget('https://cdn.example.com/stale-1'));
      await tester.pumpAndSettle();

      // Before call #1 resolves, the parent rebuilds with a newer URL
      // (e.g. the vehicle list reloaded elsewhere in the app). This also
      // fails to load and kicks off a second refresh (call #2).
      await tester.pumpWidget(buildWidget('https://cdn.example.com/stale-2'));
      await tester.pumpAndSettle();

      expect(callCount, 2);

      // Call #1 (stale) resolves last-ish but for an outdated generation —
      // it must be ignored rather than clobbering call #2's result.
      responses[0].complete('https://cdn.example.com/fresh-from-call-1');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('https://cdn.example.com/fresh-from-call-1')),
        findsNothing,
      );

      // Call #2 (current) resolves and should be the one actually applied.
      responses[1].complete('https://cdn.example.com/fresh-from-call-2');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('https://cdn.example.com/fresh-from-call-2')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'resets its retry state when only imagePath changes, even if imageUrl '
    'coincidentally stays the same (e.g. the widget got reused for a '
    'different vehicle at the same list position)',
    (tester) async {
      const sharedUrl = 'https://cdn.example.com/shared-signed-url';

      when(
        () => repository.refreshVehicleImageUrl('path-A'),
      ).thenAnswer((_) async => null);
      when(
        () => repository.refreshVehicleImageUrl('path-B'),
      ).thenAnswer((_) async => null);

      HttpOverrides.global = _AlwaysFailingHttpOverrides();
      addTearDown(() => HttpOverrides.global = null);

      Widget buildWidget(String imagePath) {
        return MaterialApp(
          home: GarageVehicleNetworkImage(
            imagePath: imagePath,
            imageUrl: sharedUrl,
            errorBuilder: (context) => const Text('placeholder'),
          ),
        );
      }

      // Vehicle A's photo fails to load and already exhausts its one retry.
      await tester.pumpWidget(buildWidget('path-A'));
      await tester.pumpAndSettle();
      verify(() => repository.refreshVehicleImageUrl('path-A')).called(1);

      // The list reorders and this same widget position now renders
      // vehicle B — a different imagePath, but its imageUrl happens to be
      // the exact same string as vehicle A's (both unsigned/placeholder,
      // for instance).
      await tester.pumpWidget(buildWidget('path-B'));
      await tester.pumpAndSettle();

      // Vehicle B deserves its own retry attempt — it must not inherit
      // vehicle A's already-used _hasRetried flag.
      verify(() => repository.refreshVehicleImageUrl('path-B')).called(1);
    },
  );
}
