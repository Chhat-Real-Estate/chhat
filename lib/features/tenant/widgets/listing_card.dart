import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../listings/models/listing_model.dart';

const Color _cardColor = Colors.white;
const Color _neonAccent = Color(0xFFC62828); // Cherry Red

class TenantListingCard extends StatelessWidget {
  final ListingModel listing;
  const TenantListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/room-detail', extra: listing),
      child: Container(
        height: 280,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: _cardColor,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: listing.photos.isNotEmpty
                  ? Image.network(
                      listing.photos.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (ctx, err, st) => Container(
                          color: _cardColor,
                          child: const Center(
                              child: Icon(Icons.home,
                                  size: 64, color: _neonAccent))),
                    )
                  : Container(
                      color: _cardColor,
                      child: const Center(
                          child:
                              Icon(Icons.home, size: 64, color: _neonAccent))),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (listing.propertyKind == 'commercial'
                                      ? listing.propertyCategory
                                      : listing.roomType)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: _neonAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(listing.area,
                                    style:
                                        TextStyle(color: Colors.grey.shade300)),
                              ],
                            ),
                          ],
                        ),
                        Text('₹${listing.rent}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: listing.propertyKind == 'commercial'
                          ? [
                              DarkInfoChip(
                                  icon: Icons.square_foot,
                                  label: listing.builtUpArea.isNotEmpty
                                      ? '${listing.builtUpArea} sqft'
                                      : 'Area NA'),
                              const SizedBox(width: 8),
                              DarkInfoChip(
                                  icon: Icons.chair_outlined,
                                  label: listing.furnishingStatus.isNotEmpty
                                      ? listing.furnishingStatus
                                      : 'Furnishing NA'),
                            ]
                          : [
                              DarkInfoChip(
                                  icon: Icons.wc, label: listing.toiletType),
                              const SizedBox(width: 8),
                              DarkInfoChip(
                                  icon: Icons.person,
                                  label: listing.genderPref == 'any'
                                      ? 'All Allowed'
                                      : (listing.genderPref == 'male'
                                          ? 'Bachelors'
                                          : 'Girls Only')),
                            ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bookmark_border,
                    color: _neonAccent, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DarkInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const DarkInfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neonAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _neonAccent),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class EmptySearch extends StatelessWidget {
  const EmptySearch({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city_outlined,
              size: 80, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text(
            'Apna area type karo upar',
            style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
          ),
          SizedBox(height: 8),
          Text(
            'Dharavi, Kurla, Sion, Wadala...',
            style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }
}
