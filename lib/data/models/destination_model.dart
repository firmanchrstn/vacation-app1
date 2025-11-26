class DestinationModel {
  final String id;
  final String nama;
  final String lokasi;
  final double rating;
  final String imageUrl;
  final String deskripsi;
  // --- TAMBAHAN KOORDINAT ---
  final double lat;
  final double lng;

  DestinationModel({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.rating,
    required this.imageUrl,
    required this.deskripsi,
    // Default 0.0 jika data belum ada di Firestore
    this.lat = 0.0, 
    this.lng = 0.0,
  });

  factory DestinationModel.fromMap(String id, Map<String, dynamic> map) {
    return DestinationModel(
      id: id,
      nama: map['nama'] ?? 'Tidak Ada Nama',
      lokasi: map['lokasi'] ?? 'Tidak Ada Lokasi',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0, 
      imageUrl: map['imageUrl'] ?? 'https://via.placeholder.com/400x300',
      deskripsi: map['deskripsi'] ?? 'Deskripsi belum tersedia.',
      // Ambil lat & lng dari Firestore
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'lokasi': lokasi,
      'rating': rating,
      'imageUrl': imageUrl,
      'deskripsi': deskripsi,
      'lat': lat,
      'lng': lng,
    };
  }
}