import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/register_response.dart';

class SuccessRegistrationDialog extends StatelessWidget {
  final RegisterResponse response;
  final VoidCallback? onContinue;

  const SuccessRegistrationDialog({
    super.key,
    required this.response,
    this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required RegisterResponse response,
    VoidCallback? onContinue,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessRegistrationDialog(
        response: response,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, minWidth: 280),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMessage(),
            const SizedBox(height: 16),
            if (response.hasUserData) ...[
              _buildUserDataSection(),
              const SizedBox(height: 16),
            ],
            _buildInfoMessage(),
            const SizedBox(height: 24),
            _buildContinueButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.celebration,
            color: Colors.green,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Bienvenido a SismosApp!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final userRole = response.role ?? 'inspector';
    final roleDisplayName = _getRoleDisplayName(userRole);

    return Text(
      'Su cuenta ha sido creada exitosamente como $roleDisplayName.',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserDataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('👤', 'Usuario', response.username ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow('📧', 'Email', response.email ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow('🏷️', 'Rol', _getRoleDisplayName(response.role ?? 'inspector')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    final userRole = response.role ?? 'inspector';
    final roleDisplayName = _getRoleDisplayName(userRole);
    final isAdmin = userRole.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAdmin ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.check_circle_outline,
            color: isAdmin ? Colors.red.shade700 : Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAdmin
                  ? 'Ya puede acceder al panel de administración'
                  : 'Ya puede comenzar a usar la aplicación como $roleDisplayName',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final userRole = response.role ?? 'inspector';
    final isAdmin = userRole.toLowerCase() == 'admin';

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          if (onContinue != null) {
            onContinue!();
          } else {
            _navigateBasedOnRole(context, userRole);
          }
        },
        icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.arrow_forward),
        label: Text(
          isAdmin ? 'Ir al Panel Admin' : 'Continuar',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAdmin ? Colors.red : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Helper methods
  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'ayudante':
        return 'Ayudante';
      default:
        return 'Inspector'; // Fallback
    }
  }

  void _navigateBasedOnRole(BuildContext context, String userRole) {
    debugPrint('🎯 SuccessDialog: Navegando según el rol: $userRole');

    if (userRole.toLowerCase() == 'admin') {
      debugPrint('🔧 Navegando a HomeAdminScreen...');
      Navigator.of(context).pushNamedAndRemoveUntil('/homeAdmin', (route) => false);
    } else {
      debugPrint('👥 Navegando a HomePage...');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}