import 'package:flutter/material.dart';
import 'package:rapa_track_mobile_app/app/pages/home_page.dart';
import 'package:rapa_track_mobile_app/app/states/authentication_state.dart';
import 'package:rapa_track_mobile_app/app/theme/app_colors.dart';
import 'package:rapa_track_mobile_app/app/theme/app_sizes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    _loadLastLoggedInUser();
    super.initState();
  }

  Future<void> _loadLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUser = prefs.getString(AuthenticationState.keySavedUsername);

    if (lastUser == null || lastUser.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _credentialController.text = lastUser;
    });
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    Icons.meeting_room_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  Text(
                    'Reservasi Ruangan',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xxxl),

                  ..._buildForms(),

                  if (_errorMessage.isNotEmpty) ...[
                    Text(
                      _errorMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildForms() {
    return [
      TextFormField(
        controller: _credentialController,
        decoration: const InputDecoration(
          labelText: 'No. Induk Pegawai / Email',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'No. Induk Pegawai / Email harus diisi';
          }

          return null;
        },
        enabled: !_isLoading,
      ),
      const SizedBox(height: AppSizes.lg),

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
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _login(),
        enabled: !_isLoading,
      ),
      const SizedBox(height: AppSizes.lg),
    ];
  }

  Widget _buildLoginButton() {
    Widget content = Text('Login');

    if (_isLoading) {
      content = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ElevatedButton.icon(
      icon: Icon(Icons.login_rounded),
      label: content,
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  Future<void> _login() async {
    final credential = _credentialController.text.trim();
    final password = _passwordController.text.trim();

    if (credential.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'No. Induk Pegawai / Email dan password harus diisi';
      });

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = AuthenticationState();

      final isLoggedIn = await authState.login(credential, password);

      if (isLoggedIn && mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error login: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
