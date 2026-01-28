import 'package:cashledger/account/model/account_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateAccountDialog extends ConsumerStatefulWidget {
  final int year;
  final AccountModel? parent;

  const CreateAccountDialog({super.key, required this.year, this.parent});

  @override
  ConsumerState<CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<CreateAccountDialog> {
  final controller = TextEditingController();
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.parent == null ? "New Account" : "New Sub Account"),
      content: Column(
        children: [
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: controller,
            placeholder: "Account name",
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: saving ? null : _save,
          child: saving
              ? const CupertinoActivityIndicator()
              : const Text("Save"),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (controller.text.isEmpty) return;

    setState(() => saving = true);

    try {
      await Supabase.instance.client.from('accounts').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'parent_account_id': widget.parent?.id,
        'id': const Uuid().v4(),

        'name': controller.text,
        'description': "",
        'account_type': 'custom',
        'limit_amount': 0,
        'year': widget.year,

        // 'parent_id': widget.parent?.id,
      });
    } catch (e) {
      debugPrint("Error creating account: $e");
    }

    setState(() => saving = false);
    Navigator.pop(context);
  }
}
