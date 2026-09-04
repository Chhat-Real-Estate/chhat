import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Photo Picker
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart'; // Database
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local Storage
import '../../../shared/datasources/remote/storage_datasource.dart'; // FIX: Storage API Add kiya
import '../../../core/constants/property_options.dart'; // NAYA IMPORT
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;
  int get _totalPages => _stepTitles.length;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
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

  // Selections
  String _propertyKind = 'residential'; // 'residential' | 'commercial'
  String _propertyCategory = '';
  String _furnishingStatus = '';
  String _parkingType = '';
  String _availability = '';

  // Commercial Only
  List<String> _suitableFor = [];
  List<String> _utilities = [];
  String _buildingGrade = '';
  String _buildingAge = '';
  String _possession = '';
  String _ownership = '';
  List<String> _visibility = [];

  final List<String> _selectedFacilities = [];
  final List<String> _selectedTenants = [];
  final List<String> _selectedRestrictions = [];
  bool _isFetchingLocation = false;

  // Image Picker State
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _selectedPhotos = List.filled(5, null);

  // Blueberry Gradient Colors
  final Color _blueberryDark = const Color(0xFF1A237E);
  final Color _blueberryLight = const Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreDraft();
    });
  }

  // FIX: Pehle field hardcoded "9876543210" dikhata tha — ab asli verified
  // phone number load hoga
  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ?? '';
    if (mounted) {
      setState(() => _phoneController.text = phone);
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('owner_draft_exists', true);
      await prefs.setInt('owner_draft_step', _currentPage);
      await prefs.setString('owner_draft_name', _nameController.text);
      await prefs.setString('owner_draft_phone', _phoneController.text);
      await prefs.setString('owner_draft_city', _cityController.text);
      await prefs.setString('owner_draft_area', _areaController.text);
      await prefs.setString('owner_draft_sub_area', _subAreaController.text);
      await prefs.setString('owner_draft_landmark', _landmarkController.text);
      await prefs.setString('owner_draft_distance', _distanceController.text);
      await prefs.setString('owner_draft_rent', _rentController.text);
      await prefs.setString('owner_draft_deposit', _depositController.text);
      await prefs.setString('owner_draft_size', _sizeController.text);
      await prefs.setString('owner_draft_floor', _floorController.text);
      await prefs.setString('owner_draft_occupancy', _occupancyController.text);
      await prefs.setString('owner_draft_built_up_area', _builtUpAreaController.text);
      await prefs.setString('owner_draft_super_built_up_area', _superBuiltUpAreaController.text);
      await prefs.setString('owner_draft_plot_area', _plotAreaController.text);
      await prefs.setString('owner_draft_total_floors', _totalFloorsController.text);
      await prefs.setString('owner_draft_ceiling_height', _ceilingHeightController.text);
      await prefs.setString('owner_draft_frontage', _frontageController.text);
      await prefs.setString('owner_draft_road_width', _roadWidthController.text);

      await prefs.setString('owner_draft_property_kind', _propertyKind);
      await prefs.setString('owner_draft_property_category', _propertyCategory);
      await prefs.setString('owner_draft_furnishing_status', _furnishingStatus);
      await prefs.setString('owner_draft_parking_type', _parkingType);
      await prefs.setString('owner_draft_availability', _availability);

      await prefs.setString('owner_draft_building_grade', _buildingGrade);
      await prefs.setString('owner_draft_building_age', _buildingAge);
      await prefs.setString('owner_draft_possession', _possession);
      await prefs.setString('owner_draft_ownership', _ownership);

      await prefs.setStringList('owner_draft_suitable_for', _suitableFor);
      await prefs.setStringList('owner_draft_utilities', _utilities);
      await prefs.setStringList('owner_draft_visibility', _visibility);
      await prefs.setStringList('owner_draft_selected_facilities', _selectedFacilities);
      await prefs.setStringList('owner_draft_selected_tenants', _selectedTenants);
      await prefs.setStringList('owner_draft_selected_restrictions', _selectedRestrictions);
    } catch (e) {
      debugPrint('Error saving owner draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('owner_draft_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  Future<void> _checkAndRestoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDraft = prefs.getBool('owner_draft_exists') ?? false;
    final savedStep = prefs.getInt('owner_draft_step') ?? 0;
    final draftName = prefs.getString('owner_draft_name') ?? '';

    if (!hasDraft && savedStep == 0 && draftName.isEmpty) {
      return;
    }

    if (!mounted) return;

    final shouldResume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFF1A237E)),
            SizedBox(width: 8),
            Text('Resume Form?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Adhoora form mila, wahin se continue karein?',
          style: TextStyle(fontSize: 15, color: Color(0xFF444444)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nahi, Naya Shuru Karein', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Haan, Continue Karein', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldResume == true) {
      setState(() {
        _nameController.text = prefs.getString('owner_draft_name') ?? _nameController.text;
        _phoneController.text = prefs.getString('owner_draft_phone') ?? _phoneController.text;
        _cityController.text = prefs.getString('owner_draft_city') ?? '';
        _areaController.text = prefs.getString('owner_draft_area') ?? '';
        _subAreaController.text = prefs.getString('owner_draft_sub_area') ?? '';
        _landmarkController.text = prefs.getString('owner_draft_landmark') ?? '';
        _distanceController.text = prefs.getString('owner_draft_distance') ?? '';
        _rentController.text = prefs.getString('owner_draft_rent') ?? '';
        _depositController.text = prefs.getString('owner_draft_deposit') ?? '';
        _sizeController.text = prefs.getString('owner_draft_size') ?? '';
        _floorController.text = prefs.getString('owner_draft_floor') ?? '';
        _occupancyController.text = prefs.getString('owner_draft_occupancy') ?? '';
        _builtUpAreaController.text = prefs.getString('owner_draft_built_up_area') ?? '';
        _superBuiltUpAreaController.text = prefs.getString('owner_draft_super_built_up_area') ?? '';
        _plotAreaController.text = prefs.getString('owner_draft_plot_area') ?? '';
        _totalFloorsController.text = prefs.getString('owner_draft_total_floors') ?? '';
        _ceilingHeightController.text = prefs.getString('owner_draft_ceiling_height') ?? '';
        _frontageController.text = prefs.getString('owner_draft_frontage') ?? '';
        _roadWidthController.text = prefs.getString('owner_draft_road_width') ?? '';

        _propertyKind = prefs.getString('owner_draft_property_kind') ?? _propertyKind;
        _propertyCategory = prefs.getString('owner_draft_property_category') ?? _propertyCategory;
        _furnishingStatus = prefs.getString('owner_draft_furnishing_status') ?? _furnishingStatus;
        _parkingType = prefs.getString('owner_draft_parking_type') ?? _parkingType;
        _availability = prefs.getString('owner_draft_availability') ?? _availability;

        _buildingGrade = prefs.getString('owner_draft_building_grade') ?? _buildingGrade;
        _buildingAge = prefs.getString('owner_draft_building_age') ?? _buildingAge;
        _possession = prefs.getString('owner_draft_possession') ?? _possession;
        _ownership = prefs.getString('owner_draft_ownership') ?? _ownership;

        _suitableFor = prefs.getStringList('owner_draft_suitable_for') ?? _suitableFor;
        _utilities = prefs.getStringList('owner_draft_utilities') ?? _utilities;
        _visibility = prefs.getStringList('owner_draft_visibility') ?? _visibility;

        _selectedFacilities.clear();
        _selectedFacilities.addAll(prefs.getStringList('owner_draft_selected_facilities') ?? []);

        _selectedTenants.clear();
        _selectedTenants.addAll(prefs.getStringList('owner_draft_selected_tenants') ?? []);

        _selectedRestrictions.clear();
        _selectedRestrictions.addAll(prefs.getStringList('owner_draft_selected_restrictions') ?? []);

        final targetPage = savedStep.clamp(0, _totalPages - 1);
        _currentPage = targetPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    } else {
      await _clearDraft();
    }
  }

  List<Map<String, dynamic>> get _stepTitles {
    final isCommercial = _propertyKind == 'commercial';
    return [
      {'title': 'Owner Details', 'icon': Icons.person_pin_circle_outlined},
      {'title': 'Property Kind', 'icon': Icons.apartment_outlined},
      {'title': 'Property Category', 'icon': Icons.category_outlined},
      {'title': 'Furnishing & Parking', 'icon': Icons.chair_outlined},
      {'title': 'Property Location', 'icon': Icons.location_on_outlined},
      if (isCommercial)
        {'title': 'Visibility', 'icon': Icons.visibility_outlined},
      {'title': 'Pricing', 'icon': Icons.currency_rupee_outlined},
      {'title': 'Property Details', 'icon': Icons.info_outline},
      {'title': 'Facilities', 'icon': Icons.weekend_outlined},
      {
        'title': isCommercial ? 'Suitable For' : 'Allowed Tenants',
        'icon': isCommercial
            ? Icons.business_center_outlined
            : Icons.group_add_outlined
      },
      {'title': 'Restrictions', 'icon': Icons.block_outlined},
      if (isCommercial)
        {'title': 'Utilities', 'icon': Icons.electrical_services_outlined},
      if (isCommercial)
        {'title': 'Building Info', 'icon': Icons.business_outlined},
      if (isCommercial) {'title': 'Possession', 'icon': Icons.key_outlined},
      if (isCommercial)
        {'title': 'Ownership', 'icon': Icons.assignment_ind_outlined},
      {'title': 'Property Photos', 'icon': Icons.add_a_photo_outlined},
      {'title': 'Availability', 'icon': Icons.event_available_outlined},
    ];
  }

  List<Widget> _buildPages() {
    final isCommercial = _propertyKind == 'commercial';
    return [
      _buildStep1Basic(),
      _buildPropertyKindStep(),
      _buildSingleSelectGrid(
          isCommercial
              ? PropertyOptions.commercialCategories
              : PropertyOptions.residentialCategories,
          _propertyCategory,
          (v) => setState(() => _propertyCategory = v)),
      _buildFurnishingParkingStep(),
      _buildStep3Location(),
      if (isCommercial)
        _buildMultiSelectGrid(
            PropertyOptions.commercialVisibility, _visibility),
      _buildStep4Pricing(),
      _buildStep5Details(),
      _buildMultiSelectGrid([
        if (!isCommercial) 'Furnished',
        'Attached Toilet',
        'Shared Toilet',
        'Water Supply - Indoor',
        'Water Supply - Outdoor',
        'WiFi',
        if (isCommercial) 'Canteen' else 'Cooking Allowed',
      ], _selectedFacilities),
      isCommercial
          ? _buildMultiSelectGrid(PropertyOptions.suitableFor, _suitableFor)
          : _buildMultiSelectGrid([
              'Single Bachelor',
              'Single Female',
              'Family',
              'Couple',
              'Bachelor Group',
              'Student',
              'Worker'
            ], _selectedTenants),
      _buildMultiSelectGrid(
          isCommercial
              ? PropertyOptions.commercialRestrictions
              : ['No Smoking', 'No Drinking', 'No Pets', 'No Non-Veg'],
          _selectedRestrictions),
      if (isCommercial)
        _buildMultiSelectGrid(PropertyOptions.commercialUtilities, _utilities),
      if (isCommercial) _buildBuildingInfoStep(),
      if (isCommercial)
        _buildSingleSelectGrid(PropertyOptions.commercialPossession,
            _possession, (v) => setState(() => _possession = v)),
      if (isCommercial)
        _buildSingleSelectGrid(PropertyOptions.commercialOwnership, _ownership,
            (v) => setState(() => _ownership = v)),
      _buildStep9Photos(),
      _buildSingleSelectGrid(
          ['Immediately', 'Within 7 Days', 'Within 15 Days', 'Within 30 Days'],
          _availability,
          (v) => setState(() => _availability = v)),
    ];
  }

  void _nextPage() {
    final currentTitle = _stepTitles[_currentPage]['title'];

    if (currentTitle == 'Owner Details') {
      if (_nameController.text.trim().length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Enter a valid name'),
            backgroundColor: Color(0xFF1A237E)));
        return;
      }
      String cleanPhone =
          _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }
      if (cleanPhone.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sahi 10 digit ka mobile number daalo'),
            backgroundColor: Color(0xFF1A237E)));
        return;
      }
    }
    if (currentTitle == 'Property Category' && _propertyCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Property type select karein'),
          backgroundColor: Color(0xFF1A237E)));
      return;
    }
    if (currentTitle == 'Pricing') {
      final rent = int.tryParse(_rentController.text.trim()) ?? 0;
      final deposit = int.tryParse(_depositController.text.trim()) ?? 0;
      if (rent <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rent 0 se zyada hona chahiye'),
            backgroundColor: Color(0xFF1A237E)));
        return;
      }
      if (deposit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Deposit 0 ya usse zyada hona chahiye'),
            backgroundColor: Color(0xFF1A237E)));
        return;
      }
    }
    if (currentTitle == 'Property Details') {
      final size = int.tryParse(_sizeController.text.trim()) ?? 0;
      if (size <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Property size (sqft) 0 se zyada hona chahiye'),
            backgroundColor: Color(0xFF1A237E)));
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      _saveDraft();
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveDraft();
      _submitForm();
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('Session expire ho gaya, dobara login karo');
      }
      final supabase = Supabase.instance.client;

      String rawPhone =
          prefs.getString('userPhone') ?? _phoneController.text.trim();
      String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }
      rawPhone = '+91$cleanPhone';

      // 1. Users table update karo
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'phone': rawPhone,
        'profile_complete': true,
        'active_role': 'owner',
        'roles': ['owner'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 2. Owner profile update karo
      await supabase.from('owner_profiles').upsert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. First Listing create karo
      final insertedListing = await supabase.from('listings').insert({
        'owner_id': userId,
        'property_kind': _propertyKind,
        'property_category': _propertyCategory,
        'furnishing_status': _furnishingStatus,
        'parking_type': _parkingType,
        'phone': rawPhone,
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim().toLowerCase(),
        'sub_area': _subAreaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'distance_km': double.tryParse(_distanceController.text.trim()) ?? 0.0,
        'rent': int.tryParse(_rentController.text.trim()) ?? 0,
        'deposit': int.tryParse(_depositController.text.trim()) ?? 0,
        'size_sqft': int.tryParse(_sizeController.text.trim()) ?? 0,
        'floor': _floorController.text.trim(),
        'occupancy': int.tryParse(_occupancyController.text.trim()) ?? 0,
        'facilities': _selectedFacilities,
        'allowed_tenants': _selectedTenants,
        'restrictions': _selectedRestrictions,
        'availability': _availability,
        'created_at': DateTime.now().toIso8601String(),
        'active': true,
        'photos': <String>[],
        'built_up_area': _builtUpAreaController.text.trim(),
        'super_built_up_area': _superBuiltUpAreaController.text.trim(),
        'plot_area': _plotAreaController.text.trim(),
        'total_floors': _totalFloorsController.text.trim(),
        'ceiling_height': _ceilingHeightController.text.trim(),
        'frontage': _frontageController.text.trim(),
        'road_width': _roadWidthController.text.trim(),
        'suitable_for': _suitableFor,
        'utilities': _utilities,
        'building_grade': _buildingGrade,
        'building_age': _buildingAge,
        'possession': _possession,
        'ownership': _ownership,
        'visibility': _visibility,
      }).select('id').single();

      final newListingId = insertedListing['id'].toString();

      // Cache bhi update karo (batch commit ke baad)
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userRole', 'owner');
      await prefs.setString('userPhone', rawPhone);
      await prefs.setBool('profileComplete', true);

      // Upload photos to Supabase Storage
      final storage = StorageDatasource();
      final photosToUpload = _selectedPhotos.whereType<XFile>().toList();
      final uploadResults = await Future.wait(
        photosToUpload.map((photo) => storage
                .uploadPhoto(photo, userId)
                .then<String?>((url) => url)
                .catchError((e) {
              debugPrint('Photo upload error: $e');
              return null;
            })),
      );
      final uploadedUrls = uploadResults.whereType<String>().toList();
      final failedCount = photosToUpload.length - uploadedUrls.length;

      // Update document with actual secure URLs
      if (uploadedUrls.isNotEmpty) {
        await supabase
            .from('listings')
            .update({'photos': uploadedUrls}).eq('id', newListingId);
      }

      // Clear local draft upon successful submission
      await _clearDraft();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(failedCount > 0
                ? 'Listing Live! Lekin $failedCount photo(s) upload nahi ho payi.'
                : 'Listing Live in Database!'),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green));
        context.go('/owner-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _blueberryDark),
            const SizedBox(width: 8),
            const Text('Skip Listing?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        content: const Text(
          'Are you sure you want to skip listing, You can make listing later.',
          style: TextStyle(color: Color(0xFF666666), height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NO',
                style: TextStyle(
                    color: Color(0xFF666666), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _blueberryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
                // SECURITY FIX #6: unknown_user fallback hataya
                if (userId == null || userId.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session expire ho gaya, dobara login karo')),
                    );
                    context.go('/phone');
                  }
                  return;
                }
                await Supabase.instance.client
                    .from('users')
                    .update({
                  'active_role': 'owner',
                  'roles': ['owner'],
                  'profile_complete': true,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', userId);
                await prefs.setString('userRole', 'owner');
                await prefs.setBool('profileComplete', true);
                await _clearDraft();
              } catch (_) {}
              if (mounted) context.go('/owner-home');
            },
            child: const Text('YES', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable device location services.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable in settings.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final subLocality = place.subLocality ?? place.thoroughfare ?? '';
        final locality = place.locality ?? place.subAdministrativeArea ?? '';
        final detectedCity = place.locality ?? place.administrativeArea ?? '';

        final areaText = [subLocality, locality].where((s) => s.trim().isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            if (areaText.isNotEmpty) {
              _areaController.text = areaText;
            }
            if (detectedCity.isNotEmpty && _cityController.text.trim().isEmpty) {
              _cityController.text = detectedCity;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location detected successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: SafeArea(
        child: Column(
          children: [
            // Unified Blueberry Top Header Box
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_blueberryDark, _blueberryLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (_currentPage > 0) {
                            _saveDraft();
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          } else {
                            context.pop();
                          }
                        },
                      ),
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text('Skip',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Icon(_stepTitles[_currentPage]['icon'],
                      color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _stepTitles[_currentPage]['title'],
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_currentPage + 1) / _totalPages,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${((_currentPage + 1) / _totalPages * 100).toInt()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _saveDraft();
                },
                children: _buildPages(),
              ),
            ),

            // Bottom Continue Button
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blueberryDark, _blueberryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _blueberryDark.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSubmitting ? null : _nextPage,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _totalPages - 1
                            ? 'Publish Property'
                            : 'Continue',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                      if (_currentPage < _totalPages - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UI WIDGETS ---

  InputDecoration _cleanInputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _blueberryDark, width: 2)),
    );
  }

  Widget _buildStep1Basic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Owner Name',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _nameController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
              ], // Sirf Alphabets allowed
              decoration: _cleanInputDeco('Pura naam daaliye')),
          const SizedBox(height: 24),
          const Text('Mobile Number',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _phoneController,
              readOnly: true,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('')
                  .copyWith(fillColor: Colors.grey.shade100)),
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('City',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _cityController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. Mumbai')),
          const SizedBox(height: 24),
          const Text('Area / Locality',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _areaController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. Andheri East')),
          const SizedBox(height: 24),
          const Text('Sub Area',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _subAreaController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. Marol')),
          const SizedBox(height: 24),
          const Text('Landmark',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _landmarkController,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. Near Metro Station')),
          const SizedBox(height: 24),
          const Text('Distance from Station/Highway (in km)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _distanceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ], // Sirf numbers aur dot allowed
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 2.5')),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              icon: _isFetchingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _blueberryDark))
                  : Icon(Icons.my_location, color: _blueberryDark),
              label: Text(
                  _isFetchingLocation
                      ? 'Fetching GPS...'
                      : 'Use Current Location',
                  style: TextStyle(
                      color: _blueberryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _blueberryDark),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPropertyKindStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Residential hai ya Commercial?',
              style: TextStyle(color: Color(0xFF666666), fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _propertyKind = 'residential';
                    _propertyCategory = '';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: _propertyKind == 'residential'
                          ? _blueberryDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _propertyKind == 'residential'
                              ? _blueberryDark
                              : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 32,
                            color: _propertyKind == 'residential'
                                ? Colors.white
                                : _blueberryDark),
                        const SizedBox(height: 8),
                        Text('Residential',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _propertyKind == 'residential'
                                    ? Colors.white
                                    : const Color(0xFF4A4A4A))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _propertyKind = 'commercial';
                    _propertyCategory = '';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: _propertyKind == 'commercial'
                          ? _blueberryDark
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _propertyKind == 'commercial'
                              ? _blueberryDark
                              : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 32,
                            color: _propertyKind == 'commercial'
                                ? Colors.white
                                : _blueberryDark),
                        const SizedBox(height: 8),
                        Text('Commercial',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _propertyKind == 'commercial'
                                    ? Colors.white
                                    : const Color(0xFF4A4A4A))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFurnishingParkingStep() {
    final isCommercial = _propertyKind == 'commercial';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Furnishing Status',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          _buildInlineChips(
              isCommercial
                  ? PropertyOptions.commercialFurnishing
                  : PropertyOptions.residentialFurnishing,
              _furnishingStatus,
              (v) => setState(() => _furnishingStatus = v)),
          const SizedBox(height: 28),
          const Text('Parking',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          _buildInlineChips(
              isCommercial
                  ? PropertyOptions.commercialParking
                  : const ['None', 'Bike Only', 'Car Only', 'Bike + Car'],
              _parkingType,
              (v) => setState(() => _parkingType = v)),
        ],
      ),
    );
  }

  Widget _buildInlineChips(
      List<String> options, String selectedValue, Function(String) onSelect) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 16.0,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _blueberryDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? _blueberryDark : const Color(0xFFE0E0E0)),
            ),
            child: Text(option,
                style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                    fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBuildingInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Building Grade',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          _buildInlineChips(PropertyOptions.buildingGrades, _buildingGrade,
              (v) => setState(() => _buildingGrade = v)),
          const SizedBox(height: 28),
          const Text('Building Age',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          _buildInlineChips(PropertyOptions.buildingAges, _buildingAge,
              (v) => setState(() => _buildingAge = v)),
          const SizedBox(height: 28),
          const Text('Commercial Area Details (Optional)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          TextField(
              controller: _builtUpAreaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _cleanInputDeco('Built-up Area (sqft) (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _superBuiltUpAreaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  _cleanInputDeco('Super Built-up Area (sqft) (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _plotAreaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _cleanInputDeco('Plot Area (sqft) (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _totalFloorsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  _cleanInputDeco('Total Floors in Building (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _ceilingHeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _cleanInputDeco('Ceiling Height (ft) (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _frontageController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _cleanInputDeco('Frontage (ft) (Optional)')),
          const SizedBox(height: 16),
          TextField(
              controller: _roadWidthController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _cleanInputDeco('Road Width (ft) (Optional)')),
        ],
      ),
    );
  }

  Widget _buildStep4Pricing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rent Amount (₹)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _rentController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Strictly Digits Only
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 5000')),
          const SizedBox(height: 24),
          const Text('Deposit Amount (₹)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _depositController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Strictly Digits Only
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 20000')),
        ],
      ),
    );
  }

  Widget _buildStep5Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Room Size (sqft)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _sizeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Strictly Digits Only
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 150')),
          const SizedBox(height: 24),
          const Text('Floor Number (0 for Ground)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _floorController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Strictly Digits Only
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 0 or 2')),
          const SizedBox(height: 24),
          const Text('Maximum Occupancy',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
              controller: _occupancyController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ], // Strictly Digits Only
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500),
              decoration: _cleanInputDeco('e.g. 3 log')),
        ],
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70); // Auto Compress
    if (image != null) {
      setState(() => _selectedPhotos[index] = image);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedPhotos[index] = null);
  }

  Widget _buildStep9Photos() {
    final isCommercial = _propertyKind == 'commercial';
    List<String> photoLabels = [
      'Front View',
      isCommercial ? 'Inside Office' : 'Inside Room',
      'Toilet',
      isCommercial ? 'Parking' : 'Water Area',
      'Building/Galli'
    ];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Achhi photos se jaldi tenant milta hai.',
              style: TextStyle(color: Color(0xFF666666), fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.compress, color: _blueberryDark, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text(
                        'Photos will be automatically compressed before upload to save data.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF3949AB)))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                final photo = _selectedPhotos[index];
                return GestureDetector(
                  onTap: () => photo == null ? _pickImage(index) : null,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16)),
                    child: photo != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? Image.network(photo.path, fit: BoxFit.cover)
                                  : Image.file(File(photo.path),
                                      fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: _blueberryDark, size: 32),
                              const SizedBox(height: 12),
                              Text(photoLabels[index],
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666))),
                            ],
                          ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSingleSelectGrid(
      List<String> options, String selectedValue, Function(String) onSelect) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 16.0,
        children: options.map((option) {
          final isSelected = selectedValue == option;
          return GestureDetector(
            onTap: () => onSelect(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _blueberryDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                ],
                border: Border.all(
                    color:
                        isSelected ? _blueberryDark : const Color(0xFFE0E0E0)),
              ),
              child: Text(option,
                  style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : const Color(0xFF4A4A4A),
                      fontSize: 15)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultiSelectGrid(
      List<String> options, List<String> selectedList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 16.0,
        children: options.map((option) {
          final isSelected = selectedList.contains(option);
          return GestureDetector(
            onTap: () => setState(() {
              isSelected
                  ? selectedList.remove(option)
                  : selectedList.add(option);
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _blueberryDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                ],
                border: Border.all(
                    color:
                        isSelected ? _blueberryDark : const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(Icons.check, color: Colors.white, size: 18),
                  if (isSelected) const SizedBox(width: 6),
                  Text(option,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4A4A4A),
                          fontSize: 15)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
