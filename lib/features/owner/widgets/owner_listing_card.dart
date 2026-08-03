import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';

const Color _blueDark = Color(0xFF1A237E);

class OwnerFullListingCard extends StatefulWidget {
  final ListingModel listing;
  const OwnerFullListingCard({super.key, required this.listing});

  @override
  State<OwnerFullListingCard> createState() => _OwnerFullListingCardState();
}

class _OwnerFullListingCardState extends State<OwnerFullListingCard> {
  int _currentPhoto = 0;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 240,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: widget.listing.photos.isNotEmpty
                      ? PageView.builder(
                          onPageChanged: (index) =>
                              setState(() => _currentPhoto = index),
                          itemCount: widget.listing.photos.length,
                          itemBuilder: (context, index) => Image.network(
                            widget.listing.photos[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: _blueDark));
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey, size: 50)),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.listing.active
                        ? const Color(0xFF4CAF50)
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    widget.listing.active ? 'Available' : 'Hidden / Occupied',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 4)
                    ],
                  ),
                  child:
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                ),
              ),
              if (widget.listing.photos.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        widget.listing.photos.asMap().entries.map((entry) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPhoto == entry.key ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPhoto == entry.key
                              ? Colors.white
                              : Colors.white54,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${widget.listing.rent} / month',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 6),
                          Text(
                              '${widget.listing.propertyCategory.isNotEmpty ? widget.listing.propertyCategory : 'Room'} in ${widget.listing.area}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: widget.listing.propertyKind == 'commercial'
                      ? [
                          FeatureChip(
                              icon: Icons.square_foot,
                              label: widget.listing.builtUpArea.isNotEmpty
                                  ? '${widget.listing.builtUpArea} sqft'
                                  : 'Area NA'),
                          const SizedBox(width: 8),
                          FeatureChip(
                              icon: Icons.chair_outlined,
                              label: widget.listing.furnishingStatus.isNotEmpty
                                  ? widget.listing.furnishingStatus
                                  : 'Furnishing NA'),
                          const SizedBox(width: 8),
                          FeatureChip(
                              icon: Icons.event_available_outlined,
                              label: widget.listing.availability.isNotEmpty
                                  ? widget.listing.availability
                                  : 'Immediate'),
                        ]
                      : [
                          FeatureChip(
                              icon: Icons.group_outlined,
                              label: 'Max ${widget.listing.occupancy}'),
                          const SizedBox(width: 8),
                          FeatureChip(
                              icon: Icons.person_outline,
                              label: widget.listing.genderPref.toUpperCase()),
                          const SizedBox(width: 8),
                          FeatureChip(
                              icon: Icons.event_available_outlined,
                              label: widget.listing.availability.isNotEmpty
                                  ? widget.listing.availability
                                  : 'Immediate'),
                        ],
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('listings')
                              .doc(widget.listing.id)
                              .snapshots(),
                          builder: (context, snap) {
                            final views = snap.hasData && snap.data!.exists
                                ? ((snap.data!.data()
                                        as Map<String, dynamic>?)?['views'] ??
                                    0)
                                : 0;
                            return Text('$views Views',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500));
                          },
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.mail_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('requests')
                              .where('listingId', isEqualTo: widget.listing.id)
                              .where('senderType', isEqualTo: 'owner')
                              .snapshots(),
                          builder: (context, snap) {
                            final invites = snap.data?.docs.length ?? 0;
                            return Text('$invites Invites',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500));
                          },
                        ),
                      ],
                    ),
                    Text('Posted: ${_formatDate(widget.listing.createdAt)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: _blueDark),
                        label: const Text('Edit Listing',
                            style: TextStyle(
                                color: _blueDark, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: _blueDark, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.push('/add-listing',
                            extra: widget.listing.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Delete Listing?',
                                  style: TextStyle(color: Colors.red)),
                              content: const Text(
                                  'Are you sure you want to deactivate this listing? It will no longer be visible to tenants.',
                                  style: TextStyle(color: Colors.black87)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ListingRepository().deactivateListing(
                                widget.listing.id!, widget.listing.ownerId);
                          }
                        },
                      ),
                    ),
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

class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const FeatureChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _blueDark),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A4A4A))),
        ],
      ),
    );
  }
}
