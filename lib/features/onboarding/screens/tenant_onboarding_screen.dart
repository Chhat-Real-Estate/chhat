import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Database
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local Storage
import '../../../core/constants/property_options.dart'; // NAYA IMPORT
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TenantOnboardingScreen extends StatefulWidget {
  const TenantOnboardingScreen({super.key});

  @override
  State<TenantOnboardingScreen> createState() => _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends State<TenantOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int get _totalPages => _stepTitles.length;

  // Form State
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController(); // DB Match Fix
  final _areaController = TextEditingController();
  final _subAreaController = TextEditingController();

  String _propertyKind = 'residential'; // 'residential' | 'commercial'
  String _tenantType = '';
  String _occupation = '';
  List<String> _propertyReq = []; // Multiple selection ke liye List bana diya
  String _moveIn = '';
  String _budgetRange = '';
  String _selectedGender = '';
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreDraft();
    });
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tenant_draft_exists', true);
      await prefs.setInt('tenant_draft_step', _currentPage);
      await prefs.setString('tenant_draft_name', _nameController.text);
      await prefs.setString('tenant_draft_age', _ageController.text);
      await prefs.setString('tenant_draft_city', _cityController.text);
      await prefs.setString('tenant_draft_area', _areaController.text);
      await prefs.setString('tenant_draft_sub_area', _subAreaController.text);
      await prefs.setString('tenant_draft_property_kind', _propertyKind);
      await prefs.setString('tenant_draft_tenant_type', _tenantType);
      await prefs.setString('tenant_draft_occupation', _occupation);
      await prefs.setStringList('tenant_draft_property_req', _propertyReq);
      await prefs.setString('tenant_draft_move_in', _moveIn);
      await prefs.setString('tenant_draft_budget_range', _budgetRange);
      await prefs.setString('tenant_draft_gender', _selectedGender);
    } catch (e) {
      debugPrint('Error saving tenant draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('tenant_draft_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  Future<void> _checkAndRestoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDraft = prefs.getBool('tenant_draft_exists') ?? false;
    final savedStep = prefs.getInt('tenant_draft_step') ?? 0;
    final draftName = prefs.getString('tenant_draft_name') ?? '';

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
            Icon(Icons.history_rounded, color: Color(0xFFC62828)),
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
              backgroundColor: const Color(0xFFC62828),
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
        _nameController.text = prefs.getString('tenant_draft_name') ?? _nameController.text;
        _ageController.text = prefs.getString('tenant_draft_age') ?? '';
        _cityController.text = prefs.getString('tenant_draft_city') ?? '';
        _areaController.text = prefs.getString('tenant_draft_area') ?? '';
        _subAreaController.text = prefs.getString('tenant_draft_sub_area') ?? '';
        _propertyKind = prefs.getString('tenant_draft_property_kind') ?? _propertyKind;
        _tenantType = prefs.getString('tenant_draft_tenant_type') ?? _tenantType;
        _occupation = prefs.getString('tenant_draft_occupation') ?? _occupation;
        _propertyReq = prefs.getStringList('tenant_draft_property_req') ?? _propertyReq;
        _moveIn = prefs.getString('tenant_draft_move_in') ?? _moveIn;
        _budgetRange = prefs.getString('tenant_draft_budget_range') ?? _budgetRange;
        _selectedGender = prefs.getString('tenant_draft_gender') ?? _selectedGender;

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
    return [
      {'title': 'Your Details', 'icon': Icons.person_pin_circle_outlined},
      {'title': 'Roommates', 'icon': Icons.group_outlined},
      {'title': 'Occupation', 'icon': Icons.work_outline},
      {'title': 'Location', 'icon': Icons.location_on_outlined},
      {'title': 'Property Kind', 'icon': Icons.apartment_outlined},
      {'title': 'Property Type', 'icon': Icons.home_work_outlined},
      {'title': 'Move-in Date', 'icon': Icons.calendar_month_outlined},
      {'title': 'Budget Range', 'icon': Icons.account_balance_wallet_outlined},
    ];
  }

  void _nextPage() {
    final currentTitle = _stepTitles[_currentPage]['title'];

    // Hard Validations
    if (currentTitle == 'Your Details') {
      if (_nameController.text.trim().length < 3) {
        _showError('Please enter full name (min 3 letters)');
        return;
      }
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 18 || age > 99) {
        _showError('Please enter a valid age (18 to 99)');
        return;
      }
      if (_selectedGender.isEmpty) {
        _showError('Please select your gender');
        return;
      }
    } else if (currentTitle == 'Roommates' && _tenantType.isEmpty) {
      _showError('Please select who you will live with');
      return;
    } else if (currentTitle == 'Occupation' && _occupation.isEmpty) {
      _showError('Please select your occupation');
      return;
    } else if (currentTitle == 'Location' &&
        _areaController.text.trim().isEmpty) {
      _showError('Please enter an area or use location');
      return;
    } else if (currentTitle == 'Property Type' && _propertyReq.isEmpty) {
      _showError('Please select a property type');
      return;
    } else if (currentTitle == 'Move-in Date' && _moveIn.isEmpty) {
      _showError('Please select a move-in timeline');
      return;
    } else if (currentTitle == 'Budget Range' && _budgetRange.isEmpty) {
      _showError('Please select your budget range');
      return;
    }

    if (_currentPage < _totalPages - 1) {
      _saveDraft();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveDraft();
      _submitForm();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD32F2F)),
    );
  }

  Future<void> _submitForm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      // SECURITY FIX #6: unknown_user fallback hataya — null ho to login pe bhejo
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expire ho gaya, dobara login karo')),
          );
          context.go('/phone');
        }
        return;
      }
      final supabase = Supabase.instance.client;

      // 1. Tenant Profile Data Prepare Karo
      final tenantData = {
        'user_id': userId,
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _selectedGender,
        'tenant_type': _tenantType,
        'occupation': _occupation,
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'sub_area': _subAreaController.text.trim(),
        'property_kind': _propertyKind,
        'property_requirements': _propertyReq,
        'move_in_date': _moveIn,
        'budget_range': _budgetRange,
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 2. Database me 'tenant_profiles' table me upsert karo
      await supabase.from('tenant_profiles').upsert(tenantData);

      // 3. User document update karo
      await supabase.from('users').update({
        'profile_complete': true,
        'active_role': 'tenant',
        'roles': ['tenant'],
        'name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Cache update
      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userRole', 'tenant');
      await prefs.setBool('profileComplete', true);

      // Clear local draft
      await _clearDraft();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile saved in Database!'),
              backgroundColor: Colors.green),
        );
        context.go('/tenant-home');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Skip Details?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        content: const Text(
          'Are you sure you want to skip? Owners might reject you to avoid delay. Fill the requirements to get verified matches.',
          style: TextStyle(color: Color(0xFF666666), height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No',
                style: TextStyle(
                    color: Color(0xFF666666), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
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
                  'active_role': 'tenant',
                  'roles': ['tenant'],
                  'profile_complete': true,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', userId);
                await prefs.setString('userRole', 'tenant');
                await prefs.setBool('profileComplete', true);
                await _clearDraft();
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile setup skipped.')),
                );
                context.go('/tenant-home');
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildStep1Basic(),
      _buildSelectionGrid([
        'Single Bachelor',
        'Single Female',
        'Family',
        'Couple',
        'Bachelor Group',
        'Student',
        'Worker'
      ], _tenantType, (val) => setState(() => _tenantType = val)),
      _buildSelectionGrid([
        'Job',
        'Business',
        'Professional',
        'Student',
        'Freelancer',
        'GIG Worker',
        'Worker',
        'Other'
      ], _occupation, (val) => setState(() => _occupation = val)),
      _buildStepArea(),
      _buildPropertyKindStep(),
      _buildMultiSelectionGrid(
          _propertyKind == 'commercial'
              ? PropertyOptions.commercialCategories
              : PropertyOptions.residentialCategories,
          _propertyReq, (val) {
        setState(() {
          if (_propertyReq.contains(val)) {
            _propertyReq.remove(val);
          } else {
            _propertyReq.add(val);
          }
        });
      }),
      _buildSelectionGrid(
          ['Immediately', 'Within 7 Days', 'Within 15 Days', 'Within 30 Days'],
          _moveIn,
          (val) => setState(() => _moveIn = val)),
      _buildSelectionGrid([
        'Below ₹5,000',
        '₹5,000 - ₹10,000',
        '₹10,000 - ₹15,000',
        '₹15,000 - ₹20,000',
        'Above ₹20,000'
      ], _budgetRange, (val) => setState(() => _budgetRange = val)),
    ];
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
    _ageController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _subAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2), // Light off-white background
      body: SafeArea(
        child: Column(
          children: [
            // Unified Cherry Red Top Header Box
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC62828), Color(0xFFEF5350)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Top actions: Back & Skip inside red box
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
                              curve: Curves.easeInOut,
                            );
                          } else {
                            context
                                .pop(); // Page 1 se direct pichli screen pe back
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
                  // Icon and Title
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
                  // Progress Bar
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

            // 4. Form Content (PageView)
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

            // 5. Cherry Red Gradient "Continue" Button
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC62828),
                      Color(0xFFEF5350)
                    ], // Cherry Red Gradient
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.red.withOpacity(0.3),
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
                  onPressed: _nextPage,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _totalPages - 1
                            ? 'Save Profile'
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
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFFD32F2F), width: 2), // Red Focus
      ),
    );
  }

  Widget _buildStep1Basic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Full Name',
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
            ],
            decoration: _cleanInputDeco('e.g. Rahul Sharma'),
          ),
          const SizedBox(height: 24),
          const Text('Age',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500),
            decoration: _cleanInputDeco('e.g. 25').copyWith(counterText: ""),
          ),
          const SizedBox(height: 24),
          const Text('Gender',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
          const SizedBox(height: 12),
          Row(
            children: ['Male', 'Female'].map((gender) {
              final isSelected = _selectedGender == gender;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = gender),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFFFEBEE) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(
                        gender,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF1A1A1A),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepArea() {
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
            decoration: _cleanInputDeco('e.g. Mumbai'),
          ),
          const SizedBox(height: 24),
          const Text('Area',
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
            decoration: _cleanInputDeco('e.g. Andheri West'),
          ),
          const SizedBox(height: 24),
          const Text('Sub-Area (Optional)',
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
            decoration: _cleanInputDeco('e.g. Lokhandwala'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFD32F2F)))
                  : const Icon(Icons.my_location, color: Color(0xFFD32F2F)),
              label: Text(
                  _isFetchingLocation
                      ? 'Fetching GPS...'
                      : 'Use Current Location',
                  style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD32F2F)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
          const Text('Aapko Residential chahiye ya Commercial property?',
              style: TextStyle(color: Color(0xFF666666), fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _propertyKind = 'residential';
                    _propertyReq = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: _propertyKind == 'residential'
                          ? const Color(0xFFC62828)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _propertyKind == 'residential'
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 32,
                            color: _propertyKind == 'residential'
                                ? Colors.white
                                : const Color(0xFFC62828)),
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
                    _propertyReq = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: _propertyKind == 'commercial'
                          ? const Color(0xFFC62828)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _propertyKind == 'commercial'
                              ? const Color(0xFFC62828)
                              : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 32,
                            color: _propertyKind == 'commercial'
                                ? Colors.white
                                : const Color(0xFFC62828)),
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

  Widget _buildSelectionGrid(
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
                color: isSelected
                    ? const Color(0xFFD32F2F)
                    : Colors.white, // Cherry Red Selection
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                ],
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFFE0E0E0)),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                  fontSize: 15,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Naya Multi-Select Widget
  Widget _buildMultiSelectionGrid(List<String> options,
      List<String> selectedValues, Function(String) onSelect) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 16.0,
        children: options.map((option) {
          final isSelected = selectedValues.contains(option);
          return GestureDetector(
            onTap: () => onSelect(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD32F2F)
                    : Colors.white, // Cherry Red
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                ],
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : const Color(0xFF4A4A4A),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
