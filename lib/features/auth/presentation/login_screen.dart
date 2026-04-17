import 'package:flutter/material.dart';

import 'package:activity_tracker/features/auth/data/auth_api.dart';
import 'package:activity_tracker/features/auth/data/auth_storage.dart';
import 'package:activity_tracker/features/tracker/presentation/tracker_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthApi();
  final _storage = AuthStorage();

  String? _errorText;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final result = await _auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    switch (result) {
      case LoginSuccess(:final token):
        await _storage.saveToken(token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TrackerScreen()),
        );
      case LoginInvalidCredentials():
        setState(() {
          _loading = false;
          _errorText = 'Invalid credentials';
        });
      case LoginError():
        setState(() {
          _loading = false;
          _errorText = 'Something went wrong. Try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Activity Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),
                const Text('Email', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Password', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _password,
                  enabled: !_loading,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Sign in', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
