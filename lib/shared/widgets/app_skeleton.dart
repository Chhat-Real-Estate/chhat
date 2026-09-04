import 'package:flutter/material.dart';

/// Reusable smooth pulse skeleton widget
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape,
  });

  const AppSkeleton.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = const CircleBorder();

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: ShapeDecoration(
              color: const Color(0xFFE0E0E0),
              shape: widget.shape ??
                  RoundedRectangleBorder(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton Card matching Listing card layout
class AppSkeletonListingCard extends StatelessWidget {
  const AppSkeletonListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: AppSkeleton(
              height: 180,
              width: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AppSkeleton(width: 110, height: 22),
                    AppSkeleton(width: 70, height: 22),
                  ],
                ),
                const SizedBox(height: 12),
                const AppSkeleton(width: 180, height: 16),
                const SizedBox(height: 8),
                const AppSkeleton(width: 120, height: 14),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    AppSkeleton(width: 60, height: 24),
                    SizedBox(width: 8),
                    AppSkeleton(width: 75, height: 24),
                    SizedBox(width: 8),
                    AppSkeleton(width: 65, height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton Tile matching Request / Notification item
class AppSkeletonTile extends StatelessWidget {
  const AppSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          const AppSkeleton.circular(size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeleton(width: 140, height: 16),
                SizedBox(height: 8),
                AppSkeleton(width: 200, height: 13),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AppSkeleton(width: 50, height: 24),
        ],
      ),
    );
  }
}
