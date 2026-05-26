import 'package:flutter/material.dart';
import '../../../core/services/crypto_service.dart';

/// Opens the appropriate password dialog based on whether the doctor
/// has already generated their RSA key pair:
///
///   • First run  → [_SetupKeysDialog]:  set password + generate RSA-2048 keys
///   • Subsequent → [_VerifyPasswordDialog]: enter password to unlock signing
///
/// Returns the password string on success, or null if cancelled.
///
/// TODO(auth-team): Once login is implemented, the returned password string
/// can be replaced by passing the authenticated session credential directly
/// to CryptoService.signData(). The key storage and signing code is unchanged.
Future<String?> showPasswordGateDialog(BuildContext context) async {
  final hasKeys = await CryptoService.hasKeyPair();
  if (!context.mounted) return null;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => hasKeys ? const _VerifyPasswordDialog() : const _SetupKeysDialog(),
  );
}

// ─── First-Run: Key Setup Dialog ─────────────────────────────────────────────

class _SetupKeysDialog extends StatefulWidget {
  const _SetupKeysDialog();
  @override
  State<_SetupKeysDialog> createState() => _SetupKeysDialogState();
}

class _SetupKeysDialogState extends State<_SetupKeysDialog> {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePw = true, _hideConfirm = true;
  String? _error;
  bool _generating = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final pw = _pwCtrl.text;
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pw != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _generating = true; _error = null; });

    // Allow the loading UI to render before the CPU-intensive key generation
    await Future.delayed(Duration.zero);

    try {
      await CryptoService.generateAndStoreKeyPair(pw);
      if (mounted) Navigator.of(context).pop(pw);
    } catch (e) {
      if (mounted) setState(() { _error = 'Key generation failed: $e'; _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _DialogTitle(
        icon: Icons.key_rounded,
        label: 'Set Up Signing Credentials',
        theme: theme,
      ),
      content: SizedBox(
        width: 400,
        child: _generating ? _LoadingBody(theme: theme) : _SetupBody(
          pwCtrl: _pwCtrl,
          confirmCtrl: _confirmCtrl,
          hidePw: _hidePw,
          hideConfirm: _hideConfirm,
          error: _error,
          onTogglePw: () => setState(() => _hidePw = !_hidePw),
          onToggleConfirm: () => setState(() => _hideConfirm = !_hideConfirm),
        ),
      ),
      actions: _generating
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.generating_tokens_rounded, size: 18),
                label: const Text('Generate Keys'),
              ),
            ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 16),
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text('Generating RSA-2048 key pair…', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(
        'This one-time setup takes a few seconds.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.55)),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
    ],
  );
}

class _SetupBody extends StatelessWidget {
  const _SetupBody({
    required this.pwCtrl, required this.confirmCtrl,
    required this.hidePw, required this.hideConfirm,
    required this.error,
    required this.onTogglePw, required this.onToggleConfirm,
  });
  final TextEditingController pwCtrl, confirmCtrl;
  final bool hidePw, hideConfirm;
  final String? error;
  final VoidCallback onTogglePw, onToggleConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a password to protect your private signing key. You\'ll need it every time you sign a prescription.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.68)),
        ),
        const SizedBox(height: 10),
        _Chip(icon: Icons.lock_outline, label: 'RSA-2048 key pair generated locally', color: primary),
        _Chip(icon: Icons.security, label: 'Private key AES-256 encrypted at rest', color: primary),
        _Chip(icon: Icons.devices, label: 'Keys stored in secure device storage', color: primary),
        const SizedBox(height: 16),
        TextField(
          controller: pwCtrl,
          obscureText: hidePw,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.password_rounded),
            suffixIcon: IconButton(icon: Icon(hidePw ? Icons.visibility_off : Icons.visibility), onPressed: onTogglePw),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmCtrl,
          obscureText: hideConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.check_circle_outline_rounded),
            suffixIcon: IconButton(icon: Icon(hideConfirm ? Icons.visibility_off : Icons.visibility), onPressed: onToggleConfirm),
            errorText: error,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Subsequent Runs: Verify Password Dialog ──────────────────────────────────

class _VerifyPasswordDialog extends StatefulWidget {
  const _VerifyPasswordDialog();
  @override
  State<_VerifyPasswordDialog> createState() => _VerifyPasswordDialogState();
}

class _VerifyPasswordDialogState extends State<_VerifyPasswordDialog> {
  final _pwCtrl = TextEditingController();
  bool _hide = true, _verifying = false;
  String? _error;

  @override
  void dispose() { _pwCtrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    setState(() { _verifying = true; _error = null; });
    final ok = await CryptoService.validatePassword(_pwCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(_pwCtrl.text);
    } else {
      setState(() { _error = 'Incorrect password. Please try again.'; _verifying = false; _pwCtrl.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _DialogTitle(icon: Icons.verified_user_rounded, label: 'Sign Prescription', theme: theme),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your password to apply a cryptographic RSA-2048 signature to this prescription.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.68)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pwCtrl,
              obscureText: _hide,
              autofocus: true,
              onSubmitted: (_) => _verifying ? null : _verify(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide)),
                errorText: _error,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _verifying ? null : _verify,
          icon: _verifying
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.draw_rounded, size: 18),
          label: const Text('Sign'),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.icon, required this.label, required this.theme});
  final IconData icon;
  final String label;
  final ThemeData theme;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.75)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.85))),
      ],
    ),
  );
}
