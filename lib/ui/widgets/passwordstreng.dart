import 'package:flutter/material.dart';

class PasswordStrengthWidget extends StatefulWidget {
  final String password;
  final double height;
  final double borderRadius;
  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final String? matchPassword; // Para comparar contraseñas
  final bool showStrengthIndicator; // Para mostrar/ocultar el indicador

  const PasswordStrengthWidget({
    super.key,
    required this.password,
    required this.controller,
    required this.labelText,
    this.height = 6.0,
    this.borderRadius = 3.0,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.prefixIcon = Icons.lock,
    this.matchPassword,
    this.showStrengthIndicator = false,
  });

  @override
  State<PasswordStrengthWidget> createState() => _PasswordStrengthWidgetState();
}

class _PasswordStrengthWidgetState extends State<PasswordStrengthWidget> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget _buildSuffixIcon() {
    List<Widget> icons = [];

    // Icono de fortaleza de contraseña (si está habilitado y hay texto)
    if (widget.showStrengthIndicator && widget.password.isNotEmpty) {
      final strength = _calculatePasswordStrength(widget.password);
      icons.add(
        Icon(
          strength.icon,
          color: strength.color,
          size: 20,
        ),
      );
    }

    // Icono de coincidencia de contraseñas (si se proporciona matchPassword)
    if (widget.matchPassword != null &&
        widget.password.isNotEmpty &&
        widget.password == widget.matchPassword) {
      icons.add(
        const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20
        ),
      );
    }

    // Espaciado entre iconos si hay más de uno
    if (icons.isNotEmpty) {
      icons.add(const SizedBox(width: 8));
    }

    // Botón de visibilidad (siempre presente)
    icons.add(
      IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: widget.enabled ? _toggleVisibility : null,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }

  Widget _buildStrengthIndicator() {
    if (!widget.showStrengthIndicator || widget.password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculatePasswordStrength(widget.password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  color: Colors.grey[300],
                ),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: widget.height,
                        margin: EdgeInsets.only(
                          right: index < 3 ? 4 : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          color: index < strength.level
                              ? strength.color
                              : Colors.transparent,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              strength.icon,
              color: strength.color,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          strength.text,
          style: TextStyle(
            fontSize: 12,
            color: strength.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: _buildSuffixIcon(),
          ),
          obscureText: _obscureText,
          enabled: widget.enabled,
          onChanged: (value) {
            setState(() {}); // Actualizar indicadores
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          validator: widget.validator,
        ),
        _buildStrengthIndicator(),
      ],
    );
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
        level: 0,
        text: '',
        color: Colors.grey,
        icon: Icons.info_outline,
      );
    }

    int score = 0;
    List<String> feedback = [];

    // Longitud mínima
    if (password.length >= 8) {
      score++;
    } else {
      feedback.add('Al menos 8 caracteres');
    }

    // Contiene letras mayúsculas
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    } else {
      feedback.add('Incluir mayúsculas');
    }

    // Contiene letras minúsculas
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    } else {
      feedback.add('Incluir minúsculas');
    }

    // Contiene números
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    } else {
      feedback.add('Incluir números');
    }

    // Contiene símbolos
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      score++;
    } else {
      feedback.add('Incluir símbolos (!@#\$&*~)');
    }

    return _getStrengthFromScore(score, feedback);
  }

  PasswordStrength _getStrengthFromScore(int score, List<String> feedback) {
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength(
          level: 1,
          text: 'Muy débil',
          color: Colors.red,
          icon: Icons.error,
        );
      case 2:
        return PasswordStrength(
          level: 2,
          text: 'Débil',
          color: Colors.orange,
          icon: Icons.warning,
        );
      case 3:
        return PasswordStrength(
          level: 3,
          text: 'Buena',
          color: Colors.yellow[700]!,
          icon: Icons.check_circle_outline,
        );
      case 4:
      case 5:
        return PasswordStrength(
          level: 4,
          text: 'Muy fuerte',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      default:
        return PasswordStrength(
          level: 0,
          text: '',
          color: Colors.grey,
          icon: Icons.info_outline,
        );
    }
  }
}

class PasswordStrength {
  final int level;
  final String text;
  final Color color;
  final IconData icon;

  PasswordStrength({
    required this.level,
    required this.text,
    required this.color,
    required this.icon,
  });
}

// Funciones auxiliares para usar en otros widgets (mantenemos compatibilidad)
class PasswordStrengthHelper {
  static IconData getPasswordStrengthIcon(String password) {
    final strength = _calculatePasswordStrength(password);
    return strength.icon;
  }

  static Color getPasswordStrengthColor(String password) {
    final strength = _calculatePasswordStrength(password);
    return strength.color;
  }

  static PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
        level: 0,
        text: '',
        color: Colors.grey,
        icon: Icons.info_outline,
      );
    }

    int score = 0;

    // Longitud mínima
    if (password.length >= 8) score++;

    // Contiene letras mayúsculas
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;

    // Contiene letras minúsculas
    if (RegExp(r'[a-z]').hasMatch(password)) score++;

    // Contiene números
    if (RegExp(r'[0-9]').hasMatch(password)) score++;

    // Contiene símbolos
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;

    switch (score) {
      case 0:
      case 1:
        return PasswordStrength(
          level: 1,
          text: 'Muy débil',
          color: Colors.red,
          icon: Icons.error,
        );
      case 2:
        return PasswordStrength(
          level: 2,
          text: 'Débil',
          color: Colors.orange,
          icon: Icons.warning,
        );
      case 3:
        return PasswordStrength(
          level: 3,
          text: 'Buena',
          color: Colors.yellow[700]!,
          icon: Icons.check_circle_outline,
        );
      case 4:
      case 5:
        return PasswordStrength(
          level: 4,
          text: 'Muy fuerte',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      default:
        return PasswordStrength(
          level: 0,
          text: '',
          color: Colors.grey,
          icon: Icons.info_outline,
        );
    }
  }
}