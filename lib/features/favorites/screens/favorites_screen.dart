import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisata_application/core/theme/app_colors.dart'; // Assuming app_colors.dart exists
// Import the data model
import 'package:wisata_application/data/models/destination_model.dart'; // Assuming destination_model.dart exists
import 'package:wisata_application/features/detail/screens/detail_screen.dart'; // Assuming detail_screen.dart exists

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // --- TRANSLATED ---
    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('My Favorites', style: Theme.of(context).textTheme.titleLarge)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 100, color: AppColors.textMedium.withOpacity(0.5)),
                const SizedBox(height: 30),
                Text('You Are Not Logged In', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 15),
                Text(
                  'Sign in to save and view your favorite destinations.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Stream<QuerySnapshot> favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      // --- TRANSLATED ---
      appBar: AppBar(title: Text('My Favorites', style: Theme.of(context).textTheme.titleLarge)),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            // --- TRANSLATED ---
            return Center(child: Text('Error loading favorites: ${snapshot.error}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error)));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_outline_rounded, size: 100, color: AppColors.textMedium.withOpacity(0.5)),
                    const SizedBox(height: 30),
                    // --- TRANSLATED ---
                    Text('No Favorites Yet', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 15),
                    // --- TRANSLATED ---
                    Text(
                      'Add destinations you like so you can easily find them here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      // --- TRANSLATED ---
                      child: ElevatedButton.icon(onPressed: () {
                        // Navigate to Explore tab (index 1)
                        final TabController? tabController = DefaultTabController.of(context);
                         if (tabController != null && tabController.index != 1) {
                           tabController.animateTo(1);
                         }
                       }, icon: const Icon(Icons.explore_rounded), label: const Text('Start Exploring')),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              // Create model before navigation
              final DestinationModel destination = DestinationModel.fromMap(doc.id, data);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Navigate using the created model
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(destination: destination)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            data['imageUrl'] ?? 'https://via.placeholder.com/50',
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (context, url, error) => const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['nama'] ?? 'No Name', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis), // Keep name as is
                              const SizedBox(height: 5),
                              Row(children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMedium),
                                const SizedBox(width: 5),
                                Expanded(child: Text(data['lokasi'] ?? 'No Location', style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)) // Keep location as is
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 28),
                          onPressed: () {
                            doc.reference.delete().then((_) {
                              // --- TRANSLATED ---
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destination removed from favorites.'), backgroundColor: AppColors.success));
                            }).catchError((e) {
                              // --- TRANSLATED ---
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.error));
                            });
                          },
                          // --- TRANSLATED ---
                          tooltip: 'Remove from Favorites',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}