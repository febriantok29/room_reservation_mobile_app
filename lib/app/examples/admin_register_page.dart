import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/models/request/user_register_request.dart';
import 'package:room_reservation_mobile_app/app/pages/home_page.dart';
import 'package:room_reservation_mobile_app/app/services/auth_service.dart';
import 'package:room_reservation_mobile_app/app/utils/mounted_state_mixin.dart';

/// Contoh halaman registrasi yang sederhana menggunakan FirestoreAuthService
class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});

  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage>
    with MountedStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _now = DateTime.now();

  final _dateFormat = DateFormat('d MMMM yyyy');

  // Controllers untuk form
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;

  // Auth service
  final _service = AuthService.getInstance();

  // UI state
  bool _isLoading = false;
  String _statusMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Pendaftaran Admin')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                ..._buildForms(),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForms() {
    final contents = <Widget>[
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Depan',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama depan harus diisi';
                }

                return null;
              },
            ),
          ),

          Expanded(
            child: TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Belakang',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
            ),
          ),
        ],
      ),

      TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Nomor Telepon',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final phoneRegex = RegExp(
              r'^(?:\+?[0-9][0-9\s-]{6,14}|0[0-9\s-]{6,14})$',
            );

            if (!phoneRegex.hasMatch(value)) {
              return 'Format nomor telepon tidak valid';
            }
          }

          return null;
        },
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
      ),

      // Address Input with 3 lines
      TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          labelText: 'Alamat',
          prefixIcon: Icon(Icons.home),
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
      ),

      GestureDetector(
        onTap: _isLoading ? null : _pickDateOfBirth,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Tanggal Lahir',
              prefixIcon: Icon(Icons.cake),
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: _dateOfBirth != null
                  ? _dateFormat.format(_dateOfBirth!)
                  : '',
            ),
            enabled: false,
          ),
        ),
      ),

      // Email field
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !_isLoading,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email harus diisi';
          }

          final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegExp.hasMatch(value)) {
            return 'Format email tidak valid';
          }

          return null;
        },
      ),

      // Password field
      TextFormField(
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password harus diisi';
          }

          if (value.length < 6) {
            return 'Password minimal 6 karakter';
          }

          return null;
        },
      ),

      // Confirm Password field
      TextFormField(
        controller: _confirmPasswordController,
        decoration: InputDecoration(
          labelText: 'Konfirmasi Password',
          prefixIcon: const Icon(Icons.lock_outline),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
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
        enabled: !_isLoading,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Konfirmasi password harus diisi';
          }

          if (value != _passwordController.text) {
            return 'Password dan konfirmasi password tidak cocok';
          }

          return null;
        },
      ),
    ];

    return contents
        .map(
          (widget) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: widget,
          ),
        )
        .toList();
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
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
    );
  }

  /// Register user
  Future<void> _register() async {
    // Validate form
    final name = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Check if passwords match
    if (password != confirmPassword) {
      setStateIfMounted(() {
        _statusMessage = 'Password dan konfirmasi password tidak cocok';
      });

      return;
    }

    setStateIfMounted(() {
      _isLoading = true;
      _statusMessage = 'Melakukan registrasi...';
    });

    try {
      // Buat UserRegisterRequest
      final request = UserRegisterRequest(
        email: email.isNotEmpty ? email.toLowerCase() : null,
        password: password,
        firstName: name,
        dateOfBirth: _dateOfBirth,
        lastName: lastName.isNotEmpty ? lastName : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        address: address.isNotEmpty ? address : null,
      );

      await _service.register(request);

      setStateIfMounted(() {
        _statusMessage = 'Registrasi berhasil!';
      });

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registrasi Berhasil'),
          content: const Text(
            'Akun Anda telah berhasil dibuat. Silakan login.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (canContinue && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
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

  Future<void> _pickDateOfBirth() async {
    final initialDate =
        _dateOfBirth ?? DateTime(_now.year - 12, _now.month, _now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: _now,
    );

    if (pickedDate != null) {
      setStateIfMounted(() {
        _dateOfBirth = pickedDate;
      });
    }
  }
}
