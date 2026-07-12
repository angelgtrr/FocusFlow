import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onSuccess;
  const LoginScreen({super.key, required this.appState, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _serverController;
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.appState.api.baseUrl);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final server = _serverController.text.trim();
    final password = _passwordController.text;
    if (server.isEmpty) {
      setState(() => _error = 'Server address is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.appState.setBaseUrl(server);
      await widget.appState.login(password);
      widget.onSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('FocusFlow', style: TextStyle(color: AppColors.violet400, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in',
                      style: TextStyle(color: AppColors.slate100, fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    const Text('SERVER ADDRESS', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _serverController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: AppColors.slate100),
                      decoration: const InputDecoration(hintText: 'https://your-ngrok-url.ngrok.app'),
                    ),
                    const SizedBox(height: 16),
                    const Text('PASSWORD', style: TextStyle(color: AppColors.slate500, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.slate100),
                      decoration: const InputDecoration(hintText: 'Password'),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.rose400, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? 'Checking...' : 'Log in'),
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
