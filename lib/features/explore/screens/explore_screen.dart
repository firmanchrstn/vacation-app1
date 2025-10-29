import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisata_application/data/models/destination_model.dart'; // Assuming destination_model.dart exists
import 'package:wisata_application/features/detail/screens/detail_screen.dart'; // Assuming detail_screen.dart exists
import 'package:wisata_application/core/theme/app_colors.dart'; // Assuming app_colors.dart exists

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
    setState(() { _searchQuery = _searchController.text; });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Firestore query remains the same
    Query destinasiQuery = FirebaseFirestore.instance.collection('destinasi');

    if (_searchQuery.isNotEmpty) {
      destinasiQuery = destinasiQuery
          .where('nama', isGreaterThanOrEqualTo: _searchQuery)
          .where('nama', isLessThan: _searchQuery + 'z');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // --- TRANSLATED ---
        title: Text('Explore Destinations', style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                // --- TRANSLATED ---
                hintText: 'Search destination name...',
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            // --- TRANSLATED ---
            return Center(child: Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error)));
          }
          if (snapshot.data!.docs.isEmpty) {
            // --- TRANSLATED ---
            return Center(child: Text('Destination not found.', style: Theme.of(context).textTheme.bodyLarge));
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

  // Helper widget to build each destination tile in the list
  Widget _buildDestinasiTile(BuildContext context, DestinationModel destination) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to DetailScreen, assuming DetailScreen is also translated or uses localization
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailScreen(destination: destination)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  destination.imageUrl,
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => Container(width: 80, height: 80, color: AppColors.textMedium.withOpacity(0.1), child: const Icon(Icons.broken_image_rounded, color: AppColors.textMedium, size: 40)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination.nama, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis), // Keep name as is
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textMedium),
                      const SizedBox(width: 5),
                      Expanded(child: Text(destination.lokasi, style: Theme.of(context).textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)), // Keep location as is
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