import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/main.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, "Logout failed: ${e.toString()}");
      }
    }
  }

  void _showUserProfileDialog(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showErrorSnackBar(context, "Error: User not logged in.");
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('User Profile'),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CupertinoActivityIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Error loading profile.');
              }

              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              return Column(
                children: [
                  _buildProfileRow('Name:', userData['name'] ?? 'N/A'),
                  _buildProfileRow('Email:', userData['email'] ?? 'N/A'),
                  _buildProfileRow('Role:', userData['role'] ?? 'N/A'),
                ],
              );
            },
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showMyTicketsDialog(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final Stream<QuerySnapshot> userTicketsStream = FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .snapshots();

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoActionSheet(
          title: const Text("My Purchased Tickets"),
          message: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: StreamBuilder<QuerySnapshot>(
              stream: userTicketsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No tickets found"));
                }

                List<QueryDocumentSnapshot> soldTickets = snapshot.data!.docs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'sold')
                    .toList()
                  ..sort((a, b) {
                    final tsA = (a.data() as Map<String, dynamic>)['purchaseTimestamp'] as Timestamp?;
                    final tsB = (b.data() as Map<String, dynamic>)['purchaseTimestamp'] as Timestamp?;
                    return (tsB ?? Timestamp.now()).compareTo(tsA ?? Timestamp.now());
                  });

                return ListView.builder(
                  itemCount: soldTickets.length,
                  itemBuilder: (context, index) {
                    final ticketData = soldTickets[index].data() as Map<String, dynamic>;
                    final purchaseTs = ticketData['purchaseTimestamp'] as Timestamp?;
                    final purchaseDate = purchaseTs != null
                        ? DateFormat('yyyy-MM-dd hh:mm a').format(purchaseTs.toDate())
                        : 'N/A';

                    return CupertinoListTile(
                      title: Text('Event: ${ticketData['eventId'] ?? 'N/A'}),
                          subtitle: Text('Level: ${ticketData['levelName'] ?? 'N/A'}\nPurchased: $purchaseDate'),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.qrcode),
                        onPressed: () => _showQrCodeDialog(
                            context,
                            ticketData['ticketId'] ?? soldTickets[index].id
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }

  void _showQrCodeDialog(BuildContext context, String ticketId) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext qrDialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Ticket QR Code'),
          content: SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: QrImageView(
                data: ticketId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Close'),
              onPressed: () => Navigator.of(qrDialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: CupertinoColors.systemRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Home'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_right_to_line, color: CupertinoColors.systemRed),
          onPressed: () => _logout(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            // View Events Button
            CupertinoButton.filled(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.calendar),
                  SizedBox(width: 8),
                  Text('View Available Events'),
                ],
              ),
              onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
            ),
            const SizedBox(height: 16),
            // View Profile Button
            CupertinoButton(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.person),
                  SizedBox(width: 8),
                  Text('View Profile Info'),
                ],
              ),
              onPressed: () => _showUserProfileDialog(context),
            ),
            const SizedBox(height: 16),
            // View My Tickets Button
            CupertinoButton.filled(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.ticket),
                  SizedBox(width: 8),
                  Text('View My Tickets'),
                ],
              ),
              onPressed: () => _showMyTicketsDialog(context),
            ),
            const SizedBox(height: 16),
            // Give Feedback Button
            CupertinoButton(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chat_bubble),
                  SizedBox(width: 8),
                  Text('Give Feedback'),
                ],
              ),
              onPressed: () => _navigateTo(context, AppRoutes.feedback),
            ),
          ],
        ),
      ),
    );
  }
}
