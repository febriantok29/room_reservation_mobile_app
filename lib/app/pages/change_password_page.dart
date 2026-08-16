import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/pages/home_page.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authState = AuthenticationState();

      await authState.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      await authState.refreshUser();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: toggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.password_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    const Text(
                      'Ganti Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.fontXl,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      'Demi keamanan, Anda wajib mengganti password sebelum melanjutkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontSm,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    _passwordField(
                      controller: _currentPasswordController,
                      label: 'Password Saat Ini',
                      obscure: _obscureCurrent,
                      toggleObscure: () {
                        setState(() {
                          _obscureCurrent = !_obscureCurrent;
                        });
                      },
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Password saat ini wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    _passwordField(
                      controller: _newPasswordController,
                      label: 'Password Baru',
                      obscure: _obscureNew,
                      toggleObscure: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Password baru wajib diisi';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.md),

                    _passwordField(
                      controller: _confirmPasswordController,
                      label: 'Ulangi Password Baru',
                      obscure: _obscureConfirm,
                      toggleObscure: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ulangi password baru';
                        }
                        if (value.trim() != _newPasswordController.text.trim()) {
                          return 'Password tidak sama';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.lg),

                    if (_errorMessage.isNotEmpty) ...[
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: AppSizes.fontSm,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Simpan Password Baru'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
