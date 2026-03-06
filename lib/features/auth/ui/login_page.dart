import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          // Si tienes go_router con redirect por auth, NO navegues manual aquí.
        },
        builder: (context, state) {
          final showOverlay = state is AuthLoading;

          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40.0,
                            vertical: MediaQuery.of(context).size.height < 600 ? 24.0 : 40.0,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildHeader(context),
                                SizedBox(height: MediaQuery.of(context).size.height < 600 ? 24 : 40),
                                _buildLoginForm(state),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showOverlay)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Iniciando sesión...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.lock, size: 72),
        const SizedBox(height: 12),
        Text('Autolab', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Ingresa con tu correo y contraseña',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo',
            hintText: 'admin01@autolab.com',
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, ingrese el correo';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: '********',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, ingrese su contraseña';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state is AuthLoading ? null : _handleLogin,
            child: Text(state is AuthLoading ? 'Cargando...' : 'Iniciar sesión'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _openWhatsAppSupport,
          child: const Text('¿Problemas para iniciar sesión?'),
        ),
      ],
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  Future<void> _openWhatsAppSupport() async {
    const phone = '50689147371';
    const message = 'Hola, necesito ayuda para iniciar sesión en Autolab.';
    final text = Uri.encodeComponent(message);

    final uriApp = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final uriWeb = Uri.parse('https://wa.me/$phone?text=$text');

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  }
}