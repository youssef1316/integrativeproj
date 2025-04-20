// lib/pages/admin_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// Make sure these imports point to the correct page files
// import 'package:eventmangment/pages/eventcreation.dart';
// import 'package:eventmangment/pages/viewevents.dart';
// Import main.dart or your routes file to access AppRoutes constants
import 'package:eventmangment/main.dart'; // Ensure AppRoutes constants exist

// --- Constants ---
// (Keep constants as they were in your previous version)
class _AppSpacings {
  static const double verticalButtonSpacing = 20.0;
  static const double bottomButtonSpacing = 40.0;
}
class _AppPadding {
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 24);
  static const EdgeInsets logoutButtonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 24);
}
class _AppRadius {
  static const double buttonRadius = 10.0;
}
class _AppElevation {
  static const double buttonElevation = 3.0;
}
class _AppTextStyles {
  static const TextStyle buttonText = TextStyle( fontSize: 17, fontWeight: FontWeight.w600);
  static const TextStyle appBarTitle = TextStyle( color: Colors.black, fontWeight: FontWeight.bold );
  static const TextStyle logoutButtonText = TextStyle( fontSize: 16, fontWeight: FontWeight.w500);
}
class _AppColors {
  static const Color primaryBackground = Color(0xFFF4F6F8);
  static const Color appBarBackground = Colors.white;
  static const Color logoutButtonBorder = Colors.redAccent;
}
// --- End Constants ---

// --- Changed Widget to StatefulWidget ---
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> { // State class

  // Helper method for navigation (now inside State)
  void _navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    // Pass arguments if provided
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  // --- Logout Function (now inside State) ---
  Future<void> _logout() async { // Removed context parameter, uses widget's context
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) { // Use mounted check available in State
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Show Select Event Dialog Function ---
  Future<String?> _showSelectEventDialog(BuildContext context) async {
    List<Map<String, String>> eventList = [];
    bool isLoading = true;
    String? error;
    String? selectedId; // State variable for the dropdown inside the dialog

    // Use StatefulBuilder to manage state *within* the dialog
    return showDialog<String?>(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Allows updating dialog state
          builder: (stfContext, stfSetState) {
            // Fetch data only once when dialog builds if list is empty
            if (isLoading && eventList.isEmpty && error == null) {
              FirebaseFirestore.instance.collection('events').orderBy('name').get().then((snapshot) {
                if (!mounted) return; // Check if main page is still mounted
                stfSetState(() { // Update dialog state
                  eventList = snapshot.docs.map((doc) {
                    final data = doc.data();
                    return {
                      'id': doc.id,
                      'name': data['name'] as String? ?? 'Unnamed Event',
                    };
                  }).toList();
                  isLoading = false;
                });
              }).catchError((e) {
                print("Error fetching events for dialog: $e");
                if (!mounted) return;
                stfSetState(() { // Update dialog state
                  error = "Failed to load events: ${e.toString()}";
                  isLoading = false;
                });
              });
            }

            return AlertDialog(
              title: const Text("Select Event for Report"),
              content: SingleChildScrollView( // In case of error message or many events
                child: SizedBox(
                  width: double.maxFinite, // Use available width
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Fit content
                    children: [
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        )
                      else if (error != null)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(error!, style: const TextStyle(color: Colors.red)),
                        )
                      else if (eventList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text("No events found."),
                          )
                        else
                        // Dropdown to select event
                          DropdownButtonFormField<String>(
                            value: selectedId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Event',
                              border: OutlineInputBorder(),
                              hintText: 'Select an event',
                            ),
                            items: eventList.map((event) {
                              return DropdownMenuItem<String>(
                                value: event['id'],
                                child: Text(event['name']!, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              stfSetState(() { // Update dialog state
                                selectedId = value;
                              });
                            },
                            validator: (value) => value == null ? 'Please select an event' : null,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                          ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(dialogContext, null); // Return null on cancel
                  },
                ),
                ElevatedButton(
                  // Disable if loading, error, or no event selected
                  onPressed: (isLoading || error != null || selectedId == null)
                      ? null
                      : () {
                    Navigator.pop(dialogContext, selectedId); // Return selected ID
                  },
                  child: const Text("View Report"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
      padding: _AppPadding.buttonPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_AppRadius.buttonRadius),
      ),
      elevation: _AppElevation.buttonElevation,
      textStyle: _AppTextStyles.buttonText,
    );

    return Scaffold(
      backgroundColor: _AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: _AppTextStyles.appBarTitle),
        backgroundColor: _AppColors.appBarBackground,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Create Event Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Event'),
                style: elevatedButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(theme.colorScheme.primary),
                  foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary),
                ),
                onPressed: () => _navigateTo(context, AppRoutes.createEvent),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing),

              // --- View Events Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.event_note),
                label: const Text('View All Events'),
                style: elevatedButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(theme.colorScheme.secondary),
                  foregroundColor: MaterialStateProperty.all(theme.colorScheme.onSecondary),
                ),
                onPressed: () => _navigateTo(context, AppRoutes.viewEvents),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing),

              // --- View Users Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.people_outline),
                label: const Text('View Users'),
                style: elevatedButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(theme.colorScheme.secondary),
                  foregroundColor: MaterialStateProperty.all(theme.colorScheme.onSecondary),
                ),
                onPressed: () => _navigateTo(context, AppRoutes.viewUsers),
              ),
              const SizedBox(height: _AppSpacings.verticalButtonSpacing),

              // --- Event Report Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Event Report'),
                style: elevatedButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(theme.colorScheme.tertiaryContainer),
                  foregroundColor: MaterialStateProperty.all(theme.colorScheme.onTertiaryContainer),
                ),
                onPressed: () async { // Make async to await dialog result
                  final selectedEventId = await _showSelectEventDialog(context);
                  if (selectedEventId != null && mounted) {
                    // Navigate to Reports screen with arguments
                    _navigateTo(
                        context,
                        AppRoutes.Reports,
                        // --- CHANGE THIS LINE ---
                        arguments: selectedEventId // Pass the selected ID string directly
                      // --- END CHANGE ---
                    );
                  }
                },
              ),

              const SizedBox(height: _AppSpacings.bottomButtonSpacing),

              // --- Logout Button ---
              OutlinedButton.icon(
                icon: Icon(Icons.logout, color: theme.colorScheme.error),
                label: Text(
                    'Logout',
                    style: _AppTextStyles.logoutButtonText.copyWith(
                        color: theme.colorScheme.error
                    )
                ),
                style: OutlinedButton.styleFrom(
                  padding: _AppPadding.logoutButtonPadding,
                  side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_AppRadius.buttonRadius),
                  ),
                ),
                onPressed: _logout, // Call method from state
              ),
            ],
          ),
        ),
      ),
    );
  }
}