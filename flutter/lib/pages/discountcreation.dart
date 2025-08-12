import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eventmangment/offlineredirect.dart';
import 'package:eventmangment/main.dart';

class CreateDiscountPage extends StatefulWidget {
  const CreateDiscountPage({super.key});

  @override
  State<CreateDiscountPage> createState() => _CreateDiscountPageState();
}

class _CreateDiscountPageState extends State<CreateDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _percentCtrl = TextEditingController(text: '10');
  final _eventIdCtrl = TextEditingController(); // leave empty for global
  DateTime? _startsAt;
  DateTime? _expiresAt;
  bool _active = true;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _percentCtrl.dispose();
    _eventIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Discount')),
      body: Stack(
        children: [
          const OfflineRedirector(
            homeRoute: AppRoutes.adminHome,
            reason: 'Create Discount requires internet. You were redirected.',
          ),
        AbsorbPointer(
          absorbing: _saving,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code (letters/numbers, no spaces)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      final val = (v ?? '').trim();
                      if (val.isEmpty) return 'Enter a code';
                      if (!RegExp(r'^[A-Za-z0-9_-]{3,24}$').hasMatch(val)) {
                        return '3–24 chars, letters/numbers/_-';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _percentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Percent (1–100)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 1 || n > 100) return 'Enter 1–100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _eventIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Event ID (leave empty for global)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: 'Starts (optional)',
                          value: _startsAt,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: _startsAt ?? DateTime.now(),
                            );
                            if (picked != null) setState(() => _startsAt = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateTile(
                          label: 'Expires (optional)',
                          value: _expiresAt,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                            );
                            if (picked != null) setState(() => _expiresAt = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Active'),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Discount'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final codeRaw = _codeCtrl.text.trim();
    final codeUpper = codeRaw.toUpperCase();
    final percent = int.parse(_percentCtrl.text.trim());
    final eventId = _eventIdCtrl.text.trim().isEmpty ? null : _eventIdCtrl.text.trim();
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    setState(() => _saving = true);
    try {
      final doc = FirebaseFirestore.instance.collection('discount_codes').doc();
      await doc.set({
        'codeUpper': codeUpper,
        'percent': percent,
        'eventId': eventId, // null => global
        'active': _active,
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        'startsAt': _startsAt != null ? Timestamp.fromDate(DateTime(_startsAt!.year, _startsAt!.month, _startsAt!.day)) : null,
        'expiresAt': _expiresAt != null ? Timestamp.fromDate(DateTime(_expiresAt!.year, _expiresAt!.month, _expiresAt!.day, 23, 59, 59)) : null,
        'notes': null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discount created')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.value, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '—' : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      title: Text(label),
      subtitle: Text(text),
      trailing: const Icon(Icons.date_range),
    );
  }
}
