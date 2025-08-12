import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscountListPage extends StatefulWidget {
  const DiscountListPage({super.key});

  @override
  State<DiscountListPage> createState() => _DiscountListPageState();
}

class _DiscountListPageState extends State<DiscountListPage> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _codesStream() {
    return FirebaseFirestore.instance
        .collection('discount_codes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<int> _fetchRedemptionCount(DocumentReference<Map<String, dynamic>> codeRef) async {
      final snap = await codeRef.collection('redemptions').get();
      return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discount Codes')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _codesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No discount codes yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final codeUpper = (data['codeUpper'] ?? '') as String;
              final percent = (data['percent'] ?? 0) as int;
              final eventId = data['eventId'] as String?;
              final active = (data['active'] ?? false) as bool;
              final startsAt = data['startsAt'] as Timestamp?;
              final expiresAt = data['expiresAt'] as Timestamp?;

              final now = Timestamp.now();
              final isUpcoming = startsAt != null && now.compareTo(startsAt) < 0;
              final isExpired  = expiresAt != null && now.compareTo(expiresAt) > 0;

              final status = _statusText(active, isUpcoming, isExpired);
              final statusColor = _statusColor(context, active, isUpcoming, isExpired);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    child: Text('$percent%'),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          codeUpper,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        eventId == null || eventId.isEmpty
                            ? 'Scope: Global'
                            : 'Scope: Event $eventId',
                      ),
                      const SizedBox(height: 4),
                      Text(_dateLine(startsAt, expiresAt)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'toggle') {
                        await d.reference.update({'active': !active});
                      } else if (val == 'deactivate') {
                        await d.reference.update({'active': false});
                      } else if (val == 'activate') {
                        await d.reference.update({'active': true});
                      } else if (val == 'delete') {
                        // Optional: confirm before delete
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete code?'),
                            content: const Text('This will remove the discount code. Redemptions remain for audit.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await d.reference.delete();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: active ? 'deactivate' : 'activate',
                        child: Text(active ? 'Deactivate' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _dateLine(Timestamp? startsAt, Timestamp? expiresAt) {
    String f(Timestamp ts) {
      final dt = ts.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }

    final parts = <String>[];
    if (startsAt != null) parts.add('Starts: ${f(startsAt)}');
    if (expiresAt != null) parts.add('Expires: ${f(expiresAt)}');
    return parts.isEmpty ? 'No start/expiry dates' : parts.join('   •   ');
  }

  String _statusText(bool active, bool upcoming, bool expired) {
    if (expired) return 'EXPIRED';
    if (upcoming) return 'UPCOMING';
    return active ? 'ACTIVE' : 'INACTIVE';
  }

  Color _statusColor(BuildContext ctx, bool active, bool upcoming, bool expired) {
    final cs = Theme.of(ctx).colorScheme;
    if (expired) return cs.error;
    if (upcoming) return cs.tertiary;
    return active ? cs.primary : cs.outline;
  }
}