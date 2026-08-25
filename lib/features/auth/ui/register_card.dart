import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/autolab_customer.dart';
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
  static final _termsUri = Uri.parse(
    'https://www.autolab.lat/terminos-y-condiciones/',
  );

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

  Future<void> _openTermsAndConditions() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      _termsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsOpenLinkError)),
      );
    }
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
    final isCompactHeight = widget.cardHeight < 760;
    final topPadding = (widget.cardHeight * (isCompactHeight ? 0.025 : 0.07))
        .clamp(16.0, 96.0);
    final fieldGap = isCompactHeight ? 10.0 : 14.0;
    final titleSize = isCompactHeight ? 24.0 : 28.0;
    final subtitleSize = isCompactHeight ? 15.0 : 17.0;
    final buttonHeight = isCompactHeight ? 50.0 : 54.0;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AuthCardShell(
      cardWidth: widget.cardWidth,
      cardHeight: widget.cardHeight,
      logoSize: widget.logoSize,
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
            key: _formKeyRegister,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.authRegisterTitle,
                  style: AutolabCustomer.h1.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 6 : 8),
                Text(
                  l10n.authRegisterSubtitle,
                  style: AutolabCustomer.bodyLarge.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                    fontSize: subtitleSize,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 14 : 20),
                TextFormField(
                  controller: _nameCtrl,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    hint: l10n.appointmentCustomerNameLabel,
                  ),
                  validator: (value) => Validators.name(value, l10n),
                ),
                SizedBox(height: fieldGap),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  onChanged: (_) {
                    if (_localErrorMessage != null ||
                        widget.emailErrorMessage != null) {
                      setState(() {
                        _localErrorMessage = null;
                        _hideRemoteEmailError = true;
                      });
                    }
                  },
                  decoration: buildAuthInputDecoration(
                    context: context,
                    hint: l10n.authRegisterEmailHint,
                  ).copyWith(errorText: emailErrorMessage, errorMaxLines: 2),
                  validator: (value) => Validators.email(value, l10n),
                ),
                SizedBox(height: fieldGap),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    hint: l10n.authRegisterPhoneHint,
                  ),
                  validator: (value) => Validators.phone(value, l10n),
                ),
                SizedBox(height: fieldGap),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _isPasswordVisible,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    hint: l10n.authRegisterPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AutolabCustomer.primary,
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
                SizedBox(height: fieldGap),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _isConfrimPasswordVisible,
                  cursorColor: AutolabCustomer.primary,
                  style: AutolabCustomer.body.copyWith(
                    color: AutolabCustomer.authTextColor(context),
                  ),
                  decoration: buildAuthInputDecoration(
                    context: context,
                    hint: l10n.authRegisterConfirmPasswordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfrimPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AutolabCustomer.primary,
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
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _acceptsTerms,
                      activeColor: AutolabCustomer.primary,
                      checkColor: AutolabCustomer.white,
                      side: BorderSide(
                        color: AutolabCustomer.authOutlineColor(context),
                      ),
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
                          Text(
                            l10n.authRegisterAcceptTermsPrefix,
                            style: AutolabCustomer.caption.copyWith(
                              color: AutolabCustomer.authTextColor(context),
                            ),
                          ),
                          GestureDetector(
                            onTap: _openTermsAndConditions,
                            child: Text(
                              l10n.authRegisterAcceptTermsLink,
                              style: AutolabCustomer.caption.copyWith(
                                color: AutolabCustomer.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AutolabCustomer.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (feedbackMessage != null) ...[
                  AuthErrorBanner(message: feedbackMessage),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _register,
                    style: AutolabCustomer.primaryButton.copyWith(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AutolabCustomer.radiusButton + 2,
                          ),
                        ),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AutolabCustomer.white,
                            ),
                          )
                        : Text(
                            l10n.authRegisterSubmit,
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
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${l10n.authRegisterHaveAccount} ',
                        style: AutolabCustomer.bodyLarge.copyWith(
                          color: AutolabCustomer.authTextColor(context),
                          fontSize: isCompactHeight ? 14 : 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onBackToLogin,
                        child: Text(
                          l10n.authRegisterLoginAction,
                          style: AutolabCustomer.bodyLarge.copyWith(
                            color: AutolabCustomer.primary,
                            fontSize: isCompactHeight ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
