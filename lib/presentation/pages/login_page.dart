import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';

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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inicio de sesión correcto')),
          );
          // No navegamos manualmente aquí.
          // El redirect de go_router debe encargarse si ya lo conectaste al AuthBloc.
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Iniciar sesión'),
          ),
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 28.0,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Bienvenido',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo',
                                  hintText: 'admin01@autolab.com',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Ingrese el correo';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                onFieldSubmitted: (_) => _handleLogin(context),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Ingrese la contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isLoading ? null : () => _handleLogin(context),
                                child: const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text('Iniciar sesión'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: isLoading ? null : _showHelp,
                                child: const Text('¿Problemas para iniciar sesión?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogin(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacte al soporte.')),
    );
  }
}