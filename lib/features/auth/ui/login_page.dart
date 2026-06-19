import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/autolab_customer.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_feedback.dart';
import '../application/auth_session_cubit.dart';
import '../application/login_form_cubit.dart';
import '../application/login_form_state.dart';
import '../application/register_form_cubit.dart';
import '../application/register_form_state.dart';
import '../domain/errors/auth_error_catalog.dart';
import '../repository/auth_repository.dart';
import 'auth_ui_error_resolver.dart';
import 'register_card.dart';
import 'widgets/auth_card_shell.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_form_style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<RegisterCardState> registerCardKey =
      GlobalKey<RegisterCardState>();

  final _formKeyLogin = GlobalKey<FormState>();
  final TextEditingController _emailLoginCtrl = TextEditingController();
  final TextEditingController _passLoginCtrl = TextEditingController();

  bool _isPasswordHidden = true;
  bool _showLoginError = false;
  bool _isShowingRegister = true;
  bool _dismissEmailConfirmedMessage = false;
  bool _showRegisterSuccessMessage = false;
  bool _hasAppliedInitialMode = false;

  bool get _shouldShowInlineLoginError {
    return !_isShowingRegister && _showLoginError;
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AutolabCustomer.authErrorIcon,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AutolabCustomer.spacingLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AutolabCustomer.radiusInput + 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();
    super.dispose();
  }

  void _login(BuildContext context) {
    final ok = _formKeyLogin.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _showLoginError = true;
      _isShowingRegister = false;
      _dismissEmailConfirmedMessage = true;
      _showRegisterSuccessMessage = false;
    });

    context.read<LoginFormCubit>().submit(
      email: _emailLoginCtrl.text.trim(),
      password: _passLoginCtrl.text,
    );
  }

  void _goToRegister(BuildContext context) {
    context.read<LoginFormCubit>().reset();

    setState(() {
      _showLoginError = false;
      _isShowingRegister = true;
      _dismissEmailConfirmedMessage = true;
      _showRegisterSuccessMessage = false;
    });
  }

  void _goToLoginFromRegister(BuildContext context) {
    context.read<RegisterFormCubit>().reset();
    registerCardKey.currentState?.cleanRegistry();

    setState(() {
      _showLoginError = false;
      _isShowingRegister = false;
      _dismissEmailConfirmedMessage = true;
      _showRegisterSuccessMessage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startsInLogin =
        GoRouterState.of(context).uri.queryParameters['mode'] == 'login';

    if (!_hasAppliedInitialMode && startsInLogin && _isShowingRegister) {
      _isShowingRegister = false;
    }
    _hasAppliedInitialMode = true;

    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginFormCubit>(
          create: (_) => LoginFormCubit(context.read<AuthRepository>()),
        ),
        BlocProvider<RegisterFormCubit>(
          create: (_) => RegisterFormCubit(context.read<AuthRepository>()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AutolabCustomer.authBackgroundColor(context),
        body: MultiBlocListener(
          listeners: [
            BlocListener<LoginFormCubit, LoginFormState>(
              listener: (context, state) {
                if (state.status == LoginFormStatus.error &&
                    hasAuthFeedback(
                      message: state.message,
                      code: state.code,
                      uiKey: state.uiKey,
                    )) {
                  final resolvedMessage = AuthUiErrorResolver.resolve(
                    l10n: l10n,
                    code: state.code,
                    uiKey: state.uiKey,
                    message: state.message,
                    remaining: state.remaining,
                  );
                  final shouldShowSnackBar =
                      _isShowingRegister || !_shouldShowInlineLoginError;

                  if (shouldShowSnackBar) {
                    _showErrorSnackBar(context, resolvedMessage);
                  }
                }

                if (state.status == LoginFormStatus.success &&
                    state.user != null) {
                  context.read<AuthSessionCubit>().setAuthenticated(
                    state.user!,
                    showCustomerOnboarding: true,
                  );
                }
              },
            ),
            BlocListener<RegisterFormCubit, RegisterFormState>(
              listener: (context, state) {
                if (state.status == RegisterFormStatus.success &&
                    state.userId != null) {
                  registerCardKey.currentState?.cleanRegistry();
                  context.read<RegisterFormCubit>().reset();

                  setState(() {
                    _showLoginError = false;
                    _isShowingRegister = false;
                    _dismissEmailConfirmedMessage = true;
                    _showRegisterSuccessMessage = true;
                  });
                }
              },
            ),
          ],
          child: Builder(
            builder: (context) {
              final loginState = context.watch<LoginFormCubit>().state;
              final registerState = context.watch<RegisterFormCubit>().state;

              final bool isLoginLoading =
                  loginState.status == LoginFormStatus.submitting;
              final bool isRegisterLoading =
                  registerState.status == RegisterFormStatus.submitting;

              final String? errorMessage =
                  loginState.status == LoginFormStatus.error &&
                      hasAuthFeedback(
                        message: loginState.message,
                        code: loginState.code,
                        uiKey: loginState.uiKey,
                      ) &&
                      _showLoginError &&
                      _shouldShowInlineLoginError
                  ? AuthUiErrorResolver.resolve(
                      l10n: l10n,
                      code: loginState.code,
                      uiKey: loginState.uiKey,
                      message: loginState.message,
                      remaining: loginState.remaining,
                    )
                  : null;
              final showEmailConfirmedMessage =
                  !_dismissEmailConfirmedMessage &&
                  !_isShowingRegister &&
                  errorMessage == null &&
                  GoRouterState.of(
                        context,
                      ).uri.queryParameters['emailConfirmed'] ==
                      'true';
              final successMessage = showEmailConfirmedMessage
                  ? l10n.authEmailConfirmedLoginMessage
                  : _showRegisterSuccessMessage
                  ? l10n.authRegisterSuccess
                  : null;

              final String? registerErrorMessage =
                  registerState.status == RegisterFormStatus.error &&
                      hasAuthFeedback(
                        message: registerState.message,
                        code: registerState.code,
                        uiKey: registerState.uiKey,
                      )
                  ? AuthUiErrorResolver.resolve(
                      l10n: l10n,
                      code: registerState.code,
                      uiKey: registerState.uiKey,
                      message: registerState.message,
                      remaining: registerState.remaining,
                    )
                  : null;
              final bool isRegisterEmailError = _isRegisterEmailError(
                registerState,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = MediaQuery.of(context).size.height;

                  final bool isTabletWeb = w >= 700;
                  final bool isWideWeb = w >= 1100;

                  final double cardWidth = isWideWeb
                      ? 560
                      : isTabletWeb
                      ? 520
                      : (w * 0.88).clamp(300.0, 420.0);

                  final double cardHeight = h;
                  final double logoSize = isTabletWeb ? 220 : 190;

                  return Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      reverseDuration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _buildAuthSwitchTransition,
                      child: _isShowingRegister
                          ? KeyedSubtree(
                              key: const ValueKey('register'),
                              child: RegisterCard(
                                key: registerCardKey,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                logoSize: logoSize,
                                isLoading: isRegisterLoading,
                                emailErrorMessage: isRegisterEmailError
                                    ? registerErrorMessage
                                    : null,
                                formErrorMessage: isRegisterEmailError
                                    ? null
                                    : registerErrorMessage,
                                onBackToLogin: () =>
                                    _goToLoginFromRegister(context),
                                onRegisterRequested:
                                    ({
                                      required String name,
                                      required String email,
                                      required String phone,
                                      required String password,
                                    }) {
                                      setState(() {
                                        _showLoginError = false;
                                        _isShowingRegister = true;
                                        _showRegisterSuccessMessage = false;
                                      });

                                      context.read<RegisterFormCubit>().submit(
                                        name: name,
                                        email: email,
                                        phone: phone,
                                        password: password,
                                      );
                                    },
                              ),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('login'),
                              child: _buildLogin(
                                context,
                                cardWidth,
                                cardHeight,
                                logoSize,
                                isLoginLoading,
                                errorMessage,
                                successMessage,
                                l10n,
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthSwitchTransition(Widget child, Animation<double> animation) {
    final isRegister = child.key == const ValueKey('register');
    final offsetAnimation = Tween<Offset>(
      begin: Offset(isRegister ? -0.08 : 0.08, 0),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offsetAnimation, child: child),
    );
  }

  Widget _buildLogin(
    BuildContext context,
    double cardWidth,
    double cardHeight,
    double logoSize,
    bool isLoading,
    String? errorMessage,
    String? successMessage,
    AppLocalizations l10n,
  ) {
    final isCompactHeight = cardHeight < 720;
    final topPadding = (cardHeight * (isCompactHeight ? 0.18 : 0.30)).clamp(
      56.0,
      220.0,
    );
    final titleSize = isCompactHeight ? 24.0 : 28.0;
    final subtitleSize = isCompactHeight ? 15.0 : 17.0;
    final buttonHeight = isCompactHeight ? 50.0 : 54.0;
    final sectionGap = isCompactHeight ? 20.0 : 34.0;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AuthCardShell(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      logoSize: logoSize,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            0,
            topPadding.toDouble(),
            0,
            AutolabCustomer.spacingLg + keyboardInset,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKeyLogin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.authLoginTitle,
                  style: AutolabCustomer.h1.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 6 : 8),
                Text(
                  'Añade tus datos para iniciar sesión.',
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                    fontSize: subtitleSize,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 16 : 22),
                if (errorMessage != null) ...[
                  AuthErrorBanner(message: errorMessage),
                  const SizedBox(height: 18),
                ] else if (successMessage != null) ...[
                  AuthErrorBanner(
                    message: successMessage,
                    variant: AuthBannerVariant.success,
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  controller: _emailLoginCtrl,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    label: l10n.authLoginEmailLabel,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) => Validators.email(value, l10n),
                ),
                SizedBox(height: isCompactHeight ? 12 : 16),
                TextFormField(
                  controller: _passLoginCtrl,
                  obscureText: _isPasswordHidden,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    label: l10n.authLoginPasswordLabel,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AutolabCustomer.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                  ),
                  validator: (value) => Validators.password(value, l10n),
                ),
                SizedBox(height: sectionGap),
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _login(context),
                    style: AutolabCustomer.primaryButton.copyWith(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AutolabCustomer.radiusButton + 2,
                          ),
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
                            l10n.authLoginSubmit,
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
                    onPressed: () {
                      context.go('/forgot-password');
                    },
                    child: Text(
                      '¿Olvidó su contraseña?',
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.authTextColor(context),
                        fontSize: subtitleSize,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: TextButton(
                    onPressed: () => _goToRegister(context),
                    child: Text(
                      l10n.authLoginRegisterAction,
                      style: AutolabCustomer.bodyLarge.copyWith(
                        color: AutolabCustomer.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isRegisterEmailError(RegisterFormState state) {
    final uiKey = state.uiKey;
    final code = state.code;
    return uiKey == AuthErrorCatalog.emailAlreadyRegistered.uiKey ||
        uiKey == AuthErrorCatalog.accountAlreadyExists.uiKey ||
        uiKey == AuthErrorCatalog.emailNotConfirmedRegister.uiKey ||
        code == AuthErrorCatalog.emailAlreadyRegistered.code ||
        code == AuthErrorCatalog.accountAlreadyExists.code ||
        code == AuthErrorCatalog.emailNotConfirmedRegister.code;
  }
}
