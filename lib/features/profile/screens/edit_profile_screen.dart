import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends StatefulWidget {
  final String activeRole;
  const EditProfileScreen({super.key, required this.activeRole});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _subAreaController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = '';

  late Color _themeColor;
  late List<Color> _gradientColors;

  @override
  void initState() {
    super.initState();
    if (widget.activeRole == 'tenant') {
      _themeColor = const Color(0xFFC62828); // Cherry Red
      _gradientColors = [const Color(0xFFC62828), const Color(0xFFEF5350)];
    } else {
      _themeColor = const Color(0xFF1A237E); // Blueberry
      _gradientColors = [const Color(0xFF1A237E), const Color(0xFF3949AB)];
    }
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _subAreaController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final supabase = Supabase.instance.client;

      // 1. users table se data fetch karo
      final userData = await supabase
          .from('users')
          .select('name, phone')
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? userId;
      }

      // 2. Specific profile table se baaki data fetch karo
      final tableName =
          widget.activeRole == 'tenant' ? 'tenant_profiles' : 'owner_profiles';
      final profileData = await supabase
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (profileData != null) {
        if (_nameController.text.isEmpty) {
          _nameController.text = profileData['name'] ?? '';
        }
        _cityController.text = profileData['city'] ?? '';
        _areaController.text = profileData['area'] ?? '';
        _subAreaController.text = (profileData['sub_area'] ?? profileData['subArea']) ?? '';

        if (widget.activeRole == 'tenant') {
          _ageController.text = (profileData['age'] ?? '').toString();
          if (_ageController.text == '0') _ageController.text = '';
          _selectedGender = profileData['gender'] ?? '';
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final supabase = Supabase.instance.client;
      final tableName =
          widget.activeRole == 'tenant' ? 'tenant_profiles' : 'owner_profiles';

      Map<String, dynamic> updateData = {
        'user_id': userId,
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'sub_area': _subAreaController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.activeRole == 'tenant') {
        updateData['age'] = int.tryParse(_ageController.text.trim()) ?? 0;
        updateData['gender'] = _selectedGender;
      }

      await supabase.from(tableName).upsert(updateData);

      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile Updated Successfully!'),
            backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF666666)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _themeColor, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: _themeColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop()),
                const Expanded(
                    child: Text('Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _themeColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                            controller: _nameController,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500), // FIX: Black Text
                            decoration:
                                _inputDeco('Full Name')), // FIX: Made Editable
                        const SizedBox(height: 20),
                        TextField(
                            controller: _phoneController,
                            readOnly: true, // Phone number cannot be changed
                            style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500),
                            decoration: _inputDeco('Mobile Number')
                                .copyWith(fillColor: const Color(0xFFEFEFEF))),
                        const SizedBox(height: 20),
                        TextField(
                            controller: _cityController,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500), // FIX: Black Text
                            decoration: _inputDeco('City (e.g. Mumbai)')),
                        const SizedBox(height: 20),
                        TextField(
                            controller: _areaController,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                            decoration: _inputDeco('Area (e.g. Andheri East)')),
                        const SizedBox(height: 20),
                        TextField(
                            controller: _subAreaController,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                            decoration:
                                _inputDeco('Sub-Area (e.g. Barkot Ali Nagar)')),
                        const SizedBox(height: 20),
                        if (widget.activeRole == 'tenant') ...[
                          TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              decoration: _inputDeco('Age')),
                          const SizedBox(height: 20),
                          // Gender Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedGender.isEmpty
                                ? null
                                : _selectedGender,
                            decoration: _inputDeco('Gender'),
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 16),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'Female', child: Text('Female')),
                              DropdownMenuItem(
                                  value: 'Other', child: Text('Other')),
                              DropdownMenuItem(
                                  value: 'Prefer not to say',
                                  child: Text('Prefer not to say')),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedGender = val ?? ''),
                          ),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: _gradientColors),
                                borderRadius: BorderRadius.circular(16)),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Save Changes',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
