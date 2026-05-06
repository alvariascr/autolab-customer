import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_feedback.dart';
import '../application/password_recovery_cubit.dart';
import '../application/password_recovery_state.dart';
import '../repository/auth_repository.dart';
import 'auth_ui_error_resolver.dart';
import 'widgets/auth_card_shell.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_form_style.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  var _isPasswordHidden = true;
  var _isConfirmPasswordHidden = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();
    context.read<PasswordRecoveryCubit>().updatePassword(
      password: _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => PasswordRecoveryCubit(context.read<AuthRepository>()),
      child: Scaffold(
        body: BlocListener<PasswordRecoveryCubit, PasswordRecoveryState>(
          listener: (context, state) {
            if (state.status != PasswordRecoveryStatus.success) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.authPasswordResetSuccess),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/login');
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = MediaQuery.of(context).size.height;
              final isTabletWeb = w >= 700;
              final isWideWeb = w >= 1100;
              final cardWidth = isWideWeb
                  ? 560.0
                  : isTabletWeb
                  ? 520.0
                  : w * 0.92;
              final cardHeight = (h * 0.86).clamp(540.0, 680.0);
              final logoSize = isTabletWeb ? 210.0 : 180.0;

              return Center(
                child: AuthCardShell(
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  logoSize: logoSize,
                  child: _ResetPasswordForm(
                    formKey: _formKey,
                    passwordCtrl: _passwordCtrl,
                    confirmPasswordCtrl: _confirmPasswordCtrl,
                    isPasswordHidden: _isPasswordHidden,
                    isConfirmPasswordHidden: _isConfirmPasswordHidden,
                    onTogglePassword: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                    onToggleConfirmPassword: () {
                      setState(() {
                        _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                      });
                    },
                    onSubmit: () => _submit(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm({
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.isPasswordHidden,
    required this.isConfirmPasswordHidden,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool isPasswordHidden;
  final bool isConfirmPasswordHidden;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<PasswordRecoveryCubit>().state;
    final isLoading = state.status == PasswordRecoveryStatus.submitting;
    final errorMessage =
        state.status == PasswordRecoveryStatus.error &&
            hasAuthFeedback(
              message: state.message,
              code: state.code,
              uiKey: state.uiKey,
            )
        ? AuthUiErrorResolver.resolve(
            l10n: l10n,
            code: state.code,
            uiKey: state.uiKey,
            message: state.message,
          )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Text(
              l10n.authResetPasswordTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.authResetPasswordSubtitle,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (errorMessage != null) ...[
              AuthErrorBanner(message: errorMessage),
              const SizedBox(height: 15),
            ],
            TextFormField(
              controller: passwordCtrl,
              obscureText: isPasswordHidden,
              decoration: buildAuthInputDecoration(
                label: l10n.authResetPasswordNewPasswordLabel,
                hint: l10n.authResetPasswordNewPasswordHint,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (value) => Validators.password(value, l10n),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: isConfirmPasswordHidden,
              decoration: buildAuthInputDecoration(
                label: l10n.authRegisterConfirmPasswordLabel,
                hint: l10n.authRegisterConfirmPasswordHint,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: onToggleConfirmPassword,
                ),
              ),
              validator: (value) {
                return Validators.confirmPassword(
                  value,
                  passwordCtrl.text,
                  l10n,
                );
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 240,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.authResetPasswordSubmit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/login'),
              child: Text(
                l10n.authPasswordResetBackToLogin,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
