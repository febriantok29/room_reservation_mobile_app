import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_login_example_page.dart';
import 'package:room_reservation_mobile_app/app/services/firestore_service/firestore_auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/mounted_state_mixin.dart';

/// Contoh halaman registrasi yang sederhana menggunakan FirestoreAuthService
class FirestoreRegisterExamplePage extends StatefulWidget {
  const FirestoreRegisterExamplePage({super.key});

  @override
  State<FirestoreRegisterExamplePage> createState() =>
      _FirestoreRegisterExamplePageState();
}

class _FirestoreRegisterExamplePageState
    extends State<FirestoreRegisterExamplePage>
    with MountedStateMixin {
  // Controllers untuk form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Auth service
  late final Future<FirestoreAuthService> _authService =
      FirestoreAuthService.getInstance();

  // UI state
  bool _isLoading = false;
  String _statusMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Center(
              child: Text(
                'Register',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error')
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusMessage),
              ),

            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Username field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.account_circle),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setStateIfMounted(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Confirm Password field
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setStateIfMounted(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _register(),
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Register button
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('REGISTER'),
            ),

            const SizedBox(height: 16),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FirestoreLoginExamplePage(),
                            ),
                          );
                        },
                  child: const Text('Login'),
                ),
              ],
            ),

            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Kembali ke menu utama'),
            ),
          ],
        ),
      ),
    );
  }

  /// Register user
  Future<void> _register() async {
    // Validate form
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Basic validation
    if (name.isEmpty ||
        email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setStateIfMounted(() {
        _statusMessage = 'Semua field harus diisi';
      });
      return;
    }

    // Check if passwords match
    if (password != confirmPassword) {
      setStateIfMounted(() {
        _statusMessage = 'Password dan konfirmasi password tidak cocok';
      });
      return;
    }

    // Email validation
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(email)) {
      setStateIfMounted(() {
        _statusMessage = 'Format email tidak valid';
      });
      return;
    }

    setStateIfMounted(() {
      _isLoading = true;
      _statusMessage = 'Melakukan registrasi...';
    });

    try {
      final authService = await _authService;

      await authService.register(
        name: name,
        email: email,
        username: username,
        password: password,
      );

      setStateIfMounted(() {
        _statusMessage = 'Registrasi berhasil!';
      });

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      // Navigate to login page after successful registration
      if (canContinue) {
        // Delay to show success message briefly
        Future.delayed(const Duration(seconds: 2), () {
          if (canContinue && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FirestoreLoginExamplePage(),
              ),
            );
          }
        });
      }
    } catch (e) {
      setStateIfMounted(() {
        _statusMessage = 'Error registrasi: ${e.toString()}';
      });
    } finally {
      setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }
}
