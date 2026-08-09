import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../features/listings/repositories/listing_repository.dart';
import '../../../features/listings/models/listing_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For User ID
import 'package:cloud_firestore/cloud_firestore.dart'; // For Smart Filter Data Fetching
import 'tenant_profile_tab.dart'; // NAYA: Extracted tab import
import 'tenant_requests_screen.dart'; // NAYA: Extracted requests import
import '../../profile/screens/profile_screen.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

// --- Clean White & Cherry Red Theme ---
const Color _bgColor = Color(0xFFF5F7F2); // Light Greyish White
const Color _cardColor = Colors.white;
const Color _cherryRed = Color(0xFFC62828);
const Color _cherryLight = Color(0xFFEF5350);
const Color _neonAccent = Color(
    0xFFC62828); // FIX: Purane errors hatane ke liye Cherry Red par map kiya

class _MapExploreScreenState extends State<MapExploreScreen> {
  int _currentIndex = 0;

  // FIX: 'final' hata kar 'get' lagaya taaki setState aur tab index change kar sakein
  List<Widget> get _pages => [
        const _ExplorePage(),
        const TenantProfileTab(), // FIX: Ab ye code nayi file se load hoga
        const TenantRequestsScreen(), // FIX: Ab ye code nayi file se load hoga
        ProfileScreen(
          onBack: () {
            setState(() {
              _currentIndex = 0; // FIX: Variable name corrected
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_cherryRed, _cherryLight]),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Find Room',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_ind_outlined),
              activeIcon: Icon(Icons.assignment_ind),
              label: 'My Info',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ), // FIX: Container ka bracket
    ); // FIX: Scaffold ka bracket
  }
}

// Page 1 — Explore
class _ExplorePage extends StatefulWidget {
  const _ExplorePage();

  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  final _searchController = TextEditingController();
  String _searchArea = '';
  Timer?
      _searchDebounce; // NAYA: search debounce — har keystroke pe query na chale

  // Advanced Filters
  String _filterPropCat = '';
  String _filterTenantType = '';
  String _filterToilet = '';
  RangeValues _rentRange = const RangeValues(1000, 30000);
  RangeValues _depositRange = const RangeValues(0, 100000);
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadTenantSmartFilters();
  }

  // NAYA: Smart Home Page Auto-Filter Logic
  Future<void> _loadTenantSmartFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('tenantProfiles')
          .doc(userId)
          .get();

      // FIX: Check if widget is still in the tree before calling setState
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          final reqs = List<String>.from(data['propertyRequirements'] ?? []);
          if (reqs.isNotEmpty) _filterPropCat = reqs.first;

          final tType = data['tenantType'] as String?;
          if (tType != null && tType.isNotEmpty) _filterTenantType = tType;

          final budget = data['budgetRange'] as String?;
          if (budget == 'Below ₹5,000')
            _rentRange = const RangeValues(1000, 5000);
          else if (budget == '₹5,000 - ₹10,000')
            _rentRange = const RangeValues(5000, 10000);
          else if (budget == '₹10,000 - ₹15,000')
            _rentRange = const RangeValues(10000, 15000);
          else if (budget == '₹15,000 - ₹20,000')
            _rentRange = const RangeValues(15000, 20000);
          else if (budget == 'Above ₹20,000')
            _rentRange = const RangeValues(20000, 30000);
        });
      }
    } catch (e) {
      debugPrint("Smart Filter Error: $e");
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Simple Top Search Bar with Filter Icon
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'City, Area, Sub-area likho...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: _cherryRed),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchArea = '');
                                })
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _cherryRed)),
                      ),
                      onChanged: (val) {
                        if (_searchDebounce?.isActive ?? false) {
                          _searchDebounce!.cancel();
                        }
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 400), () {
                          if (mounted) {
                            setState(() => _searchArea = val.trim());
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _cherryRed,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          _showFilters ? Icons.filter_list_off : Icons.tune,
                          color: Colors.white,
                          size: 24),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            if (_showFilters)
              _FilterPanel(
                initialPropCat: _filterPropCat,
                initialTenantType: _filterTenantType,
                initialToilet: _filterToilet,
                initialRentRange: _rentRange,
                initialDepositRange: _depositRange,
                onApply: (propCat, tenantType, toilet, rent, deposit) {
                  setState(() {
                    _filterPropCat = propCat;
                    _filterTenantType = tenantType;
                    _filterToilet = toilet;
                    _rentRange = rent;
                    _depositRange = deposit;
                    _showFilters = false; // Apply dabate hi filter chhup jayega
                  });
                },
              ),

            // Results
            Expanded(
              child: _searchArea.isEmpty
                  ? const _EmptySearch()
                  : _ListingResults(
                      area: _searchArea,
                      filterPropCat: _filterPropCat,
                      filterTenantType: _filterTenantType,
                      filterToilet: _filterToilet,
                      rentRange: _rentRange,
                      depositRange: _depositRange,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Panel (Stateful with Apply Button)
class _FilterPanel extends StatefulWidget {
  final String initialPropCat;
  final String initialTenantType;
  final String initialToilet;
  final RangeValues initialRentRange;
  final RangeValues initialDepositRange;
  final Function(String, String, String, RangeValues, RangeValues) onApply;

  const _FilterPanel({
    required this.initialPropCat,
    required this.initialTenantType,
    required this.initialToilet,
    required this.initialRentRange,
    required this.initialDepositRange,
    required this.onApply,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late String _propCat;
  late String _tenantType;
  late String _toilet;
  late RangeValues _rentRange;
  late RangeValues _depositRange;

  @override
  void initState() {
    super.initState();
    _propCat = widget.initialPropCat;
    _tenantType = widget.initialTenantType;
    _toilet = widget.initialToilet;
    _rentRange = widget.initialRentRange;
    _depositRange = widget.initialDepositRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      constraints: const BoxConstraints(maxHeight: 450),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _FilterChips(
                      options: const [
                        '1RK',
                        '1BHK',
                        'Chawl Room',
                        'PG Bed',
                        'Slum Room',
                        'SRA Flat',
                        'Shared Room'
                      ],
                      selected: _propCat,
                      onSelect: (val) => setState(() => _propCat = val)),
                  const Divider(height: 24),

                  const Text('Allowed Tenants',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _FilterChips(
                      options: const [
                        'Single Bachelor',
                        'Single Female',
                        'Family',
                        'Couple',
                        'Bachelor Group',
                        'Student',
                        'Worker'
                      ],
                      selected: _tenantType,
                      onSelect: (val) => setState(() => _tenantType = val)),
                  const Divider(height: 24),

                  const Text('Facilities (Toilet)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _FilterChips(
                      options: const ['Attached Toilet', 'Shared Toilet'],
                      selected: _toilet,
                      onSelect: (val) => setState(() => _toilet = val)),
                  const Divider(height: 24),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Rent Range',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                            '₹${_rentRange.start.toInt()} - ₹${_rentRange.end.toInt()}',
                            style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.bold)),
                      ]),
                  // NAYA: 29 divisions = Exactly 1000 ka step (30k - 1k = 29k)
                  RangeSlider(
                      values: _rentRange,
                      min: 1000,
                      max: 30000,
                      divisions: 29,
                      activeColor: const Color(0xFFC62828),
                      onChanged: (val) => setState(() => _rentRange = val)),

                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deposit Amount Range',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                            '₹${_depositRange.start.toInt()} - ₹${_depositRange.end.toInt()}',
                            style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.bold)),
                      ]),
                  // NAYA: 100 divisions = Exactly 1000 ka step (100k - 0 = 100k)
                  RangeSlider(
                      values: _depositRange,
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      activeColor: const Color(0xFFC62828),
                      onChanged: (val) => setState(() => _depositRange = val)),
                ],
              ),
            ),
          ),
          // NAYA: Apply Filters Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10)
            ]),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => widget.onApply(
                    _propCat, _tenantType, _toilet, _rentRange, _depositRange),
                child: const Text('Apply Filters',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelect;

  const _FilterChips(
      {required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(isSelected
              ? ''
              : option), // FIX: Dubara dabane par deselect hoga (All ki zarurat nahi)
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFC62828) : Colors.white,
              border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC62828)
                      : Colors.grey.shade300),
              borderRadius:
                  BorderRadius.circular(8), // FIX: Low curve as requested
            ),
            child: Text(option,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87)),
          ),
        );
      }).toList(),
    );
  }
}

// Listing Results (Pagination + Strict Schema Mapping)
class _ListingResults extends StatefulWidget {
  final String area;
  final String filterPropCat;
  final String filterTenantType;
  final String filterToilet;
  final RangeValues rentRange;
  final RangeValues depositRange;

  const _ListingResults({
    required this.area,
    required this.filterPropCat,
    required this.filterTenantType,
    required this.filterToilet,
    required this.rentRange,
    required this.depositRange,
  });

  @override
  State<_ListingResults> createState() => _ListingResultsState();
}

class _ListingResultsState extends State<_ListingResults> {
  int _displayLimit = 10;

  @override
  void didUpdateWidget(covariant _ListingResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area ||
        oldWidget.filterTenantType != widget.filterTenantType ||
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
      stream: ListingRepository().getNearbyListings(widget.area),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828)));
        var listings = snapshot.data ?? [];

        // 1. Property Category Match (Exact String Match)
        if (widget.filterPropCat.isNotEmpty) {
          listings = listings
              .where((l) => l.propertyCategory == widget.filterPropCat)
              .toList();
        }

        // 2. Tenant Type Match (Array Match checking inside allowedTenants list)
        if (widget.filterTenantType.isNotEmpty) {
          listings = listings.where((l) {
            final allowed = l.toMap()['allowedTenants'] as List<dynamic>? ?? [];
            return allowed.contains(widget.filterTenantType);
          }).toList();
        }

        // 3. Toilet Facility Match (Array Match checking inside facilities list)
        if (widget.filterToilet.isNotEmpty) {
          listings = listings.where((l) {
            final facilities = l.toMap()['facilities'] as List<dynamic>? ?? [];
            return facilities.contains(widget.filterToilet);
          }).toList();
        }

        // 4. Amount Range Checks
        listings = listings
            .where((l) =>
                l.rent >= widget.rentRange.start &&
                l.rent <= widget.rentRange.end &&
                l.deposit >= widget.depositRange.start &&
                l.deposit <= widget.depositRange.end)
            .toList();

        // 5. Area Search Match (Checks Area, SubArea, City, and Landmark)
        final search = widget.area.toLowerCase();
        if (search.isNotEmpty) {
          listings = listings.where((l) {
            final mapData = l.toMap();
            final city = (mapData['city'] ?? '').toString().toLowerCase();
            final subArea = (mapData['subArea'] ?? '').toString().toLowerCase();
            final landmark =
                (mapData['landmark'] ?? '').toString().toLowerCase();
            final area = l.area.toLowerCase();

            return area.contains(search) ||
                city.contains(search) ||
                subArea.contains(search) ||
                landmark.contains(search) ||
                l.propertyCategory.toLowerCase().contains(search);
          }).toList();
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off,
                    size: 64, color: Color(0xFFCCCCCC)),
                const SizedBox(height: 16),
                Text('Koi result nahi mila',
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF999999))),
              ],
            ),
          );
        }

        final displayedList = listings.take(_displayLimit).toList();
        final hasMore = listings.length > _displayLimit;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  return _TenantListingCard(listing: displayedList[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Tenant Listing Card
class _TenantListingCard extends StatelessWidget {
  final ListingModel listing;
  const _TenantListingCard({required this.listing});

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
            // Property Image Full Cover
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
            // Dark Bottom Gradient
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
                              listing.roomType.toUpperCase(),
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
                      children: [
                        _DarkInfoChip(
                            icon: Icons.wc, label: listing.toiletType),
                        const SizedBox(width: 8),
                        _DarkInfoChip(
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
            // Bookmark Icon
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

class _DarkInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DarkInfoChip({required this.icon, required this.label});

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

// Empty search state
class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

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
