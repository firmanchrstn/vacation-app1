import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
import 'package:wisata_application/features/favorites/screens/favorites_screen.dart';
// PENTING: Pastikan path import ini benar
import 'package:wisata_application/features/itinerary/screens/itinerary_screen.dart'; 
import 'package:wisata_application/features/profile/screens/edit_profile_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login.')));
    }

    final DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          String userName = 'Loading...';
          String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
          String? profileImageUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            userName = data?['nama'] ?? 'User';
            profileImageUrl = data?['profileImageUrl'] as String?;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                  child: profileImageUrl == null 
                      ? Icon(Icons.person_rounded, size: 60, color: AppColors.primary) // <-- Line 60-an
                      : null,
                ),
                const SizedBox(height: 15),
                Text(userName, style: Theme.of(context).textTheme.headlineSmall),
                Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 20),
                
                // Tombol Edit Profile
                OutlinedButton(
                  onPressed: () {
                    // Pastikan EditProfileScreen sudah diimport
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: const Text('Edit Profile'),
                ),
                
                const SizedBox(height: 40),

                // Menu Favorites
                _buildMenuTile(
                  context,
                  icon: Icons.favorite_border_rounded,
                  title: 'Favorites',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                  },
                ),
                // Menu Travel Plan
                _buildMenuTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Travel Plan',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ItineraryScreen()));
                  },
                ),
                
                const Divider(height: 40),

                // Menu Logout
                _buildMenuTile(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: _logout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDestructive ? AppColors.error : AppColors.textDark,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}