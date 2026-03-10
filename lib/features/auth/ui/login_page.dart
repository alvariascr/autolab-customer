import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flip_card/flip_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/di/injection_container.dart';
import '../repository/auth_repository.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';


class LoginPage extends StatefulWidget {
  //static const String routeName = "/newlogin2screen";

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  // Login
  final _formKeyLogin = GlobalKey<FormState>();
  final TextEditingController _emailLoginCtrl = TextEditingController();
  final TextEditingController _passLoginCtrl = TextEditingController();
  bool _verPassLogin = true;

  // Registro
  final _formKeyRegistro = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  final AuthRepository repository = sl<AuthRepository>();
  bool _verPassReg = true;
  bool _verConfirContra = true;
  bool _aceptaTerminos = false;

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

  @override
  void dispose() {
    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();

    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final ok = _formKeyLogin.currentState?.validate() ?? false;
    if (!ok) return;

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailLoginCtrl.text.trim(),
        password: _passLoginCtrl.text,
      ),
    );
  }

  void _registrar() {
    final ok = _formKeyRegistro.currentState?.validate() ?? false;
    if (!ok) return;

    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar términos y condiciones"),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      RegisterRequested(
        //name: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        //phone: _telefonoCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      ),
    );
  }

  void _limpiarRegistro() {
    _formKeyRegistro.currentState?.reset();
    _nombreCtrl.clear();
    _emailCtrl.clear();
    _telefonoCtrl.clear();
    _passCtrl.clear();
    _confirmPassCtrl.clear();
    setState(() {
      _aceptaTerminos = false;
      _verPassReg = true;
      _verConfirContra = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }

          if (state is AuthSuccess) {
            //Aqui va donde se redirigue a la otra pantalla
            //Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          }
        },
        builder: (context, state) {
          final bool isLoading = state is AuthLoading;

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
                  front: _buildLogin(cardWidth, cardHeight, logoSize, isLoading),
                  back: _buildRegister(cardWidth, cardHeight, logoSize, isLoading),
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
      ) {
    return Material(
      elevation: 15,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        height: cardHeight,
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
                        key: _formKeyLogin,
                        child: Column(
                          children: [
                            const Text(
                              "Iniciar Sesión",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _emailLoginCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDec(
                                label: "Email",
                                hint: "Ingrese su email",
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "El correo es obligatorio";
                                }

                                final emailRegex =
                                RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return "Correo inválido";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _passLoginCtrl,
                              obscureText: _verPassLogin,
                              decoration: _inputDec(
                                label: "Contraseña",
                                hint: "Ingrese la contraseña",
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _verPassLogin
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _verPassLogin = !_verPassLogin;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "La contraseña es obligatoria";
                                }
                                if (value.length < 6) {
                                  return "Mínimo 6 caracteres";
                                }
                                return null;
                              },
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
                                  "Iniciar Sesión",
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
                                "Olvidó su contraseña",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "O iniciar sesión con:",
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
                                      "Google",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      elevation: 5,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                      "Facebook",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      elevation: 5,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                  "¿No tienes cuenta?",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                TextButton(
                                  onPressed: () {
                                    cardKey.currentState?.toggleCard();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Registrarse",
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
            ),

            Positioned(
              top: 0,
              child: Image.asset(
                "assets/images/virtual/Mesa de trabajo 10@2x.png",
                width: logoSize,
                height: logoSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegister(
      double cardWidth,
      double cardHeight,
      double logoSize,
      bool isLoading,
      ) {
    return Material(
      elevation: 15,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        height: cardHeight,
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
                        key: _formKeyRegistro,
                        child: Column(
                          children: [
                            const Text(
                              "Registrarse",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _nombreCtrl,
                              decoration: _inputDec(
                                label: "Nombre",
                                hint: "Ingrese su nombre",
                                icon: Icons.person_outline,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "El nombre es obligatorio";
                                }
                                if (v.trim().length < 3) {
                                  return "Mínimo 3 caracteres";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDec(
                                label: "Email",
                                hint: "Ingrese su email",
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "El email es obligatorio";
                                }

                                final emailRegex =
                                RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return "Email inválido";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _telefonoCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDec(
                                label: "Teléfono",
                                hint: "Ingrese su teléfono",
                                icon: Icons.phone_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "El teléfono es obligatorio";
                                }
                                if (v.trim().length < 8) {
                                  return "Teléfono inválido";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _verPassReg,
                              decoration: _inputDec(
                                label: "Contraseña",
                                hint: "Ingrese la contraseña",
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _verPassReg
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _verPassReg = !_verPassReg;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "La contraseña es obligatoria";
                                }
                                if (v.length < 6) {
                                  return "Mínimo 6 caracteres";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _confirmPassCtrl,
                              obscureText: _verConfirContra,
                              decoration: _inputDec(
                                label: "Confirmar contraseña",
                                hint: "Repita la contraseña",
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _verConfirContra
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _verConfirContra = !_verConfirContra;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Confirme la contraseña";
                                }
                                if (v != _passCtrl.text) {
                                  return "Las contraseñas no coinciden";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            CheckboxListTile(
                              value: _aceptaTerminos,
                              onChanged: (v) {
                                setState(() {
                                  _aceptaTerminos = v ?? false;
                                });
                              },
                              controlAffinity:
                              ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "Acepto términos y condiciones",
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _registrar,
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
                                  "Registrarse",
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
                                const Text("¿Ya tienes cuenta? "),
                                TextButton(
                                  onPressed: () {
                                    _limpiarRegistro();
                                    cardKey.currentState?.toggleCard();
                                  },
                                  child: const Text(
                                    "Iniciar sesión",
                                    style: TextStyle(color: Colors.lightBlue),
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
                "assets/images/virtual/Mesa de trabajo 10@2x.png",
                width: logoSize,
                height: logoSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}