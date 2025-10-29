import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisata_application/core/theme/app_colors.dart'; // Assuming app_colors.dart exists

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUpUser() async {
    // --- TRANSLATED ---
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification link sent to your email. Please check your email.'), backgroundColor: AppColors.success),
        );
      }

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // --- TRANSLATED ---
      String errorMessage = 'Sign Up Failed: An error occurred.';
       if (e.code == 'weak-password') {
        errorMessage = 'Sign Up Failed: Password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Sign Up Failed: Email is already registered.';
      } else if (e.code == 'invalid-email') {
         errorMessage = 'Sign Up Failed: Email format is invalid.';
      } else {
         errorMessage = 'Sign Up Failed: ${e.message}'; // Show Firebase message if available
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
       if (mounted) {
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: An unknown error occurred. $e'), backgroundColor: AppColors.error),
        );
      }
    }
    finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text("Create New Account", style: Theme.of(context).textTheme.titleLarge), // Title removed as requested
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- TRANSLATED ---
                Text('Create Your New Account', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('Sign up now to start your adventure!',
                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  // --- TRANSLATED ---
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  style: Theme.of(context).textTheme.bodyLarge
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  // --- TRANSLATED ---
                  decoration: const InputDecoration(labelText: 'Password (min. 6 characters)', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  style: Theme.of(context).textTheme.bodyLarge
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  // --- TRANSLATED ---
                  decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  style: Theme.of(context).textTheme.bodyLarge
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    // --- TRANSLATED ---
                    : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _signUpUser, child: const Text('Create Account'))),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () { Navigator.of(context).pop(); },
                  // --- TRANSLATED ---
                  child: const Text('Already have an account? Sign In')
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}