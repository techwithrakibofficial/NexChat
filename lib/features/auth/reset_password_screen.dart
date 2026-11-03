import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_system/glass.dart';
import 'auth_validation.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _password.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _password.text));
      _password.clear(); _confirm.clear();
      if (mounted) widget.onComplete();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to update. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set a new password')),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: ListView(padding: const EdgeInsets.all(24), children: [GlassCard(child: Form(key: _form, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.key_rounded, size: 48, color: Palette.cyan), const SizedBox(height: 24),
          TextFormField(controller: _password, enabled: !_busy, obscureText: true, autocorrect: false,
            enableSuggestions: false, autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'New password'), validator: validateNewPassword),
          const SizedBox(height: 16),
          TextFormField(controller: _confirm, enabled: !_busy, obscureText: true, autocorrect: false,
            enableSuggestions: false, decoration: const InputDecoration(labelText: 'Confirm password'),
            validator: (v) => v != _password.text ? 'Passwords do not match' : null),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Update password')),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Semantics(liveRegion: true, child: Text(_error!))),
        ],
      )))]),
    ))),
  );
}
