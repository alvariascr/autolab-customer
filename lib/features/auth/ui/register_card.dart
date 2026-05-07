import 'package:autolab_customer/features/auth/ui/terms_page.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/auth_card_shell.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_form_style.dart';

class RegisterCard extends StatefulWidget {
  final double cardWidth;
  final double cardHeight;
  final double logoSize;
  final bool isLoading;
  final String? emailErrorMessage;
  final String? formErrorMessage;
  final VoidCallback onBackToLogin;
  final Function({
    required String name,
    required String email,
    required String phone,
    required String password,
  })
  onRegisterRequested;

  const RegisterCard({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.logoSize,
    required this.isLoading,
    this.emailErrorMessage,
    this.formErrorMessage,
    required this.onBackToLogin,
    required this.onRegisterRequested,
  });

  @override
  RegisterCardState createState() => RegisterCardState();
}

class RegisterCardState extends State<RegisterCard> {
  final _formKeyRegister = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _isPasswordVisible = true;
  bool _isConfrimPasswordVisible = true;
  bool _acceptsTerms = false;
  String? _localErrorMessage;
  bool _hideRemoteEmailError = false;

  @override
  void didUpdateWidget(covariant RegisterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emailErrorMessage != widget.emailErrorMessage) {
      _hideRemoteEmailError = false;
    }
  }

  void _register() {
    setState(() {
      _localErrorMessage = null;
      _hideRemoteEmailError = false;
    });

    final ok = _formKeyRegister.currentState?.validate() ?? false;
    if (!ok) return;

    if (!_acceptsTerms) {
      setState(() {
        _localErrorMessage = AppLocalizations.of(context)!.authTermsRequired;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    widget.onRegisterRequested(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
  }

  void cleanRegistry() {
    _formKeyRegister.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _passCtrl.clear();
    _confirmPassCtrl.clear();

    setState(() {
      _acceptsTerms = false;
      _isPasswordVisible = true;
      _isConfrimPasswordVisible = true;
      _localErrorMessage = null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedbackMessage = _localErrorMessage ?? widget.formErrorMessage;
    final emailErrorMessage = _hideRemoteEmailError
        ? null
        : widget.emailErrorMessage;

    return AuthCardShell(
      cardWidth: widget.cardWidth,
      cardHeight: widget.cardHeight,
      logoSize: widget.logoSize,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKeyRegister,
                child: Column(
                  children: [
                    Text(
                      l10n.authRegisterTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authRegisterNameLabel,
                        hint: l10n.authRegisterNameHint,
                        icon: Icons.person_outline,
                      ),
                      validator: (value) => Validators.name(value, l10n),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_localErrorMessage != null ||
                            widget.emailErrorMessage != null) {
                          setState(() {
                            _localErrorMessage = null;
                            _hideRemoteEmailError = true;
                          });
                        }
                      },
                      decoration:
                          buildAuthInputDecoration(
                            label: l10n.authRegisterEmailLabel,
                            hint: l10n.authRegisterEmailHint,
                            icon: Icons.email_outlined,
                          ).copyWith(
                            errorText: emailErrorMessage,
                            errorMaxLines: 2,
                          ),
                      validator: (value) => Validators.email(value, l10n),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authRegisterPhoneLabel,
                        hint: l10n.authRegisterPhoneHint,
                        icon: Icons.phone_outlined,
                      ),
                      validator: (value) => Validators.phone(value, l10n),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _isPasswordVisible,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authRegisterPasswordLabel,
                        hint: l10n.authRegisterPasswordHint,
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) => Validators.password(value, l10n),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _isConfrimPasswordVisible,
                      decoration: buildAuthInputDecoration(
                        label: l10n.authRegisterConfirmPasswordLabel,
                        hint: l10n.authRegisterConfirmPasswordHint,
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfrimPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfrimPasswordVisible =
                                  !_isConfrimPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (v) =>
                          Validators.confirmPassword(v, _passCtrl.text, l10n),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _acceptsTerms,
                          onChanged: (v) {
                            setState(() {
                              _acceptsTerms = v ?? false;
                              if (_acceptsTerms) {
                                _localErrorMessage = null;
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(l10n.authRegisterAcceptTermsPrefix),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TermsPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.authRegisterAcceptTermsLink,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (feedbackMessage != null) ...[
                      AuthErrorBanner(message: feedbackMessage),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.authRegisterSubmit,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.authRegisterHaveAccount),
                        TextButton(
                          onPressed: widget.onBackToLogin,
                          child: Text(
                            l10n.authRegisterLoginAction,
                            style: const TextStyle(color: Colors.lightBlue),
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
