import 'package:autolab_customer/features/auth/ui/terms_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterCard extends StatefulWidget {
  final double cardWidth;
  final double cardHeight;
  final double logoSize;
  final bool isLoading;
  final VoidCallback onBackToLogin;

  const RegisterCard({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.logoSize,
    required this.isLoading,
    required this.onBackToLogin,
  });

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final _formKeyRegister = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _isPasswordVisible = true;
  bool _isConfrimPasswordVisible = true;
  bool _acceptsTerms = false;

  InputDecoration _inputDec({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _register() {
    final ok = _formKeyRegister.currentState?.validate() ?? false;
    if (!ok) return;

    if (!_acceptsTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar términos y condiciones'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      ),
    );
  }

  void _cleanRegistry() {
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
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

          _cleanRegistry();
          context.read<AuthBloc>().add(const ClearAuthState());
          widget.onBackToLogin();
        }
      },
      builder: (context, state) {
        final bool isLoading = state is AuthLoading;

        return Material(
          elevation: 15,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: widget.cardWidth,
            height: widget.cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 140),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Form(
                            key: _formKeyRegister,
                            child: Column(
                              children: [
                                const Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: _inputDec(
                                    label: 'Nombre',
                                    hint: 'Ingrese su nombre',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    if (v.trim().length < 3) {
                                      return 'Mínimo 3 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDec(
                                    label: 'Email',
                                    hint: 'Ingrese su email',
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El email es obligatorio';
                                    }

                                    final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!emailRegex.hasMatch(v.trim())) {
                                      return 'Email inválido';
                                    }

                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDec(
                                    label: 'Teléfono',
                                    hint: 'Ingrese su teléfono',
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'El teléfono es obligatorio';
                                    }
                                    if (v.trim().length < 8) {
                                      return 'Teléfono inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _isPasswordVisible,
                                  decoration: _inputDec(
                                    label: 'Contraseña',
                                    hint: 'Ingrese la contraseña',
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
                                          _isPasswordVisible =
                                          !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'La contraseña es obligatoria';
                                    }
                                    if (v.length < 6) {
                                      return 'Mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _isConfrimPasswordVisible,
                                  decoration: _inputDec(
                                    label: 'Confirmar contraseña',
                                    hint: 'Repita la contraseña',
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
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirme la contraseña';
                                    }
                                    if (v != _passCtrl.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: _acceptsTerms,
                                      onChanged: (v) {
                                        setState(() {
                                          _acceptsTerms = v ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        children: [
                                          const Text('Acepto '),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                  const TermsPage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Términos y Condiciones',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                decoration:
                                                TextDecoration.underline,
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
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _register,
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
                                      'Registrarse',
                                      style: TextStyle(
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
                                    const Text('¿Ya tienes cuenta? '),
                                    TextButton(
                                      onPressed: () {
                                        _cleanRegistry();
                                        context
                                            .read<AuthBloc>()
                                            .add(const ClearAuthState());
                                        widget.onBackToLogin();
                                      },
                                      child: const Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          color: Colors.lightBlue,
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
                ),
                Positioned(
                  top: 0,
                  child: Image.asset(
                    'assets/images/virtual/Mesa de trabajo 10@2x.png',
                    width: widget.logoSize,
                    height: widget.logoSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}