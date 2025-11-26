import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/features/detail/screens/detail_screen.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
import 'package:wisata_application/core/widgets/app_shimmer.dart'; // Import Shimmer

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String text = _searchController.text;
    if (text.length >= 3) {
      // Kapitalisasi huruf pertama agar cocok dengan data Firestore
      setState(() { _searchQuery = text[0].toUpperCase() + text.substring(1); });
    } else {
      if (_searchQuery.isNotEmpty) setState(() { _searchQuery = ''; });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query destinasiQuery = FirebaseFirestore.instance.collection('destinasi');

    if (_searchQuery.isNotEmpty) {
      // --- PERBAIKAN DI SINI ---
      destinasiQuery = destinasiQuery
          .where('nama', isGreaterThanOrEqualTo: _searchQuery)
          .where('nama', isLessThan: '${_searchQuery}z'); // Gunakan kurung kurawal {}
      // -------------------------
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Explore Destinations', style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Search (min. 3 letters)...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: destinasiQuery.snapshots(),
        builder: (context, snapshot) {
          // --- SHIMMER LOADING LIST ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              itemCount: 6, 
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  height: 100,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const AppShimmer(width: 80, height: 80, borderRadius: 12),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppShimmer(width: 150, height: 18, borderRadius: 4),
                            const SizedBox(height: 8),
                            const AppShimmer(width: 100, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error)));
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? 'No destinations found for "$_searchQuery"'
                        : 'No destinations available.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              final DestinationModel destination = DestinationModel.fromMap(doc.id, data);
              return _buildDestinasiTile(context, destination);
            },
          );
        },
      ),
    );
  }

  Widget _buildDestinasiTile(BuildContext context, DestinationModel destination) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(destination: destination)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Hero(
                  tag: destination.imageUrl,
                  child: Image.network(
                    destination.imageUrl,
                    width: 80, height: 80, fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const AppShimmer(width: 80, height: 80, borderRadius: 0);
                    },
                    errorBuilder: (context, url, error) => Container(width: 80, height: 80, color: AppColors.textMedium.withOpacity(0.1), child: const Icon(Icons.broken_image_rounded, color: AppColors.textMedium, size: 40)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination.nama, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMedium),
                      const SizedBox(width: 5),
                      Expanded(child: Text(destination.lokasi, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 5),
                Text(destination.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelLarge),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}