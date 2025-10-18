import 'package:flutter/material.dart';
import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/services/firestore_service/firestore_auth_service.dart';

/// Contoh halaman profile yang sederhana menggunakan FirestoreAuthService
/// dengan memanfaatkan FutureBuilder untuk penanganan state loading dan error
class FirestoreProfileExamplePage extends StatefulWidget {
  const FirestoreProfileExamplePage({super.key});

  @override
  State<FirestoreProfileExamplePage> createState() =>
      _FirestoreProfileExamplePageState();
}

class _FirestoreProfileExamplePageState
    extends State<FirestoreProfileExamplePage> {
  // Auth service
  late final Future<FirestoreAuthService> _authServiceFuture =
      FirestoreAuthService.getInstance();

  // Profile future
  late Future<Profile?> _profileFuture;

  // Controllers untuk form
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  // UI state
  bool _isUpdating = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Load user profile
  Future<Profile?> _loadProfile() async {
    try {
      final authService = await _authServiceFuture;
      final profile = await authService.getCurrentUser(forceRefresh: true);

      if (profile != null) {
        // Set form data
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _emailController.text = profile.email ?? '';
        _usernameController.text = profile.username ?? '';
      }

      return profile;
    } catch (e) {
      // Melempar exception agar FutureBuilder dapat menangkap error
      throw Exception('Error memuat profil: ${e.toString()}');
    }
  }

  /// Update profile information
  Future<void> _updateProfile(Profile profile) async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();

    // Basic validation
    if (firstName.isEmpty || email.isEmpty || username.isEmpty) {
      setState(() {
        _statusMessage = 'Nama depan, email dan username harus diisi';
      });
      return;
    }

    // Email validation
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        _statusMessage = 'Format email tidak valid';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _statusMessage = 'Memperbarui profil...';
    });

    try {
      final authService = await _authServiceFuture;

      // Create updated profile
      final updatedProfile = Profile(
        id: profile.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        role: profile.role,
      );

      await authService.updateProfile(updatedProfile);

      // Reload profile to get fresh data
      setState(() {
        _profileFuture = _loadProfile();
        _statusMessage = 'Profil berhasil diperbarui';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error memperbarui profil: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Example')),
      body: FutureBuilder<Profile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          // Menampilkan loading indicator saat data sedang dimuat
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Menampilkan pesan error jika terjadi kesalahan
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _profileFuture = _loadProfile();
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Menampilkan pesan jika data kosong
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Pengguna tidak ditemukan atau belum login',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          // Mendapatkan data profile
          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Center(
                  child: Text(
                    'Edit Profil',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar placeholder
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      profile.firstName?.isNotEmpty == true
                          ? profile.firstName!.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

                if (_statusMessage.isNotEmpty) const SizedBox(height: 16),

                // First Name field
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Depan',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_isUpdating,
                ),

                const SizedBox(height: 16),

                // Last Name field
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Belakang',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_isUpdating,
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
                  enabled: !_isUpdating,
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
                  enabled: !_isUpdating,
                ),

                const SizedBox(height: 16),

                // ID (Read only)
                TextField(
                  controller: TextEditingController(text: profile.id ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    prefixIcon: Icon(Icons.perm_identity),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),

                const SizedBox(height: 16),

                // Role (Read only)
                TextField(
                  controller: TextEditingController(text: profile.role ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),

                const SizedBox(height: 24),

                // Update button
                ElevatedButton(
                  onPressed: _isUpdating ? null : () => _updateProfile(profile),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('PERBARUI PROFIL'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isUpdating ? null : () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
