import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  void _showErrorSnackBar(String message) {
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

  void _login() {
    final ok = _formKeyLogin.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _showLoginError = true;
      _isShowingRegister = false;
    });

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailLoginCtrl.text.trim(),
        password: _passLoginCtrl.text,
      ),
    );
  }

  void _goToRegister() {
    context.read<AuthBloc>().add(const ClearAuthState());

    setState(() {
      _showLoginError = false;
      _isShowingRegister = true;
    });

    cardKey.currentState?.toggleCard();
  }

  void _goToLoginFromRegister() {
    context.read<AuthBloc>().add(const ClearAuthState());

    registerCardKey.currentState?.cleanRegistry();

    setState(() {
      _showLoginError = false;
      _isShowingRegister = false;
    });

    cardKey.currentState?.toggleCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            final bool shouldRenderInlineError = _shouldShowInlineLoginError;

            final bool shouldShowSnackBar =
                _isShowingRegister || !shouldRenderInlineError;

            if (shouldShowSnackBar) {
              _showErrorSnackBar(state.message);
            }
          }

          if (state is AuthRegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registro exitoso. Revisa tu correo para confirmar tu cuenta',
                ),
                backgroundColor: Colors.green,
              ),
            );

            registerCardKey.currentState?.cleanRegistry();
            context.read<AuthBloc>().add(const ClearAuthState());

            setState(() {
              _showLoginError = false;
              _isShowingRegister = false;
            });

            cardKey.currentState?.toggleCard();
          }
        },
        builder: (context, state) {
          final bool isLoading = state is AuthLoading;

          final String? errorMessage =
              state is AuthError &&
                  _showLoginError &&
                  _shouldShowInlineLoginError
              ? state.message
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
                    cardWidth,
                    cardHeight,
                    logoSize,
                    isLoading,
                    errorMessage,
                  ),
                  back: RegisterCard(
                    key: registerCardKey,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    logoSize: logoSize,
                    isLoading: isLoading,
                    onBackToLogin: _goToLoginFromRegister,
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

                          context.read<AuthBloc>().add(
                            RegisterRequested(
                              name: name,
                              email: email,
                              phone: phone,
                              password: password,
                            ),
                          );
                        },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogin(
    double cardWidth,
    double cardHeight,
    double logoSize,
    bool isLoading,
    String? errorMessage,
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
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
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
                        label: 'Email',
                        hint: 'Ingrese su email',
                        icon: Icons.email_outlined,
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passLoginCtrl,
                      obscureText: _isPasswordHidden,
                      decoration: buildAuthInputDecoration(
                        label: 'Contraseña',
                        hint: 'Ingrese la contraseña',
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
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
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
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
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
                      child: const Text(
                        'Olvidó su contraseña',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'O iniciar sesión con:',
                      style: TextStyle(color: Colors.grey),
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
                            label: const Text(
                              'Google',
                              style: TextStyle(color: Colors.white),
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
                            label: const Text(
                              'Facebook',
                              style: TextStyle(color: Colors.white),
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
                          '¿No tienes cuenta?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: _goToRegister,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
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
