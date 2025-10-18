import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/examples/firestore_home_page.dart';
import 'package:room_reservation_mobile_app/app/services/firestore_service/firestore_auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/mounted_state_mixin.dart';

/// Contoh halaman login yang sederhana menggunakan FirestoreAuthService
class FirestoreLoginExamplePage extends StatefulWidget {
  const FirestoreLoginExamplePage({super.key});

  @override
  State<FirestoreLoginExamplePage> createState() =>
      _FirestoreLoginExamplePageState();
}

class _FirestoreLoginExamplePageState extends State<FirestoreLoginExamplePage>
    with MountedStateMixin {
  // Controllers untuk form
  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();

  // Auth service
  late final Future<FirestoreAuthService> _authService =
      FirestoreAuthService.getInstance();

  // UI state
  bool _isLoading = false;
  String _statusMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Center(
              child: Text(
                'Login',
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

            // Email/Username field
            TextField(
              controller: _credentialController,
              decoration: const InputDecoration(
                labelText: 'Email atau Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              enabled: !_isLoading,
            ),

            const SizedBox(height: 24),

            // Login button
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
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
                  : const Text('LOGIN'),
            ),

            const SizedBox(height: 16),

            // Register link
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Kembali ke menu utama'),
            ),
          ],
        ),
      ),
    );
  }

  /// Login user
  Future<void> _login() async {
    // Validate form
    final credential = _credentialController.text.trim();
    final password = _passwordController.text.trim();

    if (credential.isEmpty || password.isEmpty) {
      setStateIfMounted(() {
        _statusMessage = 'Email/username dan password harus diisi';
      });
      return;
    }

    setStateIfMounted(() {
      _isLoading = true;
      _statusMessage = 'Melakukan login...';
    });

    try {
      final authService = await _authService;

      final user = await authService.login(
        credential: credential,
        password: password,
      );

      setStateIfMounted(() {
        _statusMessage =
            'Login berhasil sebagai ${user.firstName} ${user.lastName}';
      });

      // Clear form
      _credentialController.clear();
      _passwordController.clear();

      if (canContinue && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FirestoreHomePage()),
        );
      }
    } catch (e) {
      setStateIfMounted(() {
        _statusMessage = 'Error login: ${e.toString()}';
      });
    } finally {
      setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }
}
