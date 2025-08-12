import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/main.dart';
import 'package:eventmangment/firebase_options.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _codeController = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
              onSubmitted: (_) => _onVerifyPressed(),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _onVerifyPressed,
                child: _verifying
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onVerifyPressed() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    setState(() { _verifying = true; _error = null; });
    try {
      final fn = ModalRoute.of(context)!.settings.arguments as Future<void> Function(String);
      await fn(code);
      if (!mounted) return;
      Navigator.of(context).pop(true); // success
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _verifying = false; });
    }
  }
}

