import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisata_application/features/auth/screens/signup_screen.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    // ... (Fungsi login tetap sama) ...
    setState(() { _isLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.message}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  // --- FUNGSI BARU UNTUK RESET PASSWORD ---
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Validasi jika email kosong
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() { _isLoading = true; });
    
    try {
      // Kirim email reset
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email. Please check your inbox.'), backgroundColor: AppColors.success),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }
  // --- AKHIR FUNGSI BARU ---

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome Back!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('Please sign in to continue your adventure.',
                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 40),

                TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    style: Theme.of(context).textTheme.bodyLarge
                ),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    style: Theme.of(context).textTheme.bodyLarge
                ),
                
                // --- TOMBOL FORGOT PASSWORD BARU ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _resetPassword, // Nonaktifkan saat loading
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Sesuaikan spasi jika perlu
                
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loginUser, child: const Text('Sign In'))),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignUpScreen())); }, 
                  child: const Text('Don\'t have an account? Sign Up Now'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}