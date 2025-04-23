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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
      ),
    );
  }

  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar("Account created successfully!", isError: false);
        if (!mounted) return;
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // [Keep all your existing error handling]
    } catch(e) {
      // [Keep existing error handling]
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Create Account"),
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
                      const SizedBox(height: 16),
                      // Name Field
                      CupertinoFormSection(
                        backgroundColor: Colors.transparent,
                        margin: EdgeInsets.zero,
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _nameController,
                            prefix: const Icon(CupertinoIcons.person, size: 20),
                            placeholder: "Full Name",
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      // Confirm Password Field
                      CupertinoFormSection(
                        backgroundColor: Colors.transparent,
                        margin: EdgeInsets.zero,
                        children: [
                          CupertinoTextFormFieldRow(
                            controller: _confirmPasswordController,
                            prefix: const Icon(CupertinoIcons.lock, size: 20),
                            placeholder: "Confirm Password",
                            obscureText: !_confirmPasswordVisible,
                            suffix: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(
                                _confirmPasswordVisible
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: _isLoading ? null : _signUpUser,
                          child: _isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text("Create Account"),
                        ),
                      ),
                      const Spacer(),
                      // Login Link
                      CupertinoButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          "Already have an account? Sign In",
                          style: TextStyle(color: CupertinoColors.link),
                        ),
                      ),
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
