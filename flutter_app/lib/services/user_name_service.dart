import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNameService {
  static const _key = 'visitor_name';

  /// 保存済み名前があればそれを返す。なければダイアログで聞く。
  /// キャンセル時は「無記名」を返すが保存しない（次回また聞く）。
  static Future<String> getOrAskName(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) return saved;

    if (!context.mounted) return '無記名';

    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _NameDialog(),
    );

    if (name != null && name.isNotEmpty) {
      await prefs.setString(_key, name);
      return name;
    }
    return '無記名';
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('はじめまして！'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '宜しければお名前を教えてください。\n苗字だけとか平仮名とかでもOK。\nby かわい',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'お名前',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
