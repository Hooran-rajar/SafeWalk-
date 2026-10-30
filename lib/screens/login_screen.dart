import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!widget.firebaseReady) {
      _message('Configure Firebase first. See README.md. Preview mode is available below.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().login(email: _email.text, password: _password.text);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Could not sign in. Check your details.');
    } catch (e) {
      _message('Sign in failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF7EF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Color(0xFF087F6E), size: 36),
                    ),
                    const SizedBox(height: 24),
                    const Text('Welcome to SafeWalk',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'A little more safety for every journey.',
                      style: TextStyle(
                          fontSize: 16, color: Colors.blueGrey.shade600),
                    ),
                    const SizedBox(height: 28),
                    if (!widget.firebaseReady)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2D7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Preview mode: connect your Firebase project to enable real accounts and database features.',
                        ),
                      ),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || !v.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Log in',
                      icon: Icons.login_rounded,
                      isLoading: _loading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 12),
                    if (widget.firebaseReady)
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            if (_email.text.trim().isEmpty) {
                              _message('Enter your email first.');
                              return;
                            }
                            try {
                              await AuthService().resetPassword(_email.text);
                              _message('Password reset email requested.');
                            } catch (e) {
                              _message('Could not send reset email: $e');
                            }
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignupScreen(firebaseReady: widget.firebaseReady),
                          ),
                        ),
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ),
                    if (!widget.firebaseReady) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(firebaseReady: false),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Preview app without Firebase'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
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
