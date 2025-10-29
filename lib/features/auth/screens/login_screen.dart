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
    setState(() { _isLoading = true; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Gagal: ${e.message}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Masuk", style: Theme.of(context).textTheme.titleLarge), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Selamat Datang Kembali!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('Silakan masuk untuk melanjutkan petualangan Anda.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 40),

                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),
                
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loginUser, child: const Text('Masuk'))),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignUpScreen())); }, 
                  child: const Text('Belum punya akun? Daftar Sekarang'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}