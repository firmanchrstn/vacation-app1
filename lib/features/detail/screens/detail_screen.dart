import 'dart:convert'; // PENTING
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // PENTING
import 'package:wisata_application/data/models/destination_model.dart';
import 'package:wisata_application/core/theme/app_colors.dart';

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
  
  // State untuk Rencana
  bool _isInPlan = false;
  bool _isLoadingPlan = true;

  @override
  void initState() {
    super.initState();
    // Cek status rencana saat halaman dibuka
    if (widget.cameFromItinerary) {
      _isInPlan = true;
      _isLoadingPlan = false;
    } else {
      _checkIfInPlan();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- LOGIKA RENCANA ---

  Future<void> _checkIfInPlan() async {
    setState(() { _isLoadingPlan = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> planList = prefs.getStringList('itinerary') ?? [];
      
      // Cek apakah ID destinasi ini ada di daftar
      bool found = planList.any((item) {
        try {
          final map = jsonDecode(item);
          return map['id'] == widget.destination.id;
        } catch (_) { return false; }
      });

      if (mounted) {
        setState(() {
          _isInPlan = found;
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingPlan = false; });
    }
  }

  Future<void> _togglePlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> planList = prefs.getStringList('itinerary') ?? [];

      if (_isInPlan) {
        // HAPUS dari Rencana
        planList.removeWhere((item) {
          try {
            final map = jsonDecode(item);
            return map['id'] == widget.destination.id;
          } catch (_) { return false; }
        });
        await prefs.setStringList('itinerary', planList);
        
        if (mounted) {
          setState(() { _isInPlan = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Plan'), backgroundColor: AppColors.textDark),
          );
        }
      } else {
        // TAMBAH ke Rencana
        Map<String, dynamic> map = widget.destination.toMap();
        map['id'] = widget.destination.id; // Pastikan ID tersimpan
        String jsonString = jsonEncode(map);
        
        planList.add(jsonString);
        await prefs.setStringList('itinerary', planList);

        if (mounted) {
          setState(() { _isInPlan = true; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to Plan!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update plan: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // --- LOGIKA KOMENTAR (Sama seperti sebelumnya) ---
  Future<void> _postComment() async {
      // ... (Kode _postComment sama persis seperti kode final sebelumnya) ...
      // (Salin fungsi _postComment dari respons sebelumnya ke sini)
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
          if (userDoc.exists) {
            userName = (userDoc.data() as Map<String, dynamic>)['nama'] ?? 'User';
            if (userName.isEmpty) userName = 'User';
          }
          await FirebaseFirestore.instance.collection('destinasi').doc(widget.destination.id).collection('comments').add({
            'userId': user.uid, 'userName': userName, 'text': commentText, 'timestamp': FieldValue.serverTimestamp(),
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment posted!'), backgroundColor: AppColors.success));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e'), backgroundColor: AppColors.error));
        }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> commentsStream = FirebaseFirestore.instance
        .collection('destinasi').doc(widget.destination.id).collection('comments')
        .orderBy('timestamp', descending: true).snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ... (SliverAppBar sama persis seperti sebelumnya) ...
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
              title: Text(widget.destination.nama, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16, right: 16),
              background: ShaderMask(
                shaderCallback: (rect) { return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)); },
                blendMode: BlendMode.darken,
                child: Image.network(widget.destination.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: AppColors.error.withOpacity(0.2), child: const Icon(Icons.image_not_supported_rounded, color: AppColors.error, size: 80))),
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
                      // ... (Card Info & Deskripsi sama persis) ...
                       Card(
                        margin: EdgeInsets.zero,
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Row(children: [const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22), const SizedBox(width: 8), Expanded(child: Text(widget.destination.lokasi, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textDark), overflow: TextOverflow.ellipsis))])),
                              const SizedBox(width: 15),
                              Row(children: [const Icon(Icons.star_rounded, color: AppColors.accent, size: 22), const SizedBox(width: 8), Text(widget.destination.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium)]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('About Destination', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 15),
                      Text(widget.destination.deskripsi, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7, color: AppColors.textDark), textAlign: TextAlign.justify),
                      const SizedBox(height: 40),

                      // Tombol Peta
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () { /* TODO: Google Maps */ },
                          icon: const Icon(Icons.navigation_rounded, size: 24),
                          label: const Text('View on Map (Google Maps)'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- TOMBOL ADD TO PLAN (DINAMIS) ---
                      _isLoadingPlan
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _togglePlan,
                                icon: Icon(
                                  _isInPlan ? Icons.check_circle_outline_rounded : Icons.calendar_today_rounded, 
                                  color: _isInPlan ? AppColors.success : AppColors.primary
                                ),
                                label: Text(
                                  _isInPlan ? 'In Your Plan (Tap to Remove)' : 'Add to Plan', 
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: _isInPlan ? AppColors.success : AppColors.primary
                                  )
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
                                  side: BorderSide(color: _isInPlan ? AppColors.success : AppColors.primary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                      // --- AKHIR TOMBOL PLAN ---

                      // ... (Bagian Komentar & ListView.builder sama persis) ...
                      const SizedBox(height: 40),
                      const Divider(thickness: 1),
                      const SizedBox(height: 20),
                      Text('Reviews & Comments', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      
                      Row(children: [Expanded(child: TextField(controller: _commentController, decoration: InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), filled: true, fillColor: Colors.white), minLines: 1, maxLines: 3)), const SizedBox(width: 10), Container(decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: IconButton(onPressed: _postComment, icon: const Icon(Icons.send_rounded, color: Colors.white)))]),
                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: commentsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Text('Error loading comments.');
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.grey))));

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var doc = snapshot.data!.docs[index];
                              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                              Timestamp? ts = data['timestamp'] as Timestamp?;
                              String timeString = ts != null ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}" : "Just now";
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          Row(children: [const CircleAvatar(radius: 14, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 18, color: Colors.white)), const SizedBox(width: 8), Text(data['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                                          Text(timeString, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ]),
                                      const SizedBox(height: 8),
                                      Text(data['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                                    ]),
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