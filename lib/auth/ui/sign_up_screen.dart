import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _signup() async {
    setState(() => loading = true);
    final auth = ref.read(authServiceProvider);
    try {
      final res = await auth.signUp(
        emailCtrl.text.trim(),
        passCtrl.text,
        data: {'name': "Kima", 'org': "apple"},
      );
      // res contains user/session info. If email confirmation required, session may be null.
      _showMessage('Check your email for confirmation if required.');
    } catch (e) {
      _showMessage('Signup failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String m) => showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      content: Text(m),
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Create account'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: emailCtrl,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: passCtrl,
                placeholder: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: loading ? null : _signup,
                child: loading
                    ? const CupertinoActivityIndicator()
                    : const Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
