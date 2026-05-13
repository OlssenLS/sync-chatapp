import 'package:flutter/material.dart';
import 'dart:math';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _shakeController.reset();
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (result.containsKey('token')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
          );
          // TODO: Navigate to Home
        }
      } else {
        _shake();
        if (mounted) _showError(result['error'] ?? "Login Failed");
      }
    } catch (e) {
      _shake();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * sin(_shakeAnimation.value * pi * 5), 0),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_alt, size: 80, color: Color(0xFF24A1DE)),
                    const SizedBox(height: 20),
                    const Text(
                      "SYNC",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                    const SizedBox(height: 50),
                    TextFormField(
                      controller: _identifierController,
                      validator: (value) => value!.isEmpty ? 'Username or Email is required' : null,
                      decoration: _inputDecoration("Username or Email", Icons.person_outline),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) => value!.isEmpty ? 'Password is required' : null,
                      decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24A1DE),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF24A1DE), fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF24A1DE)),
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}
