import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../util/constants.dart';

class ShimmerContent extends StatelessWidget {

  final double width;

  const ShimmerContent({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: shimmerHeight,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.all(9.0),
            child: Row(
              children: [
                Expanded(child: Container(height: 300, color: Colors.white)),
              ],
            ),
          ),
        ),
      )
    );
  }
}