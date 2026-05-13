import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (value.length < 3) return 'Username must be at least 3 characters';
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegExp.hasMatch(value)) return 'Use only letters, numbers, and underscores';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain both letters and numbers';
    }
    return null;
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.register(
        _emailController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result.containsKey('message')) {
        if (mounted) {
          _showSuccess(result['message']);
          Navigator.pop(context);
        }
      } else {
        if (mounted) _showError(result['error'] ?? "Registration Failed");
      }
    } catch (e) {
      if (mounted) _showError("Connection error. Is the server running?");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Join SYNC today", style: TextStyle(color: Colors.black54, fontSize: 16)),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _inputDecoration("Email", Icons.email_outlined),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    validator: _validateUsername,
                    decoration: _inputDecoration("Username", Icons.person_outline),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24A1DE),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF24A1DE)),
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      errorStyle: const TextStyle(color: Colors.redAccent),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}
