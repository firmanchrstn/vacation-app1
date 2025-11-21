import 'dart:typed_data'; // PENTING: Untuk data gambar universal
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
// JANGAN import 'dart:io'; agar aman di Web

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  late final DocumentReference _userRef;
  
  bool _isLoading = false;
  String? _currentImageUrl;
  
  // Kita simpan gambar sebagai Bytes (Data), bukan File/Path
  // Ini aman untuk Web dan HP
  Uint8List? _pickedImageBytes; 

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      _userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      _loadUserData();
    }
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  void _loadUserData() async {
    if (userId == null) return;
    final userData = await _userRef.get();
    if (userData.exists) {
      final data = userData.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _nameController.text = data['nama'] ?? '';
          _currentImageUrl = data['profileImageUrl'];
        });
      }
    }
  }

  // FUNGSI PILIH GAMBAR (UNIVERSAL)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Langsung baca sebagai bytes saat dipilih
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
      });
    }
  }

  // FUNGSI SIMPAN (UNIVERSAL)
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppColors.error)
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? newImageUrl = _currentImageUrl;

      // 1. Upload Gambar (Jika ada yang baru)
      if (_pickedImageBytes != null) {
        final String filePath = 'profile_pictures/$userId/profile.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(filePath);

        // putData bekerja di semua platform (Web, Android, iOS)
        // Tambahkan contentType agar browser tahu ini gambar jpeg
        await storageRef.putData(
          _pickedImageBytes!, 
          SettableMetadata(contentType: 'image/jpeg')
        );
        
        // Dapatkan URL download yang baru
        newImageUrl = await storageRef.getDownloadURL();
      }

      // 2. Update Data di Firestore
      await _userRef.update({
        'nama': _nameController.text.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    
    // Logika Tampilan Gambar:
    // 1. Jika ada gambar baru dari galeri (Bytes) -> Pakai MemoryImage
    // 2. Jika tidak, tapi ada URL dari database -> Pakai NetworkImage
    if (_pickedImageBytes != null) {
      imageProvider = MemoryImage(_pickedImageBytes!);
    } else if (_currentImageUrl != null) {
      imageProvider = NetworkImage(_currentImageUrl!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: imageProvider,
                    child: (imageProvider == null) 
                        ? Icon(Icons.person_rounded, size: 70, color: AppColors.primary) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: AppColors.textLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: InputDecoration(
                labelText: 'Email (Read only)',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}