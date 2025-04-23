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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
      }
    } on FirebaseAuthException catch (e) {
      // [Keep all your existing error handling]
    } catch (e) {
      // [Keep existing error handling]
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Sign In"),
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Email Field
                      CupertinoFormSection(
                        backgroundColor: Colors.transparent,
                        margin: EdgeInsets.zero,
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _emailController,
                            prefix: const Icon(CupertinoIcons.mail, size: 20),
                            placeholder: "Email",
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(value.trim());
                              if (!emailValid) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      CupertinoFormSection(
                        backgroundColor: Colors.transparent,
                        margin: EdgeInsets.zero,
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _passwordController,
                            prefix: const Icon(CupertinoIcons.lock, size: 20),
                            placeholder: "Password",
                            obscureText: !_passwordVisible,
                            suffix: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(
                                _passwordVisible
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: _isLoading ? null : _loginUser,
                          child: _isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text("Sign In"),
                        ),
                      ),
                      const Spacer(),
                      // Sign Up Link
                      CupertinoButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pushNamed(context, AppRoutes.signUp);
                        },
                        child: const Text(
                          "Create New Account",
                          style: TextStyle(color: CupertinoColors.link),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
