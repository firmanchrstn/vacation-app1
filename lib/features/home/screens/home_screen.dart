import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/features/detail/screens/detail_screen.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- FUNGSI TOGGLE FAVORITE ---
  Future<void> _toggleFavorite(
      bool isFavorite,
      Map<String, dynamic> destinasiData,
      String documentId,
      BuildContext context) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to manage favorites'), backgroundColor: AppColors.error),
      );
      return;
    }

    final DocumentReference favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(documentId);

    try {
      if (isFavorite) {
        // Hapus (Unlike)
        await favoriteRef.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites'), backgroundColor: AppColors.textDark),
          );
        }
      } else {
        // Tambah (Like)
        await favoriteRef.set(destinasiData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _getFirstLetter(String? name) {
    if (name != null && name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    return '?';
  }

  void _navigateToExploreTab(BuildContext context) {
    final TabController? tabController = DefaultTabController.of(context);
    if (tabController != null && tabController.index != 1) {
      tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Stream Destinasi
    final Stream<QuerySnapshot> destinasiStream =
        FirebaseFirestore.instance.collection('destinasi').snapshots();
        
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final DocumentReference? userRef = userId != null 
        ? FirebaseFirestore.instance.collection('users').doc(userId) 
        : null;

    // 2. Stream Favorit (untuk cek status)
    final Stream<QuerySnapshot>? favoritesStream = userId != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .snapshots()
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 0, right: 24),
              background: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: userRef?.snapshots(), 
                      builder: (context, snapshot) {
                        String userName = 'Adventurer';
                        String firstLetter = '?';
                        String? profileImageUrl;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final nameFromDb = data?['nama'] as String?;
                          profileImageUrl = data?['profileImageUrl'] as String?;
                          if (nameFromDb != null && nameFromDb.trim().isNotEmpty) {
                            userName = nameFromDb.trim();
                            firstLetter = _getFirstLetter(userName);
                          }
                        } else if (userId == null) {
                           userName = 'Guest';
                           firstLetter = 'G';
                        }
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hello, $userName!', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textDark)),
                            InkWell(
                              onTap: () {
                                final TabController? tabController = DefaultTabController.of(context);
                                if (tabController != null && tabController.index != 3) {
                                  tabController.animateTo(3);
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withOpacity(0.8),
                                backgroundImage: (profileImageUrl != null)
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child: (profileImageUrl == null)
                                    ? Text(
                                        firstLetter,
                                        style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    Text('Find Your Dream Destination', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search destinations...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: const Icon(Icons.mic_none_rounded, color: AppColors.textMedium),
                    filled: true,
                    fillColor: AppColors.textLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildSectionTitle(
                    context, 
                    'Featured Destinations', 
                    () => _navigateToExploreTab(context)
                  ),
                  const SizedBox(height: 15),
                  
                  // --- NESTED STREAM BUILDER UNTUK CEK FAVORIT ---
                  SizedBox(
                    height: 280,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: favoritesStream, // 1. Dengarkan Favorit
                      builder: (context, favSnapshot) {
                        Set<String> favoriteIds = {};
                        if (favSnapshot.hasData) {
                          favoriteIds = favSnapshot.data!.docs.map((doc) => doc.id).toSet();
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: destinasiStream, // 2. Dengarkan Destinasi
                          builder: (context, destSnapshot) {
                            if (destSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: AppColors.primary));
                            }
                            if (destSnapshot.hasError) {
                              return Center(child: Text('Failed to load data', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error)));
                            }
                            if (destSnapshot.data!.docs.isEmpty) {
                              return Center(child: Text('No destinations yet', style: Theme.of(context).textTheme.bodyLarge));
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: destSnapshot.data!.docs.length,
                              itemBuilder: (context, index) { 
                                var doc = destSnapshot.data!.docs[index];
                                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                
                                // Cek apakah di-favoritkan
                                bool isFavorite = favoriteIds.contains(doc.id);

                                return _buildRecommendationCard(
                                  context, 
                                  data, 
                                  doc.id, 
                                  isFavorite // Kirim status
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // ---------------------------------------------
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    Map<String, dynamic> data,
    String documentId,
    bool isFavorite, // Terima status favorit
  ) {
    final DestinationModel destination = DestinationModel.fromMap(documentId, data);
    final String title = destination.nama;
    final String location = destination.lokasi;
    final String rating = destination.rating.toStringAsFixed(1);
    final String imageUrl = destination.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(destination: destination)));
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network( 
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(height: 160, width: double.infinity, color: Colors.grey[200], child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(height: 160, width: double.infinity, color: AppColors.error.withOpacity(0.1), child: const Icon(Icons.broken_image_rounded, color: AppColors.error));
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.85), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(rating, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textLight)),
                      ],
                    ),
                  ),
                ),
                
                // --- TOMBOL FAVORIT DINAMIS ---
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), 
                      shape: BoxShape.circle, 
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]
                    ),
                    child: IconButton(
                      // Ikon berubah warna dan bentuk
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                        color: isFavorite ? Colors.red : Colors.redAccent, 
                      ),
                      onPressed: () { 
                        _toggleFavorite(isFavorite, data, documentId, context); 
                      },
                      tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                    ),
                  ),
                ),
                // -----------------------------
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 6),
                    Expanded(child: Text(location, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}