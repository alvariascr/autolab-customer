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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();
    context.read<PasswordRecoveryCubit>().sendResetEmail(
      email: _emailCtrl.text.trim(),
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
                content: Text(l10n.authPasswordResetEmailSent),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
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
              final cardHeight = (h * 0.78).clamp(500.0, 640.0);
              final logoSize = isTabletWeb ? 210.0 : 180.0;

              return Center(
                child: AuthCardShell(
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  logoSize: logoSize,
                  child: _ForgotPasswordForm(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
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

class _ForgotPasswordForm extends StatelessWidget {
  const _ForgotPasswordForm({
    required this.formKey,
    required this.emailCtrl,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
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
              l10n.authForgotPasswordTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.authForgotPasswordSubtitle,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (errorMessage != null) ...[
              AuthErrorBanner(message: errorMessage),
              const SizedBox(height: 15),
            ],
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: buildAuthInputDecoration(
                label: l10n.authLoginEmailLabel,
                hint: l10n.authLoginEmailHint,
                icon: Icons.email_outlined,
              ),
              validator: (value) => Validators.email(value, l10n),
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
                        l10n.authForgotPasswordSubmit,
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
