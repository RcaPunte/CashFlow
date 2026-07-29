import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/auth/ui/sign_up_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "admin@rca.com");
  final _passwordController = TextEditingController(text: "password123");
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (!mounted) return;
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = "Unexpected error occurred");
    }

    setState(() => _loading = false);
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Login"),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  CupertinoTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: "Email",
                    padding: const EdgeInsets.all(14),
                  ),

                  const SizedBox(height: 16),

                  CupertinoTextField(
                    controller: _passwordController,
                    obscureText: true,
                    placeholder: "Password",
                    padding: const EdgeInsets.all(14),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  CupertinoButton.filled(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text("Login"),
                  ),

                  const SizedBox(height: 12),

                  CupertinoButton(
                    onPressed: _navigateToSignUp,
                    child: const Text("Create Account"),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}