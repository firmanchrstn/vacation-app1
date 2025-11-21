import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/features/detail/screens/detail_screen.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  List<DestinationModel> _itineraryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    setState(() { _isLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> itineraryJsonList = prefs.getStringList('itinerary') ?? [];
      final List<DestinationModel> loadedItems = [];

      for (String jsonItem in itineraryJsonList) {
        try {
          Map<String, dynamic> itemMap = jsonDecode(jsonItem);
          loadedItems.add(DestinationModel.fromMap(itemMap['id'] ?? 'unknown', itemMap));
        } catch (e) {
          debugPrint("Error decoding item: $e");
        }
      }
      if (mounted) {
        setState(() {
          _itineraryItems = loadedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _removeItem(String destinationId) async {
     try {
      final prefs = await SharedPreferences.getInstance();
      List<String> itineraryJsonList = prefs.getStringList('itinerary') ?? [];
      
      itineraryJsonList.removeWhere((jsonItem) {
         try {
           Map<String, dynamic> itemMap = jsonDecode(jsonItem);
           return itemMap['id'] == destinationId;
         } catch(e) { return false; }
      });

      await prefs.setStringList('itinerary', itineraryJsonList);
      _loadItinerary(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from plan.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) { /* Error */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Travel Plan', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _itineraryItems.isEmpty
            ? Center(child: Text("No plans yet", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _itineraryItems.length,
                itemBuilder: (context, index) {
                  final destination = _itineraryItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(destination.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      title: Text(destination.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(destination.lokasi),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        onPressed: () => _removeItem(destination.id),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              destination: destination,
                              cameFromItinerary: true, 
                            ),
                          ),
                        ).then((_) => _loadItinerary());
                      },
                    ),
                  );
                },
              ),
    );
  }
}