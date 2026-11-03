import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/supabase_config.dart';
import '../../core/design_system/glass.dart';
import 'auth_validation.dart';

/// Account operations stay separate from the offline sample conversations.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.onDemo});
  final VoidCallback onDemo;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  late final StreamSubscription<AuthState> _subscription;
  final _auth = Supabase.instance.client.auth;
  bool _signup = false;
  bool _busy = false;
  bool _obscure = true;
  String? _notice;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _subscription = _auth.onAuthStateChange.listen((_) {
      if (mounted) { setState(() {}); }
    }, onError: (Object _) {
      if (mounted) { _message('Session could not refresh. Check your connection.', error: true); }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    super.dispose();
  }

  void _message(String text, {bool error = false}) {
    setState(() { _notice = text; _error = error; });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _notice = null; });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) { _message(e.message, error: true); }
    } catch (_) {
      if (mounted) { _message('Unable to connect. Check your internet and try again.', error: true); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await _run(() async {
      if (_signup) {
        final result = await _auth.signUp(
          email: _email.text.trim(), password: _password.text,
          data: {'display_name': _name.text.trim()},
          emailRedirectTo: SupabaseConfig.callback,
        );
        if (!mounted) return;
        _password.clear(); _confirm.clear();
        if (result.session == null) {
          _message('Check your email to confirm your account, then sign in.');
        }
      } else {
        await _auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (!mounted) return;
        _password.clear(); _confirm.clear();
      }
    });
  }

  Future<void> _reset() async {
    final error = validateEmail(_email.text);
    if (error != null) { _message(error, error: true); return; }
    await _run(() async {
      await _auth.resetPasswordForEmail(_email.text.trim(), redirectTo: SupabaseConfig.callback);
      if (mounted) { _message('If this account exists, a password reset email will arrive. Open its link on this phone.'); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('NexChat Account')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          GlassCard(reduced: MediaQuery.disableAnimationsOf(context), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_person_outlined, size: 48, color: Palette.cyan),
              const SizedBox(height: 20),
              if (user != null) ...[
                Text(user.userMetadata?['display_name'] as String? ?? 'Your account', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8), Text(user.email ?? ''),
                const SizedBox(height: 12),
                Text(user.emailConfirmedAt != null ? 'Email verified' : 'Email confirmation pending'),
                const SizedBox(height: 16),
                const Text('Account connected. Conversations are still an offline demo and are shared on this device. Online messaging is not enabled yet.'),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: _busy ? null : () => _run(() async {
                  await _auth.signOut();
                  if (mounted) { _message('Signed out. Offline demo messages remain on this device.'); }
                }), child: const Text('Sign out')),
              ] else ...[
                Text(_signup ? 'Create your space' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Sign in securely with your email and password.'),
                const SizedBox(height: 24),
                Form(key: _form, child: AutofillGroup(child: Column(children: [
                  if (_signup) ...[
                    TextFormField(controller: _name, enabled: !_busy, textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.nickname], decoration: const InputDecoration(labelText: 'Display name'),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your display name' : null),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(controller: _email, enabled: !_busy, keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next, autocorrect: false,
                    autofillHints: const [AutofillHints.email], validator: validateEmail,
                    decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email))),
                  const SizedBox(height: 14),
                  TextFormField(controller: _password, enabled: !_busy, obscureText: _obscure,
                    autocorrect: false, enableSuggestions: false,
                    autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
                    validator: _signup ? validateNewPassword : (v) => (v?.isEmpty ?? true) ? 'Enter your password' : null,
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                  if (_signup) ...[
                    const SizedBox(height: 14),
                    TextFormField(controller: _confirm, enabled: !_busy, obscureText: true,
                      autocorrect: false, enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Confirm password'),
                      validator: (v) => v != _password.text ? 'Passwords do not match' : null),
                  ],
                ]))),
                const SizedBox(height: 20),
                FilledButton(onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
                  child: Text(_signup ? 'Create account' : 'Sign in')),
                TextButton(onPressed: _busy ? null : () {
                  setState(() { _signup = !_signup; _notice = null; _password.clear(); _confirm.clear(); });
                  _form.currentState?.reset();
                }, child: Text(_signup ? 'Already have an account? Sign in' : 'New here? Create an account')),
                if (!_signup) TextButton(onPressed: _busy ? null : _reset, child: const Text('Forgot password?')),
                if (_signup) TextButton(onPressed: _busy ? null : () {
                  final error = validateEmail(_email.text);
                  if (error != null) { _message(error, error: true); return; }
                  _run(() async {
                    await _auth.resend(type: OtpType.signup, email: _email.text.trim(), emailRedirectTo: SupabaseConfig.callback);
                    if (mounted) { _message('Confirmation requested. Check your inbox and spam folder.'); }
                  });
                }, child: const Text('Resend confirmation email')),
              ],
              if (_busy) const LinearProgressIndicator(semanticsLabel: 'Connecting to your account'),
              if (_notice != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Semantics(
                liveRegion: true, child: Text(_notice!, style: TextStyle(color: _error ? Theme.of(context).colorScheme.error : null)))),
              const Divider(height: 32),
              OutlinedButton(onPressed: _busy ? null : widget.onDemo, child: const Text('Explore offline demo')),
            ],
          )),
        ]),
      ))),
    );
  }
}
