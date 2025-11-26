import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 1. IMPORT URL_LAUNCHER
import 'package:url_launcher/url_launcher.dart'; 

class DetailScreen extends StatefulWidget {
  final DestinationModel destination;
  final bool cameFromItinerary;

  const DetailScreen({
    super.key,
    required this.destination,
    this.cameFromItinerary = false,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController = TextEditingController();
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- FUNGSI GOOGLE MAPS (BARU) ---
  Future<void> _launchMaps() async {
    // Kita cari berdasarkan "Nama Tempat, Lokasi"
    // Contoh query: "Raja Ampat, Papua Barat"
    final String query = '${widget.destination.nama}, ${widget.destination.lokasi}';
    
    // Encode agar aman untuk URL (spasi jadi %20, dll)
    final String encodedQuery = Uri.encodeComponent(query);
    
    // Buat URL Google Maps Universal (Web & App)
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedQuery");

    try {
      // Coba buka (mode externalApplication memaksa buka di app maps jika ada)
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
  // --- AKHIR FUNGSI GOOGLE MAPS ---

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
        } catch (e) { /* ignore */ }
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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to plan!'), backgroundColor: AppColors.success));
           setState(() { _isInItinerary = true; });
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already in your plan.'), backgroundColor: AppColors.accent.withOpacity(0.8)));
         }
      }
    } catch (e) {
      if(mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from plan.'), backgroundColor: AppColors.success));
        setState(() { _isInItinerary = false; });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove item: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post a comment'), backgroundColor: AppColors.error));
      return;
    }
    if (_commentController.text.trim().isEmpty) return;
    final String commentText = _commentController.text.trim();
    _commentController.clear(); 
    FocusScope.of(context).unfocus(); 

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userName = 'User';
      String? userPhoto;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        userName = data['nama'] ?? 'User';
        userPhoto = data['profileImageUrl'];
      }

      await FirebaseFirestore.instance
          .collection('destinasi')
          .doc(widget.destination.id)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'text': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment posted!'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> commentsStream = FirebaseFirestore.instance
        .collection('destinasi')
        .doc(widget.destination.id)
        .collection('comments')
        .orderBy('timestamp', descending: true) 
        .snapshots();

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
                widget.destination.nama,
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

                      Text('About the Destination', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 15),
                      Text(
                        widget.destination.deskripsi, 
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppColors.textDark), 
                        textAlign: TextAlign.justify,
                      ),
                      
                      const SizedBox(height: 40),
                      // --- TOMBOL PETA (SUDAH DIHUBUNGKAN) ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _launchMaps, // Panggil fungsi _launchMaps
                          icon: const Icon(Icons.navigation_rounded, size: 24),
                          label: const Text('View on Map (Google Maps)'),
                        ),
                      ),
                      // ----------------------------------------

                      const SizedBox(height: 20),
                      
                      // Tombol Add to Plan (Kondisional)
                      _isLoadingCheck
                          ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator(color: AppColors.primary)))
                          : widget.cameFromItinerary
                              ? SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _removeFromItinerary(context),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 24, color: AppColors.error),
                                    label: Text('Remove from Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.error)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                      side: const BorderSide(color: AppColors.error, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                )
                              : _isInItinerary
                                  ? SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _removeFromItinerary(context),
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 24, color: AppColors.success),
                                        label: Text('Remove from Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.success)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                          side: const BorderSide(color: AppColors.success, width: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _addToItinerary(context),
                                        icon: const Icon(Icons.calendar_today_rounded, size: 24, color: AppColors.primary),
                                        label: Text('Add to Plan', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                          side: const BorderSide(color: AppColors.primary, width: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),

                      // Section Komentar
                      const SizedBox(height: 40),
                      const Divider(thickness: 1),
                      const SizedBox(height: 20),
                      Text('Reviews & Comments', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Write your experience...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: _postComment,
                            icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 30),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: commentsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Something went wrong loading comments.');
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey))),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var doc = snapshot.data!.docs[index];
                              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                              Timestamp? ts = data['timestamp'] as Timestamp?;
                              String timeString = ts != null 
                                  ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}" 
                                  : "Just now";
                              String? userPhoto = data['userPhoto'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.grey,
                                                backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
                                                child: userPhoto == null ? Icon(Icons.person, size: 18, color: Colors.white) : null,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                data['userName'] ?? 'Anonymous',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          Text(timeString, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(fontSize: 14, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
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