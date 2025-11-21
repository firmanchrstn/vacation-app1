import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
// 1. Import package yang dibutuhkan
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data'; // Untuk data gambar di web

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  late final DocumentReference _userRef;

  // 2. State untuk loading upload
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      _loadUserData();
    }
  }

  void _loadUserData() async {
    // ... (Fungsi _loadUserData tetap sama) ...
    if (userId == null) return; 
    final userData = await _userRef.get();
    if (userData.exists) {
      final data = userData.data() as Map<String, dynamic>;
      _nameController.text = data['nama'] ?? ''; 
    } else {
      await _userRef.set({'email': FirebaseAuth.instance.currentUser!.email, 'nama': ''});
      _nameController.text = '';
    }
    if(mounted) setState(() {});
  }

  Future<void> _updateUserName() async {
    // ... (Fungsi _updateUserName tetap sama) ...
    if (userId == null) { /* ... handle error ... */ return; }
    if (_nameController.text.trim().isEmpty) { /* ... handle error ... */ return; }
    try {
      await _userRef.update({'nama': _nameController.text.trim()}); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diupdate!'), backgroundColor: AppColors.success));
    } catch (e) { /* ... handle error ... */ }
  }

  // 3. FUNGSI UNTUK MENGAMBIL DAN MENGUNGGAH GAMBAR
  Future<void> _pickAndUploadImage() async {
    if (userId == null) return; // Pastikan user login

    // 1. Ambil Gambar
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      // Pengguna membatalkan pemilihan gambar
      return;
    }
    
    setState(() { _isUploading = true; });

    try {
      // 2. Baca data gambar (sebagai bytes)
      final Uint8List imageData = await image.readAsBytes();
      
      // 3. Tentukan path di Firebase Storage
      // 'profile_pictures/{userId}/profile.jpg'
      final String filePath = 'profile_pictures/$userId/profile.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

      // 4. Unggah gambar
      // Kita gunakan putData (rekomendasi untuk web/bytes)
      await storageRef.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));

      // 5. Dapatkan URL Download
      final String downloadURL = await storageRef.getDownloadURL();

      // 6. Simpan URL ke Firestore
      await _userRef.update({'profileImageUrl': downloadURL});

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diupdate!'), backgroundColor: AppColors.success));

    } on FirebaseException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah: ${e.message}'), backgroundColor: AppColors.error));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: AppColors.error));
    } finally {
      if(mounted) setState(() { _isUploading = false; });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(appBar: AppBar(title: Text('Profil Saya')), body: Center(child: Text('Silakan login untuk melihat profil.')));
    }
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _userRef.snapshots(),
      builder: (context, snapshot) {
        String userName = 'Memuat...';
        String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Tidak ada email';
        String? profileImageUrl; // Variabel untuk URL gambar

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          userName = data?['nama'] ?? 'Pengguna Baru';
          // Ambil URL gambar dari data
          profileImageUrl = data?['profileImageUrl'] as String?; 
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
             userName = _nameController.text.isEmpty ? 'Memuat...' : _nameController.text;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text('Profil Saya', style: Theme.of(context).textTheme.titleLarge)),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- PERUBAHAN TAMPILAN FOTO PROFIL ---
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        // Tampilkan gambar jika URL ada, jika tidak, tampilkan ikon
                        backgroundImage: (profileImageUrl != null) 
                            ? NetworkImage(profileImageUrl) 
                            : null, // Pakai NetworkImage
                        child: (profileImageUrl == null) 
                            ? Icon(Icons.person_rounded, size: 70, color: AppColors.primary) 
                            : null,
                      ),
                      // Tampilkan loading di atas avatar
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: AppColors.accent),
                        ),
                      // Tombol Edit Foto
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2)
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textLight),
                            onPressed: _isUploading ? null : _pickAndUploadImage, // Nonaktifkan tombol saat upload
                            tooltip: 'Ganti Foto Profil',
                          ),
                        ),
                      ),
                    ],
                  ),
                  // --- AKHIR PERUBAHAN FOTO PROFIL ---

                  const SizedBox(height: 20),
                  Text(userName, style: Theme.of(context).textTheme.headlineSmall), 
                  const SizedBox(height: 5),
                  Text(userEmail, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                  const SizedBox(height: 40),

                  // Form Update Nama
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary),
                      suffixIcon: IconButton(icon: Icon(Icons.save_rounded, color: AppColors.primary), onPressed: _updateUserName, tooltip: 'Simpan Nama'),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _updateUserName, icon: const Icon(Icons.save_rounded), label: const Text('Simpan Perubahan'))),
                  const SizedBox(height: 40),
                  
                  // Tombol Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
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