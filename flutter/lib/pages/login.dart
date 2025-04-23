import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        backgroundColor: isError ? CupertinoColors.systemRed : CupertinoColors.activeGreen,
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Login"),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _emailController,
                    placeholder: 'Email',
                    prefix: const Icon(CupertinoIcons.mail),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value.trim());
                      if (!emailValid) {
                        return 'Please enter a valid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CupertinoTextFormFieldRow(
                    controller: _passwordController,
                    placeholder: 'Password',
                    prefix: const Icon(CupertinoIcons.lock),
                    obscureText: !_passwordVisible,
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      child: Icon(_passwordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : _loginUser,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : const Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isLoading ? null : () {
                          Navigator.pushNamed(context, AppRoutes.signUp);
                        },
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
