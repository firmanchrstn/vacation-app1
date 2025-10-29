import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUpUser() async {
    setState(() { _isLoading = true; });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.'), backgroundColor: AppColors.success),
        );
        Navigator.of(context).pop(); 
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daftar Gagal: ${e.message}'), backgroundColor: AppColors.error),
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
      appBar: AppBar(title: Text("Daftar Akun Baru", style: Theme.of(context).textTheme.titleLarge)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Buat Akun Baru Anda', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('Daftar sekarang untuk memulai petualangan Anda!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 40),

                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password (min. 6 karakter)', prefixIcon: Icon(Icons.lock_outline)), obscureText: true, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _signUpUser, child: const Text('Daftar Akun'))),

                const SizedBox(height: 20),
                TextButton(onPressed: () { Navigator.of(context).pop(); }, child: const Text('Sudah punya akun? Masuk')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}