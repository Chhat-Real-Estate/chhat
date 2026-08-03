import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // FIX: Ye import miss ho gaya tha
import '../../../features/listings/repositories/listing_repository.dart';
import '../../../features/listings/models/listing_model.dart';
import '../../../features/requests/repositories/request_repository.dart';
import '../../../features/requests/models/request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/reports/repositories/report_repository.dart'; // NAYA: Report logic import
import 'package:url_launcher/url_launcher.dart';
import '../../profile/screens/profile_screen.dart';

// --- Blueberry Theme Colors ---
const Color _blueDark = Color(0xFF1A237E); // Blueberry Dark
const Color _blueLight = Color(0xFF3949AB); // Blueberry Light
const Color _bgColor = Color(0xFFF5F7F2);

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentIndex = 0;

  // FIX: 'final' hata kar 'get' banaya taaki Profile ka back button Find Tenants (index 0) par le jaye
  List<Widget> get _pages => [
        const _FindTenantsPage(),
        const _ListingsPage(),
        const _RequestsTabsPage(),
        ProfileScreen(
          onBack: () {
            setState(() {
              _currentIndex =
                  0; // Owner Dashboard par back dabane se Find Tenants par jayega
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_blueDark, _blueLight]),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          backgroundColor: Colors.transparent, // Transparent to show gradient
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.person_search_outlined),
                activeIcon: Icon(Icons.person_search),
                label: 'Find Tenants'),
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Meri Listings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Requests'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: Listings Page ---
class _ListingsPage extends StatefulWidget {
  const _ListingsPage();
  @override
  State<_ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<_ListingsPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_blueDark, _blueLight]))),
        elevation: 0,
        title: const Text('Meri Listings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator(color: _blueDark))
          : StreamBuilder<List<ListingModel>>(
              stream: ListingRepository().getOwnerListings(userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                      child: CircularProgressIndicator(color: _blueDark));
                final listings = snapshot.data ?? [];

                if (listings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined,
                            size: 80, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 16),
                        Text('Abhi koi listing nahi hai',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF999999))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) =>
                      _OwnerFullListingCard(listing: listings[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-listing'),
        backgroundColor: _blueDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Room Add Karo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// FIX ISSUE #4: Premium MagicBricks/Airbnb style Listing Card
class _OwnerFullListingCard extends StatefulWidget {
  final ListingModel listing;
  const _OwnerFullListingCard({required this.listing});

  @override
  State<_OwnerFullListingCard> createState() => _OwnerFullListingCardState();
}

class _OwnerFullListingCardState extends State<_OwnerFullListingCard> {
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
        borderRadius: BorderRadius.circular(20), // Premium rounded corners
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
          // IMAGE CAROUSEL SECTION
          Stack(
            children: [
              SizedBox(
                height: 240, // Taller image for better visibility
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
              // Gradient Overlay for text visibility
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
              // Status Badge
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
              // Verified Badge
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
              // Dots Indicator
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

          // DETAILS SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Title
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

                // Amenities Row
                Row(
                  children: [
                    _FeatureChip(
                        icon: Icons.group_outlined,
                        label: 'Max ${widget.listing.occupancy}'),
                    const SizedBox(width: 8),
                    _FeatureChip(
                        icon: Icons.person_outline,
                        label: widget.listing.genderPref.toUpperCase()),
                    const SizedBox(width: 8),
                    _FeatureChip(
                        icon: Icons.event_available_outlined,
                        label: widget.listing.availability.isNotEmpty
                            ? widget.listing.availability
                            : 'Immediate'),
                  ],
                ),

                const Divider(height: 24, color: Color(0xFFEEEEEE)),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('124 Views',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        const Icon(Icons.mail_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text('12 Invites',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('Posted: ${_formatDate(widget.listing.createdAt)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 20),

                // ACTION BUTTONS
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.rocket_launch_outlined,
                            size: 18, color: Colors.white),
                        label: const Text('Boost',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.orange.shade600,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content:
                                Text('Listing Boost feature is coming soon!'),
                            backgroundColor: Colors.orange,
                          ));
                        },
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

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F2), // Light neutral background
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

// --- TAB 1: Find Tenants Page (Advanced Filters & Name) ---
class _FindTenantsPage extends StatefulWidget {
  const _FindTenantsPage();

  @override
  State<_FindTenantsPage> createState() => _FindTenantsPageState();
}

class _FindTenantsPageState extends State<_FindTenantsPage> {
  String _filterType = 'All Types';
  String _filterBudget = 'All Budgets';
  String _filterMoveIn = 'Any Move-in';
  bool _showFilters = false; // NAYA: Filter hide/show control
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_blueDark, _blueLight]))),
        elevation: 0,
        title: const Text('Find Tenants',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.tune,
                color: Colors.white),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          )
        ],
      ),
      body: Column(
        children: [
          // NAYA: Blueberry Advanced Filter Panel
          if (_showFilters)
            _OwnerFilterPanel(
              initialType: _filterType,
              initialBudget: _filterBudget,
              initialMoveIn: _filterMoveIn,
              onApply: (type, budget, moveIn) {
                setState(() {
                  _filterType = type;
                  _filterBudget = budget;
                  _filterMoveIn = moveIn;
                  _showFilters = false; // Filter apply hote hi hide hoga
                });
              },
            ),

          // Tenant List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tenantProfiles')
                  .where('isProfileComplete',
                      isEqualTo:
                          true) // FIX ISSUE #1: Incomplete profile hide kardo
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                      child: CircularProgressIndicator(color: _blueDark));
                var docs = snapshot.data?.docs ?? [];

                // Local Filtering
                if (_filterType != 'All Types')
                  docs = docs
                      .where(
                          (d) => (d.data() as Map)['tenantType'] == _filterType)
                      .toList();
                if (_filterBudget != 'All Budgets')
                  docs = docs
                      .where((d) =>
                          (d.data() as Map)['budgetRange'] == _filterBudget)
                      .toList();
                if (_filterMoveIn != 'Any Move-in')
                  docs = docs
                      .where((d) =>
                          (d.data() as Map)['moveInDate'] == _filterMoveIn)
                      .toList();

                if (docs.isEmpty)
                  return const Center(
                      child: Text('Koi tenant match nahi hua.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final tenantId = docs[index].id;
                    final tenantName = data['name'] ?? 'Unknown Tenant';

                    // NAYA: Timestamp parsing
                    final timestamp = data['updatedAt'] as Timestamp?;
                    final timeString = timestamp != null
                        ? timestamp.toDate().toString().substring(0, 16)
                        : 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(tenantName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _blueDark),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.flag_outlined,
                                        color: Colors.redAccent, size: 22),
                                    onPressed: () async {
                                      String? selectedReason;
                                      final confirm = await showDialog<String>(
                                          context: context,
                                          builder: (ctx) => StatefulBuilder(
                                              builder: (context,
                                                      setDialogState) =>
                                                  AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    surfaceTintColor:
                                                        Colors.white,
                                                    title: const Text(
                                                        'Report Agent?',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              'Kya ye tenant ek broker/agent lag raha hai? Iski profile report karein.',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black87)),
                                                          const SizedBox(
                                                              height: 12),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Broker/Agent acting as Tenant',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value:
                                                                  'broker_acting_as_tenant',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Fake profile',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value:
                                                                  'fake_profile',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Scam or Fraud',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value: 'scam',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx, null),
                                                          child: const Text(
                                                              'CANCEL',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey))),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .redAccent),
                                                        onPressed: () =>
                                                            Navigator.pop(ctx,
                                                                selectedReason),
                                                        child: const Text(
                                                            'REPORT',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                      ),
                                                    ],
                                                  )));

                                      if (confirm != null && userId != null) {
                                        await ReportRepository.submitReport(
                                            reporterId: userId!,
                                            reportedUserId: tenantId,
                                            reportType: confirm);
                                        if (context.mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Agent reported successfully!'),
                                                  backgroundColor:
                                                      Colors.redAccent));
                                      }
                                    },
                                    tooltip: 'Report Agent',
                                  ),
                                  const Icon(Icons.verified_user_outlined,
                                      color: Color(0xFF1A237E), size: 20),
                                ],
                              )
                            ],
                          ),
                          Text('Active on: $timeString',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const Divider(height: 24),
                          _buildInfoRow('Type:', data['tenantType'] ?? 'N/A'),
                          _buildInfoRow(
                              'Budget:', data['budgetRange'] ?? 'N/A'),
                          _buildInfoRow(
                              'Move In:', data['moveInDate'] ?? 'N/A'),
                          _buildInfoRow(
                              'Occupation:', data['occupation'] ?? 'N/A'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    title: const Text('Send Invitation?',
                                        style: TextStyle(
                                            color: Color(0xFF1A237E),
                                            fontWeight: FontWeight.bold)),
                                    content: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Your Contact number will be shared to Tenant. Are you sure you want to send invitation?',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14)),
                                        SizedBox(height: 16),
                                        Text('⚠️ BEWARE OF AGENT!',
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 123, 0),
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'If someone asks for commission, kindly report the account immediately.',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color.fromARGB(
                                                    221, 255, 0, 43))),
                                        SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('🇮🇳',
                                                style: TextStyle(fontSize: 14)),
                                            SizedBox(width: 6),
                                            Expanded(
                                                child: Text(
                                                    'Agar koi commission maangta hai, toh turant us account ko report karein.',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Color.fromARGB(
                                                            221, 255, 0, 43),
                                                        fontWeight:
                                                            FontWeight.w500))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('NO',
                                              style: TextStyle(
                                                  color: Colors.grey))),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1A237E)),
                                        child: const Text('YES',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && userId != null) {
                                  try {
                                    final listingQuery = await FirebaseFirestore
                                        .instance
                                        .collection('listings')
                                        .where('ownerId', isEqualTo: userId)
                                        .limit(1)
                                        .get();
                                    if (listingQuery.docs.isEmpty) {
                                      if (context.mounted)
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Pehle ek room add kariye!')));
                                      return;
                                    }

                                    await RequestRepository()
                                        .sendRequest(RequestModel(
                                      tenantId: tenantId,
                                      tenantPhone: 'Hidden',
                                      listingId: listingQuery.docs.first.id,
                                      ownerId: userId!,
                                      area: listingQuery.docs.first
                                              .data()['area'] ??
                                          '',
                                      rent: listingQuery.docs.first
                                              .data()['rent'] ??
                                          0,
                                      senderType: 'owner',
                                    ));

                                    await FirebaseFirestore.instance
                                        .collection('notifications')
                                        .add({
                                      'userId': tenantId,
                                      'title': 'New Room Invite!',
                                      'body':
                                          'Ek owner ne aapko apne room ke liye invite bheja hai.',
                                      'type': 'invite',
                                      'isRead': false,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (context.mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Invitation Sent Successfully!'),
                                              backgroundColor: Colors.green));
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(e
                                                  .toString()
                                                  .replaceAll(
                                                      'Exception: ', ''))));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text('Send Room Invite',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87))),
        ],
      ),
    );
  }
}

// NAYA: Blueberry Filter Panel for Owner
class _OwnerFilterPanel extends StatefulWidget {
  final String initialType;
  final String initialBudget;
  final String initialMoveIn;
  final Function(String, String, String) onApply;

  const _OwnerFilterPanel(
      {required this.initialType,
      required this.initialBudget,
      required this.initialMoveIn,
      required this.onApply});

  @override
  State<_OwnerFilterPanel> createState() => _OwnerFilterPanelState();
}

class _OwnerFilterPanelState extends State<_OwnerFilterPanel> {
  late String _type;
  late String _budget;
  late String _moveIn;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _budget = widget.initialBudget;
    _moveIn = widget.initialMoveIn;
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
                  const Text('Tenant Type',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _OwnerFilterChips(
                      options: const [
                        'All Types',
                        'Single Bachelor',
                        'Single Female',
                        'Family',
                        'Couple',
                        'Student'
                      ],
                      selected: _type,
                      onSelect: (val) => setState(() => _type = val)),
                  const Divider(height: 24),
                  const Text('Budget',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _OwnerFilterChips(
                      options: const [
                        'All Budgets',
                        'Below ₹5,000',
                        '₹5,000 - ₹10,000',
                        '₹10,000 - ₹15,000',
                        'Above ₹20,000'
                      ],
                      selected: _budget,
                      onSelect: (val) => setState(() => _budget = val)),
                  const Divider(height: 24),
                  const Text('Move In',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _OwnerFilterChips(
                      options: const [
                        'Any Move-in',
                        'Immediately',
                        'Within 7 Days',
                        'Within 15 Days',
                        'Within 30 Days'
                      ],
                      selected: _moveIn,
                      onSelect: (val) => setState(() => _moveIn = val)),
                ],
              ),
            ),
          ),
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
                    backgroundColor: _blueDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => widget.onApply(_type, _budget, _moveIn),
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

class _OwnerFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelect;

  const _OwnerFilterChips(
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
              ? (options.first)
              : option), // Default to first option if unselected
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _blueDark : Colors.white,
              border: Border.all(
                  color: isSelected ? _blueDark : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
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

// --- TAB 3: Requests (2 Tabs) ---
class _RequestsTabsPage extends StatefulWidget {
  const _RequestsTabsPage();
  @override
  State<_RequestsTabsPage> createState() => _RequestsTabsPageState();
}

class _RequestsTabsPageState extends State<_RequestsTabsPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_blueDark, _blueLight]))),
          title: const Text('Requests',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Incoming'), Tab(text: 'Sent')],
          ),
        ),
        body: userId == null
            ? const Center(child: CircularProgressIndicator(color: _blueDark))
            : TabBarView(
                children: [
                  _IncomingRequestsTab(userId: userId!),
                  _SentRequestsTab(userId: userId!), // FIX: Link active tab
                ],
              ),
      ),
    );
  }
}

// --- Incoming Requests Full Detail Card ---
class _IncomingRequestsTab extends StatelessWidget {
  final String userId;
  const _IncomingRequestsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: RequestRepository().getOwnerRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)));
        final requests = snapshot.data ?? [];

        // 48 hours expiry logic for UI
        final activeRequests = requests
            .where((r) =>
                r.createdAt.difference(DateTime.now()).inHours.abs() <= 48)
            .toList();

        if (activeRequests.isEmpty)
          return const Center(
              child: Text('Abhi koi active request nahi aayi',
                  style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeRequests.length,
          itemBuilder: (context, index) {
            final req = activeRequests[index];
            final isAccepted = req.status == 'accepted';
            final isPending = req.status == 'pending';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('tenantProfiles')
                  .doc(req.tenantId)
                  .get(),
              builder: (ctx, tSnap) {
                // FIX: Check exact connection state. Agar fail hua toh infinite loading nahi hogi.
                if (tSnap.connectionState == ConnectionState.waiting) {
                  return const Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: ListTile(
                          title: Text('Loading tenant details...',
                              style: TextStyle(color: Colors.black87))));
                }

                // FIX: Fallback value agar profile database me exist nahi karti
                final tData =
                    (tSnap.data?.data() as Map<String, dynamic>?) ?? {};
                final tenantName = tData['name'] ?? 'Unknown Tenant';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10)
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Room: ${req.area}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: isPending
                                      ? Colors.orange
                                      : (isAccepted
                                          ? const Color(0xFF4CAF50)
                                          : Colors.red)),
                            ),
                            child: Text(
                              isPending
                                  ? 'Pending'
                                  : (isAccepted ? 'Accepted' : 'Rejected'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPending
                                      ? Colors.orange
                                      : (isAccepted
                                          ? const Color(0xFF4CAF50)
                                          : Colors.red)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Kiraya: ₹${req.rent}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      // TIMESTAMP
                      Text('Date: ${req.createdAt.toString().substring(0, 16)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Text('Tenant Details:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      _buildDetailRow('Name:', tenantName),
                      _buildDetailRow(
                          'Tenant Type:', tData['tenantType'] ?? 'N/A'),
                      _buildDetailRow('Budget:', tData['budgetRange'] ?? 'N/A'),
                      _buildDetailRow(
                          'Occupation:', tData['occupation'] ?? 'N/A'),
                      _buildDetailRow('Move In:', tData['moveInDate'] ?? 'N/A'),
                      _buildDetailRow(
                          'Needs:',
                          (tData['propertyRequirements'] as List?)
                                  ?.join(', ') ??
                              'N/A'),

                      if (isAccepted) ...[
                        const SizedBox(height: 16),
                        // EXACT TENANT MATCH UI: GREEN CALL BUTTON & WARNING
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF2F9F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚠️ BEWARE OF AGENT!',
                                  style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Agar call par koi commission maange, toh turant uski profile report karein.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87)),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final Uri url =
                                        Uri.parse('tel:+91${req.tenantPhone}');
                                    if (!await launchUrl(url)) {
                                      if (ctx.mounted)
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Call dialer nahi khul paya!')));
                                    }
                                  },
                                  icon: const Icon(Icons.call,
                                      color: Colors.white, size: 18),
                                  label: Text(
                                      'Call Tenant: +91 ${req.tenantPhone}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6))),
                                ),
                              )
                            ],
                          ),
                        )
                      ] else if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () => RequestRepository()
                                        .updateRequestStatus(
                                            req.id!, 'rejected', userId!),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.redAccent)),
                                    child: const Text('Reject',
                                        style: TextStyle(
                                            color: Colors.redAccent)))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: () => RequestRepository()
                                        .updateRequestStatus(
                                            req.id!, 'accepted', userId!),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1A237E)),
                                    child: const Text('Accept',
                                        style:
                                            TextStyle(color: Colors.white)))),
                          ],
                        )
                      ],
                      // REPORT BUTTON
                      const Divider(height: 24),
                      GestureDetector(
                        onTap: () async {
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text('Report?',
                                          style: TextStyle(color: Colors.red)),
                                      content: const Text(
                                          'Kya aap is tenant ko report karna chahte hain?',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel')),
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('reports')
                                                  .add({
                                                'reporterId': userId,
                                                'reportedUserId': req.tenantId,
                                                'reason':
                                                    'Reported from Requests',
                                                'createdAt':
                                                    FieldValue.serverTimestamp()
                                              });
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Report submitted!'),
                                                      backgroundColor:
                                                          Colors.red));
                                            },
                                            child: const Text('Submit',
                                                style: TextStyle(
                                                    color: Colors.white)))
                                      ]));
                        },
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.flag,
                                  size: 14, color: Colors.redAccent),
                              SizedBox(width: 4),
                              Text('Report Tenant',
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold))
                            ]),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87))),
        ],
      ),
    );
  }
}

// NAYA: Sent Requests Tab (Perfect UI with Tenant Name)
class _SentRequestsTab extends StatelessWidget {
  final String userId;
  const _SentRequestsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: RequestRepository().getOwnerSentRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)));
        final requests = snapshot.data ?? [];
        if (requests.isEmpty)
          return const Center(
              child: Text('Aapne koi active invite nahi bheja hai.',
                  style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];

            // FIX: FutureBuilder lagaya Tenant ka Asli Naam laane ke liye
            return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('tenantProfiles')
                    .doc(req.tenantId)
                    .get(),
                builder: (ctx, tSnap) {
                  String tenantName = 'Loading...';

                  // FIX: Loading complete hone ke baad condition check karo
                  if (tSnap.connectionState != ConnectionState.waiting) {
                    if (tSnap.hasData &&
                        tSnap.data != null &&
                        tSnap.data!.exists) {
                      tenantName = (tSnap.data!.data()
                              as Map<String, dynamic>)['name'] ??
                          'Unknown Tenant';
                    } else {
                      tenantName =
                          'Unknown Tenant'; // Error aane par yahan fallback lega
                    }
                  }

                  return Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Invite sent for Room: ${req.area}',
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${req.status.toUpperCase()}',
                                    style: TextStyle(
                                        color: req.status == 'accepted'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Sent to: $tenantName',
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize:
                                            13)), // FIX: Yahan ID ki jagah Name aayega
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: req.status == 'accepted'
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 28)
                              : const Icon(Icons.access_time_filled,
                                  color: Colors.orange, size: 28),
                        ),
                      ));
                });
          },
        );
      },
    );
  }
}
