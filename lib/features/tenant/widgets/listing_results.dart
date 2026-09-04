import 'package:flutter/material.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import 'listing_card.dart';

class ListingResults extends StatefulWidget {
  final String area;
  final String filterPropertyKind;
  final String filterPropCat;
  final String filterTenantType;
  final String filterToilet;
  final RangeValues rentRange;
  final RangeValues depositRange;
  final VoidCallback? onResetFilters;

  const ListingResults({
    super.key,
    required this.area,
    required this.filterPropertyKind,
    required this.filterPropCat,
    required this.filterTenantType,
    required this.filterToilet,
    required this.rentRange,
    required this.depositRange,
    this.onResetFilters,
  });

  @override
  State<ListingResults> createState() => _ListingResultsState();
}

// Pulse Skeleton Animation
class _PulseSkeleton extends StatefulWidget {
  final Widget child;
  const _PulseSkeleton({required this.child});
  @override
  State<_PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<_PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
        child: widget.child);
  }
}

class _ListingResultsState extends State<ListingResults> {
  int _displayLimit = 10;
  late Stream<List<ListingModel>> _listingsStream;

  @override
  void initState() {
    super.initState();
    _listingsStream = ListingRepository().searchListings(
        propertyKind: widget.filterPropertyKind, search: widget.area);
  }

  @override
  void didUpdateWidget(covariant ListingResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIX: pehle stream sirf ek baar initState mein banta tha aur kabhi
    // update nahi hota tha — isliye search/kind change karne par bhi wahi
    // purana data dikhta rehta tha. Ab area ya kind badalne par naya
    // server-side query chalta hai.
    if (oldWidget.area != widget.area ||
        oldWidget.filterPropertyKind != widget.filterPropertyKind) {
      setState(() {
        _listingsStream = ListingRepository().searchListings(
            propertyKind: widget.filterPropertyKind, search: widget.area);
        _displayLimit = 10;
      });
    } else if (oldWidget.filterTenantType != widget.filterTenantType ||
        oldWidget.rentRange != widget.rentRange ||
        oldWidget.filterPropCat != widget.filterPropCat ||
        oldWidget.filterToilet != widget.filterToilet ||
        oldWidget.depositRange != widget.depositRange) {
      setState(() => _displayLimit = 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ListingModel>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // FIX: pehle hamesha "Internet check karein" bolta tha chahe
          // asli wajah kuch bhi ho (missing Firestore index, permission
          // error, etc.) — jhoothi/misleading error thi. Ab honest generic
          // message; asli reason AppLogger se already logged hai.
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                const Text('Rooms load nahi ho sake.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                const SizedBox(height: 8),
                const Text('Kuch problem aa gayi. Thodi der baad try karein.',
                    style: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB))),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _listingsStream = ListingRepository().searchListings(
                        propertyKind: widget.filterPropertyKind,
                        search: widget.area);
                  }),
                  icon: const Icon(Icons.refresh, color: Color(0xFFC62828)),
                  label: const Text('Retry',
                      style: TextStyle(color: Color(0xFFC62828))),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC62828))),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            (snapshot.data == null || snapshot.data!.isEmpty)) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => _PulseSkeleton(
              child: Container(
                height: 280,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 180,
                              height: 24,
                              color: Colors.grey.shade200),
                          const SizedBox(height: 8),
                          Container(
                              width: 120,
                              height: 16,
                              color: Colors.grey.shade200),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        var listings = snapshot.data ?? [];

        // NOTE: search (searchKeywords) aur propertyKind ab server-side
        // (ListingRepository.searchListings) filter hote hain — yahan client
        // side dobara filter karne ki zaroorat nahi. `search` sirf empty-state
        // message ke liye rakha hai.
        final search = widget.area.toLowerCase().trim();

        // PROPERTY CATEGORY FILTER
        if (widget.filterPropCat.isNotEmpty) {
          listings = listings
              .where((l) => l.propertyCategory == widget.filterPropCat)
              .toList();
        }

        // TENANT TYPE / SUITABLE FOR FILTER
        if (widget.filterTenantType.isNotEmpty) {
          listings = listings
              .where((l) =>
                  l.allowedTenants.contains(widget.filterTenantType) ||
                  l.suitableFor.contains(widget.filterTenantType))
              .toList();
        }

        // TOILET TYPE FILTER
        if (widget.filterToilet.isNotEmpty) {
          listings = listings
              .where((l) => l.facilities.contains(widget.filterToilet))
              .toList();
        }

        // RENT + DEPOSIT RANGE FILTER — sirf tab lagao jab user ne explicitly change kiya ho
        final rentFiltered =
            widget.rentRange.start > 0 || widget.rentRange.end < 1000000;
        final depositFiltered =
            widget.depositRange.start > 0 || widget.depositRange.end < 1000000;
        if (rentFiltered) {
          listings = listings
              .where((l) =>
                  l.rent >= widget.rentRange.start &&
                  l.rent <= widget.rentRange.end)
              .toList();
        }
        if (depositFiltered) {
          listings = listings
              .where((l) =>
                  l.deposit >= widget.depositRange.start &&
                  l.deposit <= widget.depositRange.end)
              .toList();
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off,
                    size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text(
                  search.isNotEmpty
                      ? '"$search" ke liye koi room nahi mila'
                      : 'Koi room available nahi hai',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Filters hata ke dekho, ya koi doosra area search karo',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
                if (widget.onResetFilters != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: widget.onResetFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('Clear Filters'),
                  ),
                ]
              ],
            ),
          );
        }

        final displayedList = listings.take(_displayLimit).toList();
        final hasMore = listings.length > _displayLimit;

        // NAYA: Active filters ko chips ke roop me top pe dikhao — user ko
        // pata rahe konse filters lage hain, bina panel dobara khole.
        final activeChips = <String>[
          if (widget.filterPropCat.isNotEmpty) widget.filterPropCat,
          if (widget.filterTenantType.isNotEmpty) widget.filterTenantType,
          if (widget.filterToilet.isNotEmpty) widget.filterToilet,
          if (rentFiltered) 'Budget',
          if (depositFiltered) 'Deposit',
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeChips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeChips
                      .map((c) => Chip(
                            label: Text(c,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white)),
                            backgroundColor: const Color(0xFFC62828),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('${listings.length} rooms mile',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayedList.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedList.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _displayLimit += 5),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC62828)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          child: const Text('Load More Rooms',
                              style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }
                  return TenantListingCard(listing: displayedList[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
