import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Warna dasar abu-abu
      highlightColor: Colors.grey[100]!, // Warna kilauan putih
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Warna ini wajib ada agar shimmer terlihat
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}