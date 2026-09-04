import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // NAYA: Mouse drag support ke liye
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/listings/models/listing_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/reports/repositories/report_repository.dart';

class RoomDetailScreen extends StatefulWidget {
  final ListingModel listing;
  const RoomDetailScreen({super.key, required this.listing});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _requestSent = false;
  bool _loading = false;
  int _currentPhoto = 0;
  late Future<DocumentSnapshot> _roomFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // FIX: Data ek hi baar load hoga, setState par refresh nahi hoga
    _roomFuture = FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.listing.id)
        .get();
    FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.listing.id)
        .update({'views': FieldValue.increment(1)}).catchError((_) {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleInterest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Send Request?',
            style: TextStyle(
                color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Your contact number will be shared with the room owner. Are you sure you want to send this request?',
                style: TextStyle(color: Colors.black87, fontSize: 14)),
            SizedBox(height: 16),
            Text('⚠️ BEWARE OF AGENT!',
                style: TextStyle(
                    color: Color.fromARGB(255, 255, 123, 0),
                    fontWeight: FontWeight.bold)),
            Text(
                'If someone asks for commission, kindly report the account immediately.',
                style: TextStyle(
                    fontSize: 12, color: Color.fromARGB(221, 255, 0, 43))),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🇮🇳', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Expanded(
                    child: Text(
                        'Agar koi commission maangta hai, toh turant us account ko report karein.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(221, 255, 0, 43),
                            fontWeight: FontWeight.w500))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('NO', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828)),
            child: const Text('YES', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null)
        throw Exception('User data nahi mila, wapas login karein.');

      final userPhone = prefs.getString('userPhone') ?? 'Hidden';

      final supabase = Supabase.instance.client;

      final existing = await supabase
          .from('requests')
          .select('id')
          .eq('tenant_id', userId)
          .eq('listing_id', widget.listing.id!)
          .eq('sender_type', 'tenant')
          .maybeSingle();

      if (existing != null) {
        throw Exception(
            'Aap is room ke liye pehle se request bhej chuke hain!');
      }

      await supabase.from('requests').insert({
        'tenant_id': userId,
        'tenant_phone': userPhone,
        'listing_id': widget.listing.id,
        'owner_id': widget.listing.ownerId,
        'area': widget.listing.area,
        'rent': widget.listing.rent,
        'sender_type': 'tenant',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // NOTE: notification yahan client se nahi banate — index.js ka
      // onNewRequestCreated Cloud Function isse admin SDK se khud handle
      // karta hai jab request document create hota hai (owner ko duplicate
      // notification jaane se bachne ke liye).

      setState(() => _requestSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Request successfully bhej di gayi hai!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReportDialog() async {
    String? selectedReason;
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Report Listing',
              style: TextStyle(
                  color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Added Explicit Colors.black87 to all text so it doesn't blend with white background
                const Text('Aap is room ko kyu report karna chahte hain?',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 12),
                RadioListTile<String>(
                    title: const Text('Ghar nakli / fake hai',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    value: 'fake_house',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Photos se alag ghar hai',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    value: 'different_house',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Agent commission maang raha hai',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    value: 'agent',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Bada chadhakar kiraya maang raha hai',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    value: 'higher_amount',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Owner/Agent ka behavior theek nahi',
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    value: 'bad_behavior',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child:
                    const Text('CANCEL', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please Select a reason for reporting.'),
                  ));
                  return;
                }
                Navigator.pop(ctx, selectedReason);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828)),
              child:
                  const Text('SUBMIT', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId == null) return;

        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(
                child: CircularProgressIndicator(color: Colors.redAccent)));

        await ReportRepository.submitReport(
          reporterId: userId,
          reportedUserId: widget.listing.ownerId,
          reportType: confirm,
          listingId: widget.listing.id,
        );

        if (mounted) {
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Report successfully submit ho gayi hai. Admin check karenge!'),
              backgroundColor: Colors.redAccent));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Network Error! Report fail ho gayi.')));
        }
      }
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(
                  '/tenant-home'); // FIX: Seedha tenant dashboard par jayega
            }
          },
        ),
        title: Text(
            '${widget.listing.propertyCategory} in ${widget.listing.area}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _roomFuture, // FIX: Caching used
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC62828)));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('Room data nahi mila'));

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final photos = List<String>.from(data['photos'] ?? []);
          final rent = data['rent'] ?? 0;
          final deposit = data['deposit'] ?? 0;
          final area = data['area'] ?? '';
          final subArea = data['subArea'] ?? '';
          final city = data['city'] ?? '';
          final landmark = data['landmark'] ?? '';
          final size = data['sizeSqft'] ?? 0;
          final floor = data['floor'] ?? '';
          final occupancy = data['occupancy'] ?? 0;
          final distance = data['distanceKm'] ?? 0;
          final availability = data['availability'] ?? '';
          final createdAt = _formatDate(data['createdAt'] as Timestamp?);

          final facilities = List<String>.from(data['facilities'] ?? []);
          final tenants = List<String>.from(data['allowedTenants'] ?? []);
          final restrictions = List<String>.from(data['restrictions'] ?? []);

          final propertyKind = data['propertyKind'] ?? 'residential';
          final isCommercial = propertyKind == 'commercial';
          final furnishingStatus = data['furnishingStatus'] ?? '';
          final rawParkingType = data['parkingType'];
          final parkingTypeList = rawParkingType is List
              ? List<String>.from(rawParkingType)
              : (rawParkingType is String && rawParkingType.isNotEmpty
                  ? [rawParkingType]
                  : <String>[]);
          final builtUpArea = data['builtUpArea'] ?? '';
          final suitableFor = List<String>.from(data['suitableFor'] ?? []);
          final utilities = List<String>.from(data['utilities'] ?? []);
          final buildingGrade = data['buildingGrade'] ?? '';
          final buildingAge = data['buildingAge'] ?? '';
          final possession = data['possession'] ?? '';
          final ownership = data['ownership'] ?? '';
          final visibility = List<String>.from(data['visibility'] ?? []);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Carousel
                Stack(
                  children: [
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: photos.isNotEmpty
                          // NAYA: ScrollConfiguration add kiya for Web Mouse/Trackpad Drag
                          ? ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad
                                },
                              ),
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) =>
                                    setState(() => _currentPhoto = index),
                                itemCount: photos.length,
                                itemBuilder: (context, index) =>
                                    InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  child: Image.network(
                                    photos[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                            color: Color(0xFFC62828)),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 50)),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.red.shade50,
                              child: const Center(
                                  child: Icon(Icons.image_not_supported,
                                      size: 80, color: Color(0xFFC62828)))),
                    ),
                    if (photos.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: photos.asMap().entries.map((entry) {
                            return GestureDetector(
                              // NAYA: Dots par click karne se bhi image change hogi (Web ke liye easy)
                              onTap: () {
                                _pageController.animateToPage(
                                  entry.key,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical:
                                        4), // Added vertical margin for better tap area
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPhoto == entry.key
                                        ? const Color(0xFFC62828)
                                        : Colors
                                            .white70), // Slightly more visible white
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹$rent/month',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A))),
                          Text('Deposit: ₹$deposit',
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF666666))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Color(0xFFC62828)),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                                  '$area${subArea.isNotEmpty ? ', $subArea' : ''}',
                                  style: const TextStyle(
                                      fontSize: 15, color: Color(0xFF444444)))),
                        ],
                      ),
                      if (landmark.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 20),
                          child: Text('Landmark: $landmark',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 20),
                        child: Text('City: $city | Listed on: $createdAt',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),

                      // Property Overview
                      const SizedBox(height: 16),
                      const Text('Property Overview',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 77, 75, 75))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: isCommercial
                            ? [
                                _IconDetail(Icons.straighten,
                                    '${builtUpArea.isEmpty ? size : builtUpArea} sqft'),
                                _IconDetail(Icons.layers, 'Floor $floor'),
                                _IconDetail(
                                    Icons.chair_outlined,
                                    furnishingStatus.isEmpty
                                        ? 'N/A'
                                        : furnishingStatus),
                                _IconDetail(Icons.train, '$distance km'),
                              ]
                            : [
                                _IconDetail(Icons.straighten, '$size sqft'),
                                _IconDetail(Icons.layers, 'Floor $floor'),
                                _IconDetail(Icons.group, 'Max $occupancy'),
                                _IconDetail(Icons.train, '$distance km'),
                              ],
                      ),
                      const SizedBox(height: 16),
                      if (availability.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.event_available,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('Available: $availability',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green)),
                          ],
                        ),

                      const SizedBox(height: 24),
                      Text(isCommercial ? 'Suitable For' : 'Allowed Tenants',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 81, 80, 80))),
                      const SizedBox(height: 8),
                      (isCommercial ? suitableFor : tenants).isEmpty
                          ? const Text('Any')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (isCommercial ? suitableFor : tenants)
                                  .map((t) => Chip(
                                      label: Text(t,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white)),
                                      backgroundColor:
                                          const Color.fromARGB(255, 9, 9, 9),
                                      side: BorderSide.none))
                                  .toList()),

                      if (facilities.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Facilities',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: facilities
                                .map((f) => Chip(
                                    label: Text(f,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.green)),
                                    backgroundColor: Colors.green.shade50,
                                    side: BorderSide(
                                        color: Colors.green.shade200)))
                                .toList()),
                      ],

                      if (restrictions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Restrictions',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: restrictions
                                .map((r) => Chip(
                                    label: Text(r,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.red)),
                                    backgroundColor: Colors.red.shade50,
                                    side: BorderSide.none))
                                .toList()),
                      ],

                      if (isCommercial) ...[
                        if (utilities.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Utilities',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: utilities
                                  .map((u) => Chip(
                                      label: Text(u,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1A237E))),
                                      backgroundColor: const Color(0xFFE8EAF6),
                                      side: BorderSide.none))
                                  .toList()),
                        ],
                        if (parkingTypeList.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Parking',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: parkingTypeList
                                  .map((p) => Chip(
                                      label: Text(p,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1A237E))),
                                      backgroundColor: const Color(0xFFE8EAF6),
                                      side: BorderSide.none))
                                  .toList()),
                        ],
                        if (buildingGrade.isNotEmpty ||
                            buildingAge.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Building Info',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (buildingGrade.isNotEmpty)
                              Chip(
                                  label: Text('Grade: $buildingGrade',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1A237E))),
                                  backgroundColor: const Color(0xFFE8EAF6),
                                  side: BorderSide.none),
                            if (buildingAge.isNotEmpty)
                              Chip(
                                  label: Text('Age: $buildingAge',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1A237E))),
                                  backgroundColor: const Color(0xFFE8EAF6),
                                  side: BorderSide.none),
                          ]),
                        ],
                        if (possession.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Possession',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            Chip(
                                label: Text(possession,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1A237E))),
                                backgroundColor: const Color(0xFFE8EAF6),
                                side: BorderSide.none),
                          ]),
                        ],
                        if (ownership.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Ownership',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            Chip(
                                label: Text(ownership,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1A237E))),
                                backgroundColor: const Color(0xFFE8EAF6),
                                side: BorderSide.none),
                          ]),
                        ],
                        if (visibility.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Visibility',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 81, 80, 80))),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: visibility
                                  .map((v) => Chip(
                                      label: Text(v,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1A237E))),
                                      backgroundColor: const Color(0xFFE8EAF6),
                                      side: BorderSide.none))
                                  .toList()),
                        ],
                      ],

                      const SizedBox(height: 32),

                      // Interest button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: (_loading || _requestSent)
                              ? null
                              : _handleInterest,
                          icon: Icon(
                              _requestSent
                                  ? Icons.check
                                  : Icons.handshake_outlined,
                              color: Colors.white),
                          label: Text(
                            _loading
                                ? 'Bhej raha hai...'
                                : _requestSent
                                    ? 'Request Bhej Di'
                                    : 'Interest Dikhao',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _requestSent
                                ? Colors.grey
                                : const Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Report Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _showReportDialog,
                          icon: const Icon(Icons.flag_outlined,
                              color: Colors.redAccent, size: 18),
                          label: const Text('Is listing ko report karein',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IconDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconDetail(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFC62828), size: 24), // Cherry Red
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}
