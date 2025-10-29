import 'package:flutter/material.dart';
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

class DetailScreen extends StatelessWidget {
  final DestinationModel destination; 

  const DetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380.0,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0), // Padding SUDAH ADA
              child: CircleAvatar(
                backgroundColor: AppColors.textLight.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                destination.nama,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textLight),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
              background: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.darken,
                child: Image.network(
                  destination.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.error.withOpacity(0.2),
                    child: const Icon(Icons.image_not_supported_rounded, color: AppColors.error, size: 80),
                  ),
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(destination.lokasi, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                                  const SizedBox(width: 8),
                                  Text(destination.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text('Tentang Destinasi', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 15),
                      Text(
                        destination.deskripsi, 
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppColors.textDark), 
                        textAlign: TextAlign.justify,
                      ),
                      
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () { // onPressed SUDAH ADA
                            print("Tombol Petunjuk Arah diklik"); 
                          }, 
                          icon: const Icon(Icons.navigation_rounded, size: 24),
                          label: const Text('Lihat di Peta (Google Maps)'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () { // onPressed SUDAH ADA
                            print("Tombol Tambah ke Rencana diklik"); 
                          }, 
                          icon: const Icon(Icons.calendar_today_rounded, size: 24, color: AppColors.primary),
                          label: Text('Tambahkan ke Rencana', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                            side: const BorderSide(color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}