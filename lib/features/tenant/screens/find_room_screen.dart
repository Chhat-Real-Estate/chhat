import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/filter_panel.dart';
import '../widgets/listing_results.dart';
import '../../notifications/widgets/notification_bell_icon.dart';

// NAYA: Search suggestions ke liye chhoti curated list (Mumbai ke common
// areas) — poori city coverage nahi hai, lekin typing UX turant improve
// karti hai bina kisi backend/API ke.
const List<String> _areaSuggestionsList = [
  'Andheri',
  'Bandra',
  'Borivali',
  'Chembur',
  'Dadar',
  'Dahisar',
  'Dharavi',
  'Ghatkopar',
  'Goregaon',
  'Govandi',
  'Jogeshwari',
  'Juhu',
  'Kandivali',
  'Kurla',
  'Malad',
  'Mulund',
  'Mumbra',
  'Nalasopara',
  'Naigaon',
  'Panvel',
  'Powai',
  'Sion',
  'Thane',
  'Vashi',
  'Vikhroli',
  'Vile Parle',
  'Virar',
  'Wadala',
  'Worli',
  'Colaba',
  'Chunabhatti',
  'Matunga',
  'Parel',
  'Byculla',
  'Mahim',
  'Santacruz',
  'Khar',
  'Versova',
  'Marol',
  'Saki Naka',
  'Chandivali',
  'Bhandup',
  'Kanjurmarg',
  'Airoli',
  'Kalyan',
  'Dombivli',
]; // NAYA: Debouncer ke liye import

const Color _bgColor = Color(0xFFF5F7F2);
const Color _cherryRed = Color(0xFFC62828);

class FindRoomScreen extends StatefulWidget {
  const FindRoomScreen({super.key});

  @override
  State<FindRoomScreen> createState() => _FindRoomScreenState();
}

class _FindRoomScreenState extends State<FindRoomScreen> {
  final _searchController = TextEditingController();
  String _searchArea = '';
  Timer? _debounce;
  List<String> _suggestions = []; // NAYA: Timer variable for debouncing

  String _filterPropertyKind = 'residential'; // 'residential' | 'commercial'
  String _filterPropCat = '';
  String _filterTenantType = '';
  String _filterToilet = '';
  RangeValues _rentRange = const RangeValues(0, 1000000);
  RangeValues _depositRange = const RangeValues(0, 1000000);
  bool _showFilters = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadTenantSmartFilters();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => userId = prefs.getString('userId'));
  }

  // NAYA: Reset Filters — pehle sirf FilterPanel ke andar reset tha,
  // panel band karne ke baad koi visible tareeka nahi tha filters hatane
  // ka (user ko app restart karna padta tha).
  bool _hasActiveFilters() {
    return _searchArea.isNotEmpty ||
        _filterPropCat.isNotEmpty ||
        _filterTenantType.isNotEmpty ||
        _filterToilet.isNotEmpty ||
        _rentRange.start > 0 ||
        _rentRange.end < 1000000 ||
        _depositRange.start > 0 ||
        _depositRange.end < 1000000;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _searchArea = '';
      _filterPropCat = '';
      _filterTenantType = '';
      _filterToilet = '';
      _rentRange = const RangeValues(0, 1000000);
      _depositRange = const RangeValues(0, 1000000);
    });
  }

  Future<void> _loadTenantSmartFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('tenantProfiles')
          .doc(userId)
          .get();

      if (!mounted) return;

      /* if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          final reqs = List<String>.from(data['propertyRequirements'] ?? []);
          if (reqs.isNotEmpty) _filterPropCat = reqs.first;

          /* final tType = data['tenantType'] as String?;
          if (tType != null && tType.isNotEmpty) _filterTenantType = tType;*/

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
      } */
    } catch (e) {
      debugPrint("Smart Filter Error: $e");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            if (userId != null)
              Align(
                alignment: Alignment.topRight,
                child: NotificationBellIcon(userId: userId!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _filterPropertyKind = 'residential';
                        _filterPropCat = '';
                        _filterTenantType = '';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _filterPropertyKind == 'residential'
                              ? _cherryRed
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10)),
                          border: Border.all(color: _cherryRed),
                        ),
                        child: Center(
                          child: Text('Residential',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _filterPropertyKind == 'residential'
                                      ? Colors.white
                                      : _cherryRed)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _filterPropertyKind = 'commercial';
                        _filterPropCat = '';
                        _filterTenantType = '';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _filterPropertyKind == 'commercial'
                              ? _cherryRed
                              : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(10)),
                          border: Border.all(color: _cherryRed),
                        ),
                        child: Center(
                          child: Text('Commercial',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _filterPropertyKind == 'commercial'
                                      ? Colors.white
                                      : _cherryRed)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'City, Area, Sub-area likho...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon:
                              const Icon(Icons.search, color: _cherryRed),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchArea = '';
                                      _suggestions = [];
                                    });
                                  })
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _cherryRed)),
                        ),
                        // NAYA: Debouncing (API Optimization) + suggestions
                        onChanged: (val) {
                          final query = val.trim().toLowerCase();
                          setState(() {
                            _suggestions = query.isEmpty
                                ? []
                                : _areaSuggestionsList
                                    .where((a) =>
                                        a.toLowerCase().startsWith(query))
                                    .take(5)
                                    .toList();
                          });
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              setState(() => _searchArea = val.trim());
                            }
                          });
                        },
                      ),
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
            if (_hasActiveFilters())
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _resetAllFilters,
                    icon: const Icon(Icons.filter_alt_off,
                        size: 18, color: _cherryRed),
                    label: const Text('Reset Filters',
                        style: TextStyle(
                            color: _cherryRed, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _suggestions
                        .map((s) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined,
                                  color: _cherryRed, size: 20),
                              title: Text(s),
                              onTap: () {
                                _searchController.text = s;
                                _searchController.selection =
                                    TextSelection.collapsed(offset: s.length);
                                setState(() {
                                  _searchArea = s;
                                  _suggestions = [];
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_showFilters)
              FilterPanel(
                initialPropertyKind: _filterPropertyKind,
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
                    _showFilters = false;
                  });
                },
              ),
            Expanded(
              // NAYA: Ab EmptySearch UI block nahi karega, by default saare rooms dikhenge!
              child: ListingResults(
                area: _searchArea,
                filterPropertyKind: _filterPropertyKind,
                filterPropCat: _filterPropCat,
                filterTenantType: _filterTenantType,
                filterToilet: _filterToilet,
                rentRange: _rentRange,
                depositRange: _depositRange,
                onResetFilters: _resetAllFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
