import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user = MockDatabase.authenticate(email, password);

    if (user != null) {
      // Login exitoso
      context.go('/home', extra: user);
    } else {
      // Login fallido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas. (Pista: m@m.com / 123)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO
                  SvgPicture.asset('assets/images/logo.svg', height: 100),
                  const SizedBox(height: 16),

                  // Textos de título
                  Text('BG Companion', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Tu Asistente de partidas Epicas!',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  // Campo de Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EMAIL', style: textTheme.labelSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'ej: mago@test.com',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Campo de Contraseña
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTRASEÑA', style: textTheme.labelSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: '............',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botón de Ingresar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _login,
                      child: const Text('INGRESAR'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Olvidaste contraseña
                  TextButton(
                    onPressed: () {},
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                  const SizedBox(height: 24),

                  // Botón Crear Cuenta
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: const Text('CREAR CUENTA'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
