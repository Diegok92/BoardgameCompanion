import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../domain/models/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Lista de colores para elegir, basados en la imagen
  final List<Color> _availableColors = [
    const Color(0xFFE53935), // Rojo
    const Color(0xFFFB8C00), // Naranja
    const Color(0xFFFDD835), // Amarillo
    const Color(0xFF43A047), // Verde
    const Color(0xFF00BCD4), // Celeste
    const Color(0xFF1E88E5), // Azul
    const Color(0xFF8E24AA), // Violeta
    const Color(0xFFD81B60), // Rosa
    const Color(0xFF6D4C41), // Marrón
    const Color(0xFF607D8B), // Gris
  ];

  Color? _selectedColor;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    if (password != repeatPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    final newUser = User(
      id: Random().nextInt(10000).toString(), // ID aleatorio simple
      username: username,
      email: email,
      password: password,
      favoriteColor: _selectedColor,
      invitados: [],
    );

    try {
      await ref.read(authProvider.notifier).register(newUser);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
                  // Título y Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('BG Companion', style: textTheme.headlineSmall),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 32, // Logo más pequeño
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _buildTextField(
                    'EMAIL',
                    'nombre@ejemplo.com',
                    textTheme,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),

                  // Nombre de Usuario
                  _buildTextField(
                    'NOMBRE DE USUARIO',
                    'Ej: MagoSupremo',
                    textTheme,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 24),

                  // Selector de Color
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ELEGI EL COLOR QUE TE REPRESENTARA',
                      style: textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _availableColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Contraseña
                  _buildTextField(
                    'CONTRASEÑA',
                    '............',
                    textTheme,
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 16),

                  // Repetir Contraseña
                  _buildTextField(
                    'REPETIR CONTRASEÑA',
                    '............',
                    textTheme,
                    isPassword: true,
                    controller: _repeatPasswordController,
                  ),
                  const SizedBox(height: 32),

                  // Botón Registrarse
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _register,
                      child: const Text('REGISTRARSE'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Volver al Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text('Iniciar Sesión'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar simplificado gracias al AppTheme global
  Widget _buildTextField(
    String label,
    String hint,
    TextTheme textTheme, {
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
