import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_feedback.dart';
import '../application/auth_session_cubit.dart';
import '../application/login_form_cubit.dart';
import '../application/login_form_state.dart';
import '../application/register_form_cubit.dart';
import '../application/register_form_state.dart';
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
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<RegisterCardState> registerCardKey =
      GlobalKey<RegisterCardState>();

  final _formKeyLogin = GlobalKey<FormState>();
  final TextEditingController _emailLoginCtrl = TextEditingController();
  final TextEditingController _passLoginCtrl = TextEditingController();

  bool _isPasswordHidden = true;
  bool _showLoginError = false;
  bool _isShowingRegister = false;

  bool get _shouldShowInlineLoginError {
    return !_isShowingRegister && _showLoginError;
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    });

    cardKey.currentState?.toggleCard();
  }

  void _goToLoginFromRegister(BuildContext context) {
    context.read<RegisterFormCubit>().reset();
    registerCardKey.currentState?.cleanRegistry();

    setState(() {
      _showLoginError = false;
      _isShowingRegister = false;
    });

    cardKey.currentState?.toggleCard();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  );
                }
              },
            ),
            BlocListener<RegisterFormCubit, RegisterFormState>(
              listener: (context, state) {
                if (state.status == RegisterFormStatus.error &&
                    hasAuthFeedback(
                      message: state.message,
                      code: state.code,
                      uiKey: state.uiKey,
                    )) {
                  _showErrorSnackBar(
                    context,
                    AuthUiErrorResolver.resolve(
                      l10n: l10n,
                      code: state.code,
                      uiKey: state.uiKey,
                      message: state.message,
                      remaining: state.remaining,
                    ),
                  );
                }

                if (state.status == RegisterFormStatus.success &&
                    state.userId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.authRegisterSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );

                  registerCardKey.currentState?.cleanRegistry();
                  context.read<RegisterFormCubit>().reset();

                  setState(() {
                    _showLoginError = false;
                    _isShowingRegister = false;
                  });

                  cardKey.currentState?.toggleCard();
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
                      : w * 0.92;

                  final double cardHeight = (h * 0.92).clamp(520.0, 720.0);
                  final double logoSize = isTabletWeb ? 220 : 190;

                  return Center(
                    child: FlipCard(
                      key: cardKey,
                      flipOnTouch: false,
                      front: _buildLogin(
                        context,
                        cardWidth,
                        cardHeight,
                        logoSize,
                        isLoginLoading,
                        errorMessage,
                        l10n,
                      ),
                      back: RegisterCard(
                        key: registerCardKey,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        logoSize: logoSize,
                        isLoading: isRegisterLoading,
                        onBackToLogin: () => _goToLoginFromRegister(context),
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
                              });

                              context.read<RegisterFormCubit>().submit(
                                name: name,
                                email: email,
                                phone: phone,
                                password: password,
                              );
                            },
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

  Widget _buildLogin(
    BuildContext context,
    double cardWidth,
    double cardHeight,
    double logoSize,
    bool isLoading,
    String? errorMessage,
    AppLocalizations l10n,
  ) {
    return AuthCardShell(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      logoSize: logoSize,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKeyLogin,
                child: Column(
                  children: [
                    Text(
                      l10n.authLoginTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null) ...[
                      AuthErrorBanner(message: errorMessage),
                      const SizedBox(height: 15),
                    ],
                    TextFormField(
                      controller: _emailLoginCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authLoginEmailLabel,
                        hint: l10n.authLoginEmailHint,
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) => Validators.email(value, l10n),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passLoginCtrl,
                      obscureText: _isPasswordHidden,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authLoginPasswordLabel,
                        hint: l10n.authLoginPasswordHint,
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade700,
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _login(context),
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
                                l10n.authLoginSubmit,
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
                      onPressed: () {
                        // Luego aquí puedes conectar recover password
                      },
                      child: Text(
                        l10n.authLoginForgotPassword,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.authLoginSocialPrompt,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.white,
                            ),
                            label: Text(
                              l10n.authLoginGoogle,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const FaIcon(
                              FontAwesomeIcons.facebookF,
                              color: Colors.white,
                            ),
                            label: Text(
                              l10n.authLoginFacebook,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.authLoginNoAccount,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: () => _goToRegister(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.authLoginRegisterAction,
                            style: const TextStyle(
                              color: Colors.lightBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
