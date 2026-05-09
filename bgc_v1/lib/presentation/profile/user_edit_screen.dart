import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_model.dart';

class UserEditScreen extends StatefulWidget {
  final User user;

  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  // Lista de colores disponibles
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

  late Color? _selectedColor;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.user.favoriteColor;
    _emailController = TextEditingController(text: widget.user.email);
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController(text: widget.user.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Actualizamos el objeto User en memoria
    widget.user.email = _emailController.text.trim();
    widget.user.username = _usernameController.text.trim();
    widget.user.password = _passwordController.text.trim();
    widget.user.favoriteColor = _selectedColor;

    // Simula guardar en base de datos y vuelve a la Home
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG Companion',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset('assets/images/logo.svg', height: 24),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar (Simula cambio de foto)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _selectedColor ?? Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
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
                  _emailController,
                ),
                const SizedBox(height: 16),

                // Nombre de Usuario
                _buildTextField(
                  'NOMBRE DE USUARIO',
                  'Ej: MagoSupremo',
                  textTheme,
                  _usernameController,
                ),
                const SizedBox(height: 24),

                // Selector de Color
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CAMBIAR TU COLOR FAVORITO',
                    style: textTheme.labelSmall,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColor?.value == color.value;
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
                                color: color.withOpacity(0.5),
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
                  _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 32),

                // Botón Guardar Cambios
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _saveChanges,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Verde
                    ),
                    child: const Text('GUARDAR CAMBIOS'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextTheme textTheme,
    TextEditingController controller, {
    bool isPassword = false,
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
