import 'package:flutter/material.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Rencana Perjalanan', style: Theme.of(context).textTheme.titleLarge)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, size: 100, color: AppColors.secondary.withOpacity(0.6)),
              const SizedBox(height: 30),
              Text('Susun Petualangan Anda', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              Text('Belum ada rencana perjalanan. Mulai jelajahi destinasi dan tambahkan ke rencana Anda!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMedium)),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { /* TODO: Navigasi ke Jelajah */ }, icon: Icon(Icons.search), label: const Text('Mulai Rencanakan Sekarang'))),
            ],
          ),
        ),
      ),
    );
  }
}