import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/auth/controller/auth_provider.dart';
import 'package:cashledger/auth/ui/sign_up_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// class LoginPage extends ConsumerWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final auth = ref.read(authProvider.notifier);

//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           child: const Text("Sign in with Google"),
//           onPressed: () async {
//             await auth.signInWithGoogle();
//           },
//         ),
//       ),
//     );
//   }
// }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      final res = await auth.signInWithPassword(
        emailCtrl.text.trim(),
        passCtrl.text,
      );
      if (res.session == null) {
        // check for email confirmation required
        _showMessage('Check your email for confirmation link if required.');
      }
      // Supabase will trigger auth stream; AuthGate will pick it up
    } catch (e) {
      _showMessage('Login failed: ${_errorMessage(e)}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _errorMessage(Object e) {
    return e.toString();
  }

  void _showMessage(String text) => showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      content: Text(text),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Sign in')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: emailCtrl,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: passCtrl,
                placeholder: 'Password',
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CupertinoActivityIndicator()
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('Create account'),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                child: const Text('Forgot password?'),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text('Reset password'),
                      content: Column(
                        children: [
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            placeholder: 'Email',
                            controller: emailCtrl,
                          ),
                        ],
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          child: const Text('Send'),
                          onPressed: () async {
                            final auth = ref.read(authServiceProvider);
                            try {
                              await auth.resetPassword(emailCtrl.text.trim());
                              Navigator.pop(context);
                              _showMessage('Password reset email sent.');
                            } catch (e) {
                              Navigator.pop(context);
                              _showMessage('Error: ${e.toString()}');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoButton(
      child: const Text('Sign out'),
      onPressed: () async {
        final auth = ref.read(authServiceProvider);
        await auth.signOut();
        // Supabase auth state stream will update UI
      },
    );
  }
}
