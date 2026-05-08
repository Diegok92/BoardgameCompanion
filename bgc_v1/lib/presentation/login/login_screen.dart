import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                        decoration: const InputDecoration(
                          hintText: 'nombre@ejemplo.com',
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
                      onPressed: () {
                        // Acción de ingresar
                      },
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
