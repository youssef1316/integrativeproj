import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import main.dart (or your routes file) to access the central AppRoutes
import 'package:eventmangment/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  Future<void> _loginUser() async {
    // --- Use the Form key to validate ---
    if (!_formKey.currentState!.validate()) {
      // If validation fails, do nothing more
      return;
    }
    // --- Validation passed, proceed ---
    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final String role = userData['role'] ?? 'user';
          if (!mounted) return;
          // Use AppRoutes constants defined in main.dart
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          }
        } else {
          print("User document not found for UID: ${user.uid}. Defaulting to user role.");
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.userHome);
        }
      } else {
        _showSnackBar("Login failed. User object not found.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') message = 'No user found for that email.';
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential') message = 'Wrong password provided.';
      else if (e.code == 'too-many-requests') message = 'Too many login attempts. Please try again later.';
      else if (e.code == 'network-request-failed') message = 'Network error. Please check your connection.';
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      _showSnackBar(message, isError: true);
    } catch (e) {
      print("General Login Error: $e");
      _showSnackBar("An unexpected error occurred: $e", isError: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Login"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form( // Form widget uses the _formKey
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Email Field ---
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  keyboardType: TextInputType.emailAddress,
                  // --- ADDED: Email Validation Logic ---
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value.trim());
                    if (!emailValid) {
                      return 'Please enter a valid email format';
                    }
                    return null; // Return null if valid
                  },
                  // --------------------------------------
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),

                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible)),
                  ),
                  obscureText: !_passwordVisible,
                  // --- ADDED: Password Validation Logic ---
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null; // Return null if valid
                  },
                  // ----------------------------------------
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),

                // --- Login Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser, // Calls _loginUser which now uses validation
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Login", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),

                // --- Sign Up Navigation ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        // Use AppRoutes constant defined centrally
                        Navigator.pushNamed(context, AppRoutes.signUp);
                      },
                      child: const Text("Sign Up"),
                    ),
                  ],
                ),
                // -----------------------------
              ],
            ),
          ),
        ),
      ),
    );
  }
}
