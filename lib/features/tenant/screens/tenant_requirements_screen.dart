import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../repositories/tenant_profile_repository.dart'; // NAYA: Clean Architecture Repo
import '../../../core/constants/property_options.dart'; // NAYA IMPORT

class TenantRequirementsScreen extends StatefulWidget {
  const TenantRequirementsScreen({super.key});

  @override
  State<TenantRequirementsScreen> createState() =>
      _TenantRequirementsScreenState();
}

class _TenantRequirementsScreenState extends State<TenantRequirementsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  String _propertyKind = 'residential'; // 'residential' | 'commercial'
  String? _tenantType;
  String? _occupation;
  String? _moveIn;
  String? _budgetRange;
  List<String> _propertyReq = [];

  final Color _themeColor = const Color(0xFFC62828); // Cherry Red

  final List<String> _tenantTypeOptions = [
    'Single Bachelor',
    'Single Female',
    'Family',
    'Couple',
    'Bachelor Group',
    'Student',
    'Worker'
  ];
  final List<String> _occupationOptions = [
    'Job',
    'Business',
    'Professional',
    'Student',
    'Freelancer',
    'GIG Worker',
    'Worker',
    'Other'
  ];
  final List<String> _moveInOptions = [
    'Immediately',
    'Within 7 Days',
    'Within 15 Days',
    'Within 30 Days'
  ];
  final List<String> _budgetOptions = [
    'Below ₹5,000',
    '₹5,000 - ₹10,000',
    '₹10,000 - ₹15,000',
    '₹15,000 - ₹20,000',
    'Above ₹20,000'
  ];
  List<String> get _propertyOptions => _propertyKind == 'commercial'
      ? PropertyOptions.commercialCategories
      : PropertyOptions.residentialCategories;

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

  Future<void> _fetchRequirements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      // NAYA: Repo pattern se data fetch karna
      final data = await TenantProfileRepository().getTenantProfile(userId);

      if (data != null) {
        setState(() {
          _propertyKind = data['propertyKind'] ?? 'residential';
          _tenantType = _validateOption(data['tenantType'], _tenantTypeOptions);
          _occupation = _validateOption(data['occupation'], _occupationOptions);
          _moveIn = _validateOption(data['moveInDate'], _moveInOptions);
          _budgetRange = _validateOption(data['budgetRange'], _budgetOptions);

          if (data['propertyRequirements'] != null) {
            _propertyReq = List<String>.from(data['propertyRequirements']);
          }
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateOption(String? value, List<String> options) {
    if (value != null && options.contains(value)) return value;
    return null;
  }

  Future<void> _saveRequirements() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      Map<String, dynamic> updateData = {
        'propertyKind': _propertyKind,
        'tenantType': _tenantType ?? '',
        'occupation': _occupation ?? '',
        'moveInDate': _moveIn ?? '',
        'budgetRange': _budgetRange ?? '',
        'propertyRequirements': _propertyReq,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // NAYA: Repo pattern se save karna
      await TenantProfileRepository().saveTenantProfile(userId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Requirements Updated Successfully!'),
            backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating requirements: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDropdown(String label, String? currentValue,
      List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: _themeColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _themeColor, width: 2)),
          ),
          items: options
              .map((opt) => DropdownMenuItem(
                  value: opt,
                  child:
                      Text(opt, style: const TextStyle(color: Colors.black))))
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => context.pop()),
        title: const Text('My Requirements',
            style: TextStyle(
                color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Kind',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'residential',
                          groupValue: _propertyKind,
                          activeColor: _themeColor,
                          title: const Text('Residential',
                              style: TextStyle(fontSize: 14)),
                          onChanged: (val) => setState(() {
                            _propertyKind = val!;
                            _propertyReq = [];
                            // FIX: kind badalne par purane residential/commercial
                            // specific answers reset karo — dono ke options
                            // alag hain, purani value dikhana confusing hai.
                            _tenantType = null;
                            _occupation = null;
                          }),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'commercial',
                          groupValue: _propertyKind,
                          activeColor: _themeColor,
                          title: const Text('Commercial',
                              style: TextStyle(fontSize: 14)),
                          onChanged: (val) => setState(() {
                            _propertyKind = val!;
                            _propertyReq = [];
                            _tenantType = null;
                            _occupation = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // FIX: Commercial ke liye "Who will live" aur "Occupation"
                  // (residential-only, personal questions) ki jagah business
                  // se related sawaal — ab dono kind ke liye contextually
                  // sahi cheez poochta hai.
                  _buildDropdown(
                      _propertyKind == 'commercial'
                          ? 'Business Type'
                          : 'Who will live? (Tenant Type)',
                      _tenantType,
                      _propertyKind == 'commercial'
                          ? PropertyOptions.suitableFor
                          : _tenantTypeOptions,
                      (v) => setState(() => _tenantType = v)),
                  if (_propertyKind == 'residential')
                    _buildDropdown(
                        'Occupation',
                        _occupation,
                        _occupationOptions,
                        (v) => setState(() => _occupation = v)),
                  _buildDropdown('When to move in?', _moveIn, _moveInOptions,
                      (v) => setState(() => _moveIn = v)),
                  _buildDropdown('Budget Range', _budgetRange, _budgetOptions,
                      (v) => setState(() => _budgetRange = v)),
                  const Text('Property Requirements (Select Multiple)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 12.0,
                    children: _propertyOptions.map((option) {
                      final isSelected = _propertyReq.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: _themeColor,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                            color: isSelected
                                ? _themeColor
                                : const Color(0xFFE0E0E0)),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4A4A4A),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (bool selected) {
                          setState(() {
                            selected
                                ? _propertyReq.add(option)
                                : _propertyReq.remove(option);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSaving ? null : _saveRequirements,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Requirements',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
