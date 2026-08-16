import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/pages/login_page.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:rapa_track_mobile_app/app/ui_items/confirm_dialog.dart';
import 'package:rapa_track_mobile_app/app/utils/navigation_handler.dart';

class ProfilePage extends StatelessWidget {
  final Profile user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.lg),
          _buildInfoCard(),
          const SizedBox(height: AppSizes.xl),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: AppSizes.avatarXl + AppSizes.xl,
          height: AppSizes.avatarXl + AppSizes.xl,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: AppSizes.fontXxl,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: AppSizes.fontLg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.xxs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
          ),
          child: Text(
            user.isAdmin ? 'Administrator' : (user.role?.label ?? 'Karyawan'),
            style: const TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.badge_outlined,
            label: 'ID Karyawan',
            value: user.employeeId ?? '-',
          ),
          const Divider(height: 1, indent: AppSizes.lg + AppSizes.xl),
          _buildInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email ?? '-',
          ),
          const Divider(height: 1, indent: AppSizes.lg + AppSizes.xl),
          _buildInfoTile(
            icon: Icons.apartment_outlined,
            label: 'Divisi',
            value: user.divisionLabel,
          ),
          const Divider(height: 1, indent: AppSizes.lg + AppSizes.xl),
          _buildInfoTile(
            icon: user.isActive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            label: 'Status',
            value: user.isActive ? 'Aktif' : 'Nonaktif',
            valueColor: user.isActive ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Keluar'),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: 'Keluar',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmLabel: 'Keluar',
    );
    if (confirmed == true) {
      await AuthenticationState().logout();
      NavigationHandler.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
