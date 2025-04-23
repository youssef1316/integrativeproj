import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmangment/main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        final String userRole = 'user';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': user.email,
          'role': userRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar("Account created successfully! Please log in.", isError: false);

        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _showSnackBar("Sign up failed. Could not create user.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your connection.';
      }
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      _showSnackBar(message, isError: true);
    } catch (e) {
      print("General SignUp Error: $e");
      _showSnackBar("An unexpected error occurred: $e", isError: true);
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Sign Up"),
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
                    controller: _nameController,
                    placeholder: 'Full Name',
                    prefix: const Icon(CupertinoIcons.person),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  CupertinoTextFormFieldRow(
                    controller: _confirmPasswordController,
                    placeholder: 'Confirm Password',
                    prefix: const Icon(CupertinoIcons.lock_shield),
                    obscureText: !_confirmPasswordVisible,
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                      child: Icon(_confirmPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoading ? null : _signUpUser,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? const CupertinoActivityIndicator()
                          : const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        child: const Text("Log In"),
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
