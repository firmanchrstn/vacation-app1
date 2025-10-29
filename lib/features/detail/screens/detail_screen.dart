import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisata_application/data/models/destination_model.dart'; // Assuming destination_model.dart exists
import 'package:wisata_application/core/theme/app_colors.dart'; // Assuming app_colors.dart exists

class DetailScreen extends StatefulWidget {
  final DestinationModel destination;
  final bool cameFromItinerary; // Flag received

  const DetailScreen({
    super.key,
    required this.destination,
    this.cameFromItinerary = false, // Default false
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isInItinerary = false;
  bool _isLoadingCheck = true;

  @override
  void initState() {
    super.initState();
    if (widget.cameFromItinerary) {
      _isInItinerary = true;
      _isLoadingCheck = false;
    } else {
      _checkIfInItinerary();
    }
  }

  Future<void> _checkIfInItinerary() async {
    if(!mounted) return;
    setState(() { _isLoadingCheck = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> itineraryJsonList = prefs.getStringList('itinerary') ?? [];
      bool found = false;
      for (String jsonItem in itineraryJsonList) {
        try {
          Map<String, dynamic> itemMap = jsonDecode(jsonItem);
          if (itemMap['id'] == widget.destination.id) {
            found = true;
            break;
          }
        } catch (e) {
          print("Error decoding item while checking itinerary: $e");
         }
      }
      if (mounted) {
        setState(() {
          _isInItinerary = found;
          _isLoadingCheck = false;
        });
      }
    } catch (e) {
      print("Error checking itinerary: $e");
      if (mounted) { setState(() { _isLoadingCheck = false; }); }
    }
  }


  Future<void> _addToItinerary(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> itineraryJsonList = prefs.getStringList('itinerary') ?? [];
      final Map<String, dynamic> destinationMap = widget.destination.toMap();
      destinationMap['id'] = widget.destination.id;
      final String destinationJson = jsonEncode(destinationMap);

      if (!_isInItinerary) {
        itineraryJsonList.add(destinationJson);
        await prefs.setStringList('itinerary', itineraryJsonList);
        if (mounted) {
           // --- TRANSLATED ---
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.destination.nama} added to plan!'), backgroundColor: AppColors.success));
           setState(() { _isInItinerary = true; });
        }
      } else {
         if (mounted) {
            // --- TRANSLATED ---
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.destination.nama} is already in the plan.'), backgroundColor: AppColors.accent.withOpacity(0.8)));
         }
      }
    } catch (e) {
      if(mounted) {
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save plan: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _removeFromItinerary(BuildContext context) async {
     try {
      final prefs = await SharedPreferences.getInstance();
      List<String> itineraryJsonList = prefs.getStringList('itinerary') ?? [];

      itineraryJsonList.removeWhere((jsonItem) {
         try { Map<String, dynamic> itemMap = jsonDecode(jsonItem); return itemMap['id'] == widget.destination.id; }
         catch(e) { return false; }
      });

      await prefs.setStringList('itinerary', itineraryJsonList);

      if(mounted){
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from plan.'), backgroundColor: AppColors.success));
        setState(() { _isInItinerary = false; });
      }

    } catch (e) {
      if(mounted) {
        // --- TRANSLATED ---
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove item: $e'), backgroundColor: AppColors.error));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380.0,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 2,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
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
                widget.destination.nama, // Keep name as is (proper noun)
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16, right: 16),
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
                  widget.destination.imageUrl,
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
                      Card( // Info Card
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
                                    Expanded(child: Text(widget.destination.lokasi, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                                  const SizedBox(width: 8),
                                  Text(widget.destination.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- TRANSLATED ---
                      Text('About the Destination', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 15),
                      Text(
                        widget.destination.deskripsi, // Keep description as is (content)
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppColors.textDark),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // --- TRANSLATED ---
                            print("View on Map button clicked");
                            // TODO: Implement Google Maps integration
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 24),
                          // --- TRANSLATED ---
                          label: const Text('View on Map (Google Maps)'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Conditional Itinerary Button
                      _isLoadingCheck
                          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator(color: AppColors.primary)))
                          : widget.cameFromItinerary
                              ? SizedBox( // Show Remove button only
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _removeFromItinerary(context),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 24, color: AppColors.error),
                                    // --- TRANSLATED ---
                                    label: Text('Remove from Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.error)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                      side: const BorderSide(color: AppColors.error, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                )
                              : _isInItinerary
                                  ? SizedBox( // Show Remove button (already added)
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _removeFromItinerary(context),
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 24, color: AppColors.success),
                                        // --- TRANSLATED ---
                                        label: Text('Remove from Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.success)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                          side: const BorderSide(color: AppColors.success, width: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    )
                                  : SizedBox( // Show Add button
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _addToItinerary(context),
                                        icon: const Icon(Icons.calendar_today_rounded, size: 24, color: AppColors.primary),
                                        // --- TRANSLATED ---
                                        label: Text('Add to Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
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