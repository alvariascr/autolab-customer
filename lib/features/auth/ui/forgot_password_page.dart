import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/autolab_customer.dart';
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
  PasswordRecoveryCubit? _passwordRecoveryCubit;

  PasswordRecoveryCubit get _cubit {
    return _passwordRecoveryCubit ??= PasswordRecoveryCubit(
      context.read<AuthRepository>(),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordRecoveryCubit?.close();
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
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AutolabCustomer.authBackgroundColor(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = MediaQuery.of(context).size.height;
            final isTabletWeb = w >= 700;
            final isWideWeb = w >= 1100;
            final cardWidth = isWideWeb
                ? 560.0
                : isTabletWeb
                ? 520.0
                : (w * 0.88).clamp(300.0, 420.0);
            final cardHeight = h;
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
                  cardHeight: cardHeight,
                ),
              ),
            );
          },
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
    required this.cardHeight,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final VoidCallback onSubmit;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<PasswordRecoveryCubit>().state;
    final isLoading = state.status == PasswordRecoveryStatus.submitting;
    final successMessage = state.status == PasswordRecoveryStatus.success
        ? l10n.authPasswordResetEmailSent
        : null;
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
    final isCompactHeight = cardHeight < 720;
    final topPadding = (cardHeight * (isCompactHeight ? 0.18 : 0.30)).clamp(
      56.0,
      220.0,
    );
    final titleSize = isCompactHeight ? 24.0 : 28.0;
    final subtitleSize = isCompactHeight ? 15.0 : 18.0;
    final buttonHeight = isCompactHeight ? 50.0 : 54.0;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          topPadding.toDouble(),
          0,
          AutolabCustomer.spacingLg + keyboardInset,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authForgotPasswordTitle,
                style: AutolabCustomer.h1.copyWith(
                  color: AutolabCustomer.authTextColor(context),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isCompactHeight ? 8 : 12),
              Text(
                l10n.authForgotPasswordSubtitle,
                style: AutolabCustomer.bodyLarge.copyWith(
                  color: AutolabCustomer.authTextColor(context),
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
              SizedBox(height: isCompactHeight ? 18 : 26),
              if (errorMessage != null) ...[
                AuthErrorBanner(message: errorMessage),
                const SizedBox(height: 16),
              ] else if (successMessage != null) ...[
                AuthErrorBanner(
                  message: successMessage,
                  variant: AuthBannerVariant.success,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                cursorColor: AutolabCustomer.primary,
                style: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.authTextColor(context),
                ),
                decoration: buildAuthInputDecoration(
                  context: context,
                  label: l10n.authLoginEmailLabel,
                  hint: l10n.authLoginEmailHint,
                  icon: Icons.email_outlined,
                ),
                validator: (value) => Validators.email(value, l10n),
              ),
              SizedBox(height: isCompactHeight ? 24 : 36),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: AutolabCustomer.primaryButton.copyWith(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AutolabCustomer.white,
                          ),
                        )
                      : Text(
                          l10n.authForgotPasswordSubmit,
                          style: AutolabCustomer.h3.copyWith(
                            color: AutolabCustomer.white,
                            fontSize: isCompactHeight ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isCompactHeight ? 12 : 18),
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go('/login?mode=login'),
                  child: Text(
                    l10n.authPasswordResetBackToLogin,
                    style: AutolabCustomer.bodyLarge.copyWith(
                      color: AutolabCustomer.authTextColor(context),
                      fontSize: isCompactHeight ? 15 : 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
