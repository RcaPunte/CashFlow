import 'package:cashledger/auth/controller/auth_controller.dart';
import 'package:cashledger/auth/controller/widget/logout_button.dart';
import 'package:cashledger/user_profile/controller/user_profile_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  bool saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final user = ref.read(currentUserProvider)!;

      await ref.read(authServiceProvider).updateProfile({
        'id': user.id,
        'full_name': _nameCtrl.text.trim(),
        'phone_no': _phoneCtrl.text.trim(),
        'role': _roleCtrl.text.trim(),
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Profile updated successfully'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to update profile'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('My Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.square_arrow_right,
            color: CupertinoColors.systemRed,
          ),
          onPressed: () => showLogoutDialog(context, ref),
        ),
      ),
      child: profileAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile != null) {
            _nameCtrl.text = profile.fullName ?? '';
            _phoneCtrl.text = profile.phone ?? '';
            _roleCtrl.text = profile.role ?? '';
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _nameCtrl,
                    placeholder: 'Full Name',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextFormFieldRow(
                    controller: _phoneCtrl,
                    placeholder: 'Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextFormFieldRow(
                    controller: _roleCtrl,
                    placeholder: 'Role (Admin/User)',
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: saving ? null : _saveProfile,
                    child: saving
                        ? const CupertinoActivityIndicator()
                        : const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
