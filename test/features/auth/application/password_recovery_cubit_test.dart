import 'package:autolab_core/autolab_core.dart';
import 'package:autolab_customer/features/auth/application/password_recovery_cubit.dart';
import 'package:autolab_customer/features/auth/application/password_recovery_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_auth_repository.dart';

void _stubSendPasswordResetSuccess(MockAuthRepository repository) {
  when(
    () => repository.sendPasswordResetEmail(any()),
  ).thenAnswer((_) async => const Right(unit));
}

void _stubUpdatePasswordFailure(MockAuthRepository repository) {
  when(() => repository.updatePassword(any())).thenAnswer(
    (_) async => const Left(AuthFailure(message: 'No se pudo actualizar')),
  );
}

void main() {
  group('PasswordRecoveryCubit', () {
    test('sendResetEmail emite submitting y success', () async {
      final repository = MockAuthRepository();
      _stubSendPasswordResetSuccess(repository);
      final cubit = PasswordRecoveryCubit(repository);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.submitting,
          ),
          const PasswordRecoveryState(status: PasswordRecoveryStatus.success),
        ]),
      );

      await cubit.sendResetEmail(email: 'test@test.com');
      await expectation;
      await cubit.close();
    });

    test('updatePassword emite submitting y error', () async {
      final repository = MockAuthRepository();
      _stubUpdatePasswordFailure(repository);
      final cubit = PasswordRecoveryCubit(repository);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.submitting,
          ),
          const PasswordRecoveryState(
            status: PasswordRecoveryStatus.error,
            message: 'No se pudo actualizar',
          ),
        ]),
      );

      await cubit.updatePassword(password: '123456');
      await expectation;
      await cubit.close();
    });
  });
}
