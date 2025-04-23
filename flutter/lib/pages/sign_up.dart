"import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // [cite: flutter/lib/pages/sign_up.dart]
import 'package:cloud_firestore/cloud_firestore.dart'; // [cite: flutter/lib/pages/sign_up.dart]
// Assuming AppRoutes is accessible via main.dart or a dedicated file if needed for navigation logic later
import 'package:eventmangment/main.dart';

class SignUpScreen extends StatefulWidget { // [cite: flutter/lib/pages/sign_up.dart]
  const SignUpScreen({super.key}); // [cite: flutter/lib/pages/sign_up.dart]

  @override
  State<SignUpScreen> createState() => _SignUpScreenState(); // [cite: flutter/lib/pages/sign_up.dart]
}

class _SignUpScreenState extends State<SignUpScreen> { // [cite: flutter/lib/pages/sign_up.dart]
  final _formKey = GlobalKey<FormState>(); // [cite: flutter/lib/pages/sign_up.dart]
  final _nameController = TextEditingController(); // [cite: flutter/lib/pages/sign_up.dart]
  final _emailController = TextEditingController(); // [cite: flutter/lib/pages/sign_up.dart]
  final _passwordController = TextEditingController(); // [cite: flutter/lib/pages/sign_up.dart]
  final _confirmPasswordController = TextEditingController(); // [cite: flutter/lib/pages/sign_up.dart]

  bool _isLoading = false; // [cite: flutter/lib/pages/sign_up.dart]
  bool _passwordVisible = false; // [cite: flutter/lib/pages/sign_up.dart]
  bool _confirmPasswordVisible = false; // [cite: flutter/lib/pages/sign_up.dart]

  @override
  void dispose() { // [cite: flutter/lib/pages/sign_up.dart]
    _nameController.dispose(); // [cite: flutter/lib/pages/sign_up.dart]
    _emailController.dispose(); // [cite: flutter/lib/pages/sign_up.dart]
    _passwordController.dispose(); // [cite: flutter/lib/pages/sign_up.dart]
    _confirmPasswordController.dispose(); // [cite: flutter/lib/pages/sign_up.dart]
    super.dispose(); // [cite: flutter/lib/pages/sign_up.dart]
  }

  void _showSnackBar(String message, {bool isError = true}) { // [cite: flutter/lib/pages/sign_up.dart]
    if (!mounted) return; // [cite: flutter/lib/pages/sign_up.dart]
    ScaffoldMessenger.of(context).showSnackBar( // [cite: flutter/lib/pages/sign_up.dart]
      SnackBar( // [cite: flutter/lib/pages/sign_up.dart]
        content: Text(message), // [cite: flutter/lib/pages/sign_up.dart]
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green, // [cite: flutter/lib/pages/sign_up.dart]
      ),
    );
  }

  // --- Sign Up Logic ---
  Future<void> _signUpUser() async { // [cite: flutter/lib/pages/sign_up.dart]
    // 1. Validate form - Triggers all validator functions
    if (!_formKey.currentState!.validate()) { // [cite: flutter/lib/pages/sign_up.dart]
      return; // Don't proceed if validation fails
    }
    // 2. Show Loading
    setState(() { _isLoading = true; }); // [cite: flutter/lib/pages/sign_up.dart]

    try { // [cite: flutter/lib/pages/sign_up.dart]
      // 3. Create user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword( // [cite: flutter/lib/pages/sign_up.dart]
        email: _emailController.text.trim(), // [cite: flutter/lib/pages/sign_up.dart]
        password: _passwordController.text.trim(), // [cite: flutter/lib/pages/sign_up.dart]
      );

      User? user = userCredential.user; // [cite: flutter/lib/pages/sign_up.dart]

      if (user != null) { // [cite: flutter/lib/pages/sign_up.dart]
        // 4. Add user details (including default role) to Firestore
        final String userRole = 'user'; // [cite: flutter/lib/pages/sign_up.dart]

        await FirebaseFirestore.instance // [cite: flutter/lib/pages/sign_up.dart]
            .collection('users') // [cite: flutter/lib/pages/sign_up.dart]
            .doc(user.uid) // Use UID from Auth as Document ID // [cite: flutter/lib/pages/sign_up.dart]
            .set({ // [cite: flutter/lib/pages/sign_up.dart]
          'name': _nameController.text.trim(), // [cite: flutter/lib/pages/sign_up.dart]
          'email': user.email, // Use email from Auth user object // [cite: flutter/lib/pages/sign_up.dart]
          'role': userRole, // Set the role // [cite: flutter/lib/pages/sign_up.dart]
          'createdAt': FieldValue.serverTimestamp(), // Good practice // [cite: flutter/lib/pages/sign_up.dart]
        });

        _showSnackBar("Account created successfully! Please log in.", isError: false); // [cite: flutter/lib/pages/sign_up.dart]

        if (!mounted) return; // [cite: flutter/lib/pages/sign_up.dart]
        // Navigate back to login screen after successful signup
        Navigator.pop(context); // [cite: flutter/lib/pages/sign_up.dart]

      } else { // [cite: flutter/lib/pages/sign_up.dart]
        _showSnackBar("Sign up failed. Could not create user.", isError: true); // [cite: flutter/lib/pages/sign_up.dart]
      }

    } on FirebaseAuthException catch (e) { // [cite: flutter/lib/pages/sign_up.dart]
      String message = "An error occurred. Please try again."; // [cite: flutter/lib/pages/sign_up.dart]
      if (e.code == 'weak-password') { // [cite: flutter/lib/pages/sign_up.dart]
        message = 'The password provided is too weak.'; // [cite: flutter/lib/pages/sign_up.dart]
      } else if (e.code == 'email-already-in-use') { // [cite: flutter/lib/pages/sign_up.dart]
        message = 'An account already exists for that email.'; // [cite: flutter/lib/pages/sign_up.dart]
      } else if (e.code == 'invalid-email') { // [cite: flutter/lib/pages/sign_up.dart]
        message = 'The email address is not valid.'; // [cite: flutter/lib/pages/sign_up.dart]
      } else if (e.code == 'network-request-failed') { // [cite: flutter/lib/pages/sign_up.dart]
        message = 'Network error. Please check your connection.'; // [cite: flutter/lib/pages/sign_up.dart]
      }
      print("FirebaseAuthException: ${e.code} - ${e.message}"); // [cite: flutter/lib/pages/sign_up.dart]
      _showSnackBar(message, isError: true); // [cite: flutter/lib/pages/sign_up.dart]
    } catch(e) { // [cite: flutter/lib/pages/sign_up.dart]
      print("General SignUp Error: $e"); // [cite: flutter/lib/pages/sign_up.dart]
      _showSnackBar("An unexpected error occurred: $e", isError: true); // [cite: flutter/lib/pages/sign_up.dart]
    } finally { // [cite: flutter/lib/pages/sign_up.dart]
      if (mounted) setState(() { _isLoading = false; }); // [cite: flutter/lib/pages/sign_up.dart]
    }
  }


  @override
  Widget build(BuildContext context) { // [cite: flutter/lib/pages/sign_up.dart]
    final theme = Theme.of(context); // [cite: flutter/lib/pages/sign_up.dart]
    return Scaffold( // [cite: flutter/lib/pages/sign_up.dart]
      appBar: AppBar( // [cite: flutter/lib/pages/sign_up.dart]
        title: const Text("Sign Up"), // [cite: flutter/lib/pages/sign_up.dart]
        centerTitle: true, // [cite: flutter/lib/pages/sign_up.dart]
      ),
      body: Center( // [cite: flutter/lib/pages/sign_up.dart]
        child: SingleChildScrollView( // [cite: flutter/lib/pages/sign_up.dart]
          padding: const EdgeInsets.all(24.0), // [cite: flutter/lib/pages/sign_up.dart]
          child: Form( // [cite: flutter/lib/pages/sign_up.dart]
            key: _formKey, // [cite: flutter/lib/pages/sign_up.dart]
            child: Column( // [cite: flutter/lib/pages/sign_up.dart]
              mainAxisAlignment: MainAxisAlignment.center, // [cite: flutter/lib/pages/sign_up.dart]
              crossAxisAlignment: CrossAxisAlignment.stretch, // [cite: flutter/lib/pages/sign_up.dart]
              children: [
                // --- Name Field ---
                TextFormField( // [cite: flutter/lib/pages/sign_up.dart]
                  controller: _nameController, // [cite: flutter/lib/pages/sign_up.dart]
                  decoration: InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), // [cite: flutter/lib/pages/sign_up.dart]
                  // --- FIXED: Name Validation Logic Added ---
                  validator: (value) { // [cite: flutter/lib/pages/sign_up.dart]
                    if (value == null || value.trim().isEmpty) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Please enter your name'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    return null; // Return null if valid // [cite: flutter/lib/pages/sign_up.dart]
                  },
                  // -----------------------------------------
                  textCapitalization: TextCapitalization.words, // [cite: flutter/lib/pages/sign_up.dart]
                  autovalidateMode: AutovalidateMode.onUserInteraction, // [cite: flutter/lib/pages/sign_up.dart]
                ),
                const SizedBox(height: 16), // [cite: flutter/lib/pages/sign_up.dart]

                // --- Email Field ---
                TextFormField( // [cite: flutter/lib/pages/sign_up.dart]
                  controller: _emailController, // [cite: flutter/lib/pages/sign_up.dart]
                  decoration: InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), // [cite: flutter/lib/pages/sign_up.dart]
                  keyboardType: TextInputType.emailAddress, // [cite: flutter/lib/pages/sign_up.dart]
                  // --- FIXED: Email Validation Logic Added ---
                  validator: (value) { // [cite: flutter/lib/pages/sign_up.dart]
                    if (value == null || value.trim().isEmpty) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Please enter your email'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+") // [cite: flutter/lib/pages/sign_up.dart]
                        .hasMatch(value.trim()); // [cite: flutter/lib/pages/sign_up.dart]
                    if (!emailValid) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Please enter a valid email format'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    return null; // Return null if valid // [cite: flutter/lib/pages/sign_up.dart]
                  },
                  // ------------------------------------------
                  autovalidateMode: AutovalidateMode.onUserInteraction, // [cite: flutter/lib/pages/sign_up.dart]
                ),
                const SizedBox(height: 16), // [cite: flutter/lib/pages/sign_up.dart]

                // --- Password Field ---
                TextFormField( // [cite: flutter/lib/pages/sign_up.dart]
                  controller: _passwordController, // [cite: flutter/lib/pages/sign_up.dart]
                  decoration: InputDecoration( // [cite: flutter/lib/pages/sign_up.dart]
                    labelText: "Password", // [cite: flutter/lib/pages/sign_up.dart]
                    prefixIcon: Icon(Icons.lock_outline), // [cite: flutter/lib/pages/sign_up.dart]
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // [cite: flutter/lib/pages/sign_up.dart]
                    suffixIcon: IconButton( // [cite: flutter/lib/pages/sign_up.dart]
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility), // [cite: flutter/lib/pages/sign_up.dart]
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible)), // [cite: flutter/lib/pages/sign_up.dart]
                  ),
                  obscureText: !_passwordVisible, // [cite: flutter/lib/pages/sign_up.dart]
                  // --- FIXED: Password Validation Logic Added ---
                  validator: (value) { // [cite: flutter/lib/pages/sign_up.dart]
                    if (value == null || value.isEmpty) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Please enter your password'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    if (value.length < 6) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Password must be at least 6 characters'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    return null; // Return null if valid // [cite: flutter/lib/pages/sign_up.dart]
                  },
                  // -------------------------------------------
                  autovalidateMode: AutovalidateMode.onUserInteraction, // [cite: flutter/lib/pages/sign_up.dart]
                ),
                const SizedBox(height: 16), // [cite: flutter/lib/pages/sign_up.dart]

                // --- Confirm Password Field ---
                TextFormField( // [cite: flutter/lib/pages/sign_up.dart]
                  controller: _confirmPasswordController, // [cite: flutter/lib/pages/sign_up.dart]
                  decoration: InputDecoration( // [cite: flutter/lib/pages/sign_up.dart]
                    labelText: "Confirm Password", // [cite: flutter/lib/pages/sign_up.dart]
                    prefixIcon: Icon(Icons.lock_outline), // [cite: flutter/lib/pages/sign_up.dart]
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // [cite: flutter/lib/pages/sign_up.dart]
                    suffixIcon: IconButton( // [cite: flutter/lib/pages/sign_up.dart]
                        icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility), // [cite: flutter/lib/pages/sign_up.dart]
                        onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible)), // [cite: flutter/lib/pages/sign_up.dart]
                  ),
                  obscureText: !_confirmPasswordVisible, // [cite: flutter/lib/pages/sign_up.dart]
                  // --- FIXED: Confirm Password Validation Logic ---
                  validator: (value) { // [cite: flutter/lib/pages/sign_up.dart]
                    if (value == null || value.isEmpty) { // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Please confirm your password'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    if (value != _passwordController.text) { // Compare with password controller // [cite: flutter/lib/pages/sign_up.dart]
                      return 'Passwords do not match'; // [cite: flutter/lib/pages/sign_up.dart]
                    }
                    return null; // [cite: flutter/lib/pages/sign_up.dart]
                  },
                  // -----------------------------------------------
                  autovalidateMode: AutovalidateMode.onUserInteraction, // [cite: flutter/lib/pages/sign_up.dart]
                ),
                const SizedBox(height: 24), // [cite: flutter/lib/pages/sign_up.dart]

                // --- Sign Up Button ---
                ElevatedButton( // [cite: flutter/lib/pages/sign_up.dart]
                  onPressed: _isLoading ? null : _signUpUser, // Calls _signUpUser which now uses validation // [cite: flutter/lib/pages/sign_up.dart]
                  style: ElevatedButton.styleFrom( // [cite: flutter/lib/pages/sign_up.dart]
                    padding: const EdgeInsets.symmetric(vertical: 16), // [cite: flutter/lib/pages/sign_up.dart]
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // [cite: flutter/lib/pages/sign_up.dart]
                    backgroundColor: theme.colorScheme.primary, // [cite: flutter/lib/pages/sign_up.dart]
                    foregroundColor: theme.colorScheme.onPrimary, // [cite: flutter/lib/pages/sign_up.dart]
                  ),
                  child: _isLoading // [cite: flutter/lib/pages/sign_up.dart]
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) // [cite: flutter/lib/pages/sign_up.dart]
                      : const Text("Sign Up", style: TextStyle(fontSize: 16)), // [cite: flutter/lib/pages/sign_up.dart]
                ),
                const SizedBox(height: 16), // [cite: flutter/lib/pages/sign_up.dart]

                // --- Link back to Login ---
                Row( // [cite: flutter/lib/pages/sign_up.dart]
                  mainAxisAlignment: MainAxisAlignment.center, // [cite: flutter/lib/pages/sign_up.dart]
                  children: [ // [cite: flutter/lib/pages/sign_up.dart]
                    const Text("Already have an account?"), // [cite: flutter/lib/pages/sign_up.dart]
                    TextButton( // [cite: flutter/lib/pages/sign_up.dart]
                      onPressed: _isLoading ? null : () { // [cite: flutter/lib/pages/sign_up.dart]
                        Navigator.pop(context); // Go back to the previous screen (Login) // [cite: flutter/lib/pages/sign_up.dart]
                      },
                      child: const Text("Log In"), // [cite: flutter/lib/pages/sign_up.dart]
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
