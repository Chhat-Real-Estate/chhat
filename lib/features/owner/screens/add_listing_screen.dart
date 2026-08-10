import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/listing_form_widgets.dart'; // NAYA IMPORT
import '../../../core/constants/property_options.dart'; // NAYA IMPORT

const Color _blueDark = Color(0xFF1A237E);

class AddListingScreen extends StatefulWidget {
  final String? listingId;
  const AddListingScreen({super.key, this.listingId});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _subAreaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _distanceController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _sizeController = TextEditingController();
  final _floorController = TextEditingController();
  final _occupancyController = TextEditingController();
  final _builtUpAreaController = TextEditingController();
  final _superBuiltUpAreaController = TextEditingController();
  final _plotAreaController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _ceilingHeightController = TextEditingController();
  final _frontageController = TextEditingController();
  final _roadWidthController = TextEditingController();

  String _propertyKind = 'residential'; // 'residential' | 'commercial'
  String _propertyCategory = '';
  String _furnishingStatus = '';
  List<String> _residentialParking = [];
  List<String> _commercialParking = [];
  String _availability = '';
  List<String> _selectedFacilities = [];
  List<String> _selectedTenants = [];
  List<String> _selectedRestrictions = [];

  // Commercial Only
  List<String> _suitableFor = [];
  List<String> _utilities = [];
  String _buildingGrade = '';
  String _buildingAge = '';
  String _possession = '';
  String _ownership = '';
  List<String> _visibility = [];

  bool _loading = false;
  bool _isLoadingData = false;
  List<String> _uploadedPhotos = [];

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      _fetchExistingListing();
    }
  }

  Future<void> _fetchExistingListing() async {
    setState(() => _isLoadingData = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _propertyKind = data['propertyKind'] ?? 'residential';
          _propertyCategory = data['propertyCategory'] ?? '';
          _furnishingStatus = data['furnishingStatus'] ?? '';
          final rawParking = data['parkingType'];
          final parsedParking = rawParking is List
              ? List<String>.from(rawParking)
              : (rawParking is String && rawParking.isNotEmpty
                  ? [rawParking]
                  : <String>[]);
          if (data['propertyKind'] == 'commercial') {
            _commercialParking = parsedParking;
          } else {
            _residentialParking = parsedParking;
          }
          _cityController.text = data['city'] ?? '';
          _areaController.text = data['area'] ?? '';
          _subAreaController.text = data['subArea'] ?? '';
          _landmarkController.text = data['landmark'] ?? '';
          _distanceController.text = (data['distanceKm'] ?? '').toString();
          _rentController.text = (data['rent'] ?? '').toString();
          _depositController.text = (data['deposit'] ?? '').toString();
          _sizeController.text = (data['sizeSqft'] ?? '').toString();
          _floorController.text = (data['floor'] ?? '').toString();
          _occupancyController.text = (data['occupancy'] ?? '').toString();

          _selectedFacilities = List<String>.from(data['facilities'] ?? []);
          _selectedTenants = List<String>.from(data['allowedTenants'] ?? []);
          _selectedRestrictions = List<String>.from(data['restrictions'] ?? []);
          _availability = data['availability'] ?? '';

          _builtUpAreaController.text = data['builtUpArea'] ?? '';
          _superBuiltUpAreaController.text = data['superBuiltUpArea'] ?? '';
          _plotAreaController.text = data['plotArea'] ?? '';
          _totalFloorsController.text = data['totalFloors'] ?? '';
          _ceilingHeightController.text = data['ceilingHeight'] ?? '';
          _frontageController.text = data['frontage'] ?? '';
          _roadWidthController.text = data['roadWidth'] ?? '';
          _suitableFor = List<String>.from(data['suitableFor'] ?? []);
          _utilities = List<String>.from(data['utilities'] ?? []);
          _buildingGrade = data['buildingGrade'] ?? '';
          _buildingAge = data['buildingAge'] ?? '';
          _possession = data['possession'] ?? '';
          _ownership = data['ownership'] ?? '';
          _visibility = List<String>.from(data['visibility'] ?? []);

          _uploadedPhotos = List<String>.from(data['photos'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _areaController.dispose();
    _subAreaController.dispose();
    _landmarkController.dispose();
    _distanceController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _sizeController.dispose();
    _floorController.dispose();
    _occupancyController.dispose();
    _builtUpAreaController.dispose();
    _superBuiltUpAreaController.dispose();
    _plotAreaController.dispose();
    _totalFloorsController.dispose();
    _ceilingHeightController.dispose();
    _frontageController.dispose();
    _roadWidthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.listingId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blueDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/owner-home'),
        ),
        title: Text(
          isEditMode ? 'Room Update Karo' : 'Room Post Karo',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: _blueDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListingSectionTitle(title: 'Property Kind'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'residential',
                          groupValue: _propertyKind,
                          activeColor: _blueDark,
                          title: const Text('Residential',
                              style: TextStyle(fontSize: 14)),
                          onChanged: (val) => setState(() {
                            _propertyKind = val!;
                            _propertyCategory = '';
                          }),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'commercial',
                          groupValue: _propertyKind,
                          activeColor: _blueDark,
                          title: const Text('Commercial',
                              style: TextStyle(fontSize: 14)),
                          onChanged: (val) => setState(() {
                            _propertyKind = val!;
                            _propertyCategory = '';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Property Photos'),
                  const SizedBox(height: 8),
                  const Text('Achhi photos se jaldi tenant milta hai.',
                      style: TextStyle(color: Color(0xFF666666))),
                  const SizedBox(height: 12),
                  ListingPhotoPicker(
                      initialPhotos: _uploadedPhotos,
                      onPhotosChanged: (urls) =>
                          setState(() => _uploadedPhotos = urls)),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Property Category'),
                  const SizedBox(height: 12),
                  ListingChipSelector(
                    options: _propertyKind == 'commercial'
                        ? PropertyOptions.commercialCategories
                        : PropertyOptions.residentialCategories,
                    selected: _propertyCategory,
                    onSelect: (val) => setState(() => _propertyCategory = val),
                  ),
                  const SizedBox(height: 32),
                  ListingSectionTitle(
                      title: _propertyKind == 'commercial'
                          ? 'Furnishing Status'
                          : 'Furnishing Status'),
                  const SizedBox(height: 12),
                  ListingChipSelector(
                    options: _propertyKind == 'commercial'
                        ? PropertyOptions.commercialFurnishing
                        : PropertyOptions.residentialFurnishing,
                    selected: _furnishingStatus,
                    onSelect: (val) => setState(() => _furnishingStatus = val),
                  ),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Parking'),
                  const SizedBox(height: 12),
                  if (_propertyKind == 'commercial')
                    ListingMultiChipSelector(
                      options: PropertyOptions.commercialParking,
                      selected: _commercialParking,
                      onChanged: (val) =>
                          setState(() => _commercialParking = val),
                    )
                  else
                    ListingMultiChipSelector(
                      options: const ['None', 'Bike Park', 'Car Park'],
                      selected: _residentialParking,
                      onChanged: (val) =>
                          setState(() => _residentialParking = val),
                    ),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Location Details'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _cityController, hint: 'City (e.g. Mumbai)'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _areaController,
                      hint: 'Area (e.g. Andheri East)'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _subAreaController,
                      hint: 'Sub Area (e.g. Marol)'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _landmarkController,
                      hint: 'Landmark (e.g. Near Metro)'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _distanceController,
                      hint: 'Distance from Station (in km)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  if (_propertyKind == 'commercial') ...[
                    const SizedBox(height: 32),
                    const ListingSectionTitle(title: 'Visibility'),
                    const SizedBox(height: 12),
                    ListingMultiChipSelector(
                      options: PropertyOptions.commercialVisibility,
                      selected: _visibility,
                      onChanged: (val) => setState(() => _visibility = val),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Pricing'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _rentController,
                      hint: 'Kiraya / Rent',
                      prefix: '₹',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _depositController,
                      hint: 'Deposit Amount',
                      prefix: '₹',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Room Details'),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _sizeController,
                      hint: 'Size (sqft)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  const SizedBox(height: 12),
                  ListingInputField(
                      controller: _floorController,
                      hint: 'Floor No (0 for Ground)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ]),
                  const SizedBox(height: 12),
                  if (_propertyKind == 'residential')
                    ListingInputField(
                        controller: _occupancyController,
                        hint: 'Max Occupancy (kitne log)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),
                  if (_propertyKind == 'commercial') ...[
                    ListingInputField(
                        controller: _builtUpAreaController,
                        hint: 'Built-up Area (sqft) (Optional)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _superBuiltUpAreaController,
                        hint: 'Super Built-up Area (sqft) (Optional)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _plotAreaController,
                        hint: 'Plot Area (sqft) (Optional)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _totalFloorsController,
                        hint: 'Total Floors in Building (Optional)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ]),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _ceilingHeightController,
                        hint: 'Ceiling Height (ft) (Optional)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _frontageController,
                        hint: 'Frontage (ft) (Optional)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    const SizedBox(height: 12),
                    ListingInputField(
                        controller: _roadWidthController,
                        hint: 'Road Width (ft) (Optional)',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                  ],
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Facilities'),
                  const SizedBox(height: 12),
                  ListingMultiChipSelector(
                    options: [
                      if (_propertyKind != 'commercial') 'Furnished',
                      'Attached Toilet',
                      'Shared Toilet',
                      'Water Supply - Indoor',
                      'Water Supply - Outdoor',
                      'WiFi',
                      _propertyKind == 'commercial'
                          ? 'Canteen'
                          : 'Cooking Allowed',
                    ],
                    selected: _selectedFacilities,
                    onChanged: (val) =>
                        setState(() => _selectedFacilities = val),
                  ),
                  const SizedBox(height: 32),
                  ListingSectionTitle(
                      title: _propertyKind == 'commercial'
                          ? 'Suitable For'
                          : 'Allowed Tenants'),
                  const SizedBox(height: 12),
                  ListingMultiChipSelector(
                    options: _propertyKind == 'commercial'
                        ? PropertyOptions.suitableFor
                        : const [
                            'Single Bachelor',
                            'Single Female',
                            'Family',
                            'Couple',
                            'Bachelor Group',
                            'Student',
                            'Worker'
                          ],
                    selected: _propertyKind == 'commercial'
                        ? _suitableFor
                        : _selectedTenants,
                    onChanged: (val) => setState(() {
                      if (_propertyKind == 'commercial') {
                        _suitableFor = val;
                      } else {
                        _selectedTenants = val;
                      }
                    }),
                  ),
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Restrictions'),
                  const SizedBox(height: 12),
                  ListingMultiChipSelector(
                    options: _propertyKind == 'commercial'
                        ? PropertyOptions.commercialRestrictions
                        : const [
                            'No Smoking',
                            'No Drinking',
                            'No Pets',
                            'No Non-Veg'
                          ],
                    selected: _selectedRestrictions,
                    onChanged: (val) =>
                        setState(() => _selectedRestrictions = val),
                  ),
                  if (_propertyKind == 'commercial') ...[
                    const SizedBox(height: 32),
                    const ListingSectionTitle(title: 'Utilities'),
                    const SizedBox(height: 12),
                    ListingMultiChipSelector(
                      options: PropertyOptions.commercialUtilities,
                      selected: _utilities,
                      onChanged: (val) => setState(() => _utilities = val),
                    ),
                    const SizedBox(height: 32),
                    const ListingSectionTitle(title: 'Building Info'),
                    const SizedBox(height: 12),
                    const Text('Building Grade',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    ListingChipSelector(
                      options: PropertyOptions.buildingGrades,
                      selected: _buildingGrade,
                      onSelect: (val) => setState(() => _buildingGrade = val),
                    ),
                    const SizedBox(height: 16),
                    const Text('Building Age',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    ListingChipSelector(
                      options: PropertyOptions.buildingAges,
                      selected: _buildingAge,
                      onSelect: (val) => setState(() => _buildingAge = val),
                    ),
                    const SizedBox(height: 32),
                    const ListingSectionTitle(title: 'Possession'),
                    const SizedBox(height: 12),
                    ListingChipSelector(
                      options: PropertyOptions.commercialPossession,
                      selected: _possession,
                      onSelect: (val) => setState(() => _possession = val),
                    ),
                    const SizedBox(height: 32),
                    const ListingSectionTitle(title: 'Ownership'),
                    const SizedBox(height: 12),
                    ListingChipSelector(
                      options: PropertyOptions.commercialOwnership,
                      selected: _ownership,
                      onSelect: (val) => setState(() => _ownership = val),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const ListingSectionTitle(title: 'Availability'),
                  const SizedBox(height: 12),
                  ListingChipSelector(
                    options: const [
                      'Immediately',
                      'Within 7 Days',
                      'Within 15 Days',
                      'Within 30 Days'
                    ],
                    selected: _availability,
                    onSelect: (val) => setState(() => _availability = val),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submitListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blueDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditMode
                                  ? 'Update Property'
                                  : 'Publish Property',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Future<void> _submitListing() async {
    if (_propertyCategory.isEmpty ||
        _rentController.text.isEmpty ||
        _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Zaroori fields (Category, Rent, Area) bharna mandatory hai')));
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User authentication error');

      final userPhone = prefs.getString('userPhone') ?? '';

      final updateData = {
        'ownerId': userId,
        'phone': userPhone,
        'propertyKind': _propertyKind,
        'propertyCategory': _propertyCategory,
        'furnishingStatus': _furnishingStatus,
        'parkingType': _propertyKind == 'commercial'
            ? _commercialParking
            : _residentialParking,
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim().toLowerCase(),
        'subArea': _subAreaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'distanceKm': double.tryParse(_distanceController.text.trim()) ?? 0.0,
        'rent': int.tryParse(_rentController.text.trim()) ?? 0,
        'deposit': int.tryParse(_depositController.text.trim()) ?? 0,
        'sizeSqft': int.tryParse(_sizeController.text.trim()) ?? 0,
        'floor': _floorController.text.trim(),
        'occupancy': int.tryParse(_occupancyController.text.trim()) ?? 0,
        'facilities': _selectedFacilities,
        'allowedTenants': _selectedTenants,
        'restrictions': _selectedRestrictions,
        'availability': _availability,
        'photos': _uploadedPhotos,
        'updatedAt': FieldValue.serverTimestamp(),
        'roomType': _propertyCategory.toLowerCase().contains('shared')
            ? 'shared'
            : 'single',
        'genderPref': _selectedTenants.contains('Single Female')
            ? 'female'
            : (_selectedTenants.contains('Single Bachelor') ? 'male' : 'any'),
        'toiletType': _selectedFacilities.contains('Attached Toilet')
            ? 'attached'
            : 'shared',
        'builtUpArea': _builtUpAreaController.text.trim(),
        'superBuiltUpArea': _superBuiltUpAreaController.text.trim(),
        'plotArea': _plotAreaController.text.trim(),
        'totalFloors': _totalFloorsController.text.trim(),
        'ceilingHeight': _ceilingHeightController.text.trim(),
        'frontage': _frontageController.text.trim(),
        'roadWidth': _roadWidthController.text.trim(),
        'suitableFor': _suitableFor,
        'utilities': _utilities,
        'buildingGrade': _buildingGrade,
        'buildingAge': _buildingAge,
        'possession': _possession,
        'ownership': _ownership,
        'visibility': _visibility,
      };

      if (widget.listingId != null) {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .update(updateData);
      } else {
        final activeListings = await FirebaseFirestore.instance
            .collection('listings')
            .where('ownerId', isEqualTo: userId)
            .where('active', isEqualTo: true)
            .get();

        if (activeListings.docs.length >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You can publish maximum 3 active listings.'),
              backgroundColor: Colors.red,
            ));
            setState(() => _loading = false);
          }
          return;
        }

        updateData['createdAt'] = FieldValue.serverTimestamp();
        updateData['status'] = 'active';
        updateData['active'] = true;
        await FirebaseFirestore.instance.collection('listings').add(updateData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  widget.listingId != null
                      ? 'Listing Updated Successfully!'
                      : 'Listing Live in Database!',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.green.shade700),
        );
        context.go('/owner-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
