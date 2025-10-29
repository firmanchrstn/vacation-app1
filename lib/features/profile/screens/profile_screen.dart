import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisata_application/core/theme/app_colors.dart'; // Assuming app_colors.dart exists

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  // Initialize user document reference
  late final DocumentReference _userRef;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      _loadUserData();
    }
  }

  // Function to load initial data or create a new document
  void _loadUserData() async {
    // If userId is null (not logged in), do nothing
    if (userId == null) return;

    final userData = await _userRef.get();
    if (userData.exists) {
      final data = userData.data() as Map<String, dynamic>;
      // Fill controller with saved name
      _nameController.text = data['nama'] ?? '';
    } else {
      // If document doesn't exist, create a new one with email
      await _userRef.set({
        'email': FirebaseAuth.instance.currentUser!.email,
        'nama': '', // Initially empty name
      });
      _nameController.text = '';
    }
    // Check if the widget is still mounted before calling setState
    if(mounted) {
      setState(() {});
    }
  }

  // Function to save name to Firestore
  Future<void> _updateUserName() async {
    if (userId == null) {
      // --- TRANSLATED ---
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in to save data.'), backgroundColor: AppColors.error));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      // --- TRANSLATED ---
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty.'), backgroundColor: AppColors.error));
      return;
    }

    try {
      // Update only the 'nama' field
      await _userRef.update({'nama': _nameController.text.trim()});
      if (mounted) {
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully!'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will handle navigation after logout
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not logged in, show error message
    if (userId == null) {
      // --- TRANSLATED ---
      return Scaffold(appBar: AppBar(title: Text('My Profile')), body: Center(child: Text('Please log in to view profile.')));
    }

    // StreamBuilder to listen for real-time user data changes
    return StreamBuilder<DocumentSnapshot>(
      stream: _userRef.snapshots(),
      builder: (context, snapshot) {
        // --- TRANSLATED ---
        String userName = 'Loading...';
        String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No email available';

        if (snapshot.hasData && snapshot.data!.exists) {
          // --- TRANSLATED ---
          userName = (snapshot.data!.data() as Map<String, dynamic>?)?['nama'] ?? 'New User';
          if (userName.trim().isEmpty) {
            userName = 'New User';
          }
        } else if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasError) {
          // If document doesn't exist yet but user is logged in
           userName = 'New User';
        }


        // Show loading state while data is not ready
        if (snapshot.connectionState == ConnectionState.waiting && userName == 'Loading...') {
          // You might want a better loading indicator here, but keep name field populated if already loaded once
          userName = _nameController.text.isEmpty ? 'Loading...' : _nameController.text;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          // --- TRANSLATED ---
          appBar: AppBar(title: Text('My Profile', style: Theme.of(context).textTheme.titleLarge)),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 60, backgroundColor: AppColors.primary.withOpacity(0.1), child: Icon(Icons.person_rounded, size: 70, color: AppColors.primary)),
                  const SizedBox(height: 20),
                  // Display name from Firestore/Stream
                  Text(userName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 5),
                  Text(userEmail, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                  const SizedBox(height: 40),

                  // Update Name Form
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      // --- TRANSLATED ---
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary),
                      // --- TRANSLATED ---
                      suffixIcon: IconButton(icon: Icon(Icons.save_rounded, color: AppColors.primary), onPressed: _updateUserName, tooltip: 'Save Name'),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    // --- TRANSLATED ---
                    child: ElevatedButton.icon(onPressed: _updateUserName, icon: const Icon(Icons.save_rounded), label: const Text('Save Changes'))
                  ),
                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                      // --- TRANSLATED ---
                      label: Text('Logout', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppColors.error, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}