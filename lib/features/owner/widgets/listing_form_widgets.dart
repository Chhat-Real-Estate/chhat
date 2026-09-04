import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/datasources/remote/storage_datasource.dart';

const Color _blueDark = Color(0xFF1A237E);

class ListingSectionTitle extends StatelessWidget {
  final String title;
  const ListingSectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A)));
  }
}

class ListingInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const ListingInputField(
      {super.key,
      required this.controller,
      required this.hint,
      this.prefix,
      this.keyboardType,
      this.inputFormatters});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
          fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(
            fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blueDark, width: 2)),
      ),
    );
  }
}

class ListingChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelect;

  const ListingChipSelector(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 12.0,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _blueDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _blueDark : Colors.grey.shade300),
            ),
            child: Text(
              option,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ListingMultiChipSelector extends StatefulWidget {
  final List<String> options;
  final List<String> selected;
  final Function(List<String>) onChanged;

  const ListingMultiChipSelector(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged});

  @override
  State<ListingMultiChipSelector> createState() =>
      _ListingMultiChipSelectorState();
}

class _ListingMultiChipSelectorState extends State<ListingMultiChipSelector> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 12.0,
      children: widget.options.map((option) {
        final isSelected = widget.selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected
                  ? widget.selected.remove(option)
                  : widget.selected.add(option);
            });
            widget.onChanged(widget.selected);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _blueDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _blueDark : Colors.grey.shade300),
            ),
            child: Text(
              option,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ListingPhotoPicker extends StatefulWidget {
  final List<String> initialPhotos;
  final Function(List<String>) onPhotosChanged;
  final String propertyKind;

  const ListingPhotoPicker(
      {super.key,
      this.initialPhotos = const [],
      required this.onPhotosChanged,
      this.propertyKind = 'residential'});

  @override
  State<ListingPhotoPicker> createState() => _ListingPhotoPickerState();
}

class _ListingPhotoPickerState extends State<ListingPhotoPicker> {
  final List<String?> _uploadedUrls = List.filled(5, null);
  final List<Uint8List?> _previewBytes = List.filled(5, null);
  final List<bool> _isUploading = List.filled(5, false);
  final _storage = StorageDatasource();

  static const List<String> _commercialPhotoLabels = [
    'Front View\n(Entry/Reception)',
    'Inside Room\n(Office/Workspace)',
    'Toilet\n(Washroom)',
    'Water Area\n(Pantry/Kitchen)',
    'Building/Galli\n(Parking/Entrance)',
  ];

  static const List<String> _residentialPhotoLabels = [
    'Room View\n(Room/Bedroom)',
    'Living Area\n(Common Area)',
    'Toilet\n(Washroom)',
    'Water Area\n(Kitchen/Cooking)',
    'Building/Galli\n(Building/Entrance)',
  ];

  List<String> get photoLabels => widget.propertyKind == 'commercial'
      ? _commercialPhotoLabels
      : _residentialPhotoLabels;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.initialPhotos.length && i < 5; i++) {
      _uploadedUrls[i] = widget.initialPhotos[i];
    }
  }

  Future<void> _pickAndUpload(int index) async {
    final file = await _storage.pickImage();
    if (file == null) return;

    setState(() => _isUploading[index] = true);

    try {
      final bytes = await file.readAsBytes();
      setState(() => _previewBytes[index] = bytes);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'unknown_owner';

      final url = await _storage.uploadPhoto(file, userId);
      setState(() => _uploadedUrls[index] = url);

      widget.onPhotosChanged(_uploadedUrls.whereType<String>().toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      setState(() => _previewBytes[index] = null);
    } finally {
      if (mounted) setState(() => _isUploading[index] = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _previewBytes[index] = null;
      _uploadedUrls[index] = null;
    });
    widget.onPhotosChanged(_uploadedUrls.whereType<String>().toList());
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        final bytes = _previewBytes[index];
        final url = _uploadedUrls[index];
        final uploading = _isUploading[index];

        return GestureDetector(
          onTap: () => (bytes == null && url == null && !uploading)
              ? _pickAndUpload(index)
              : null,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: uploading
                ? const Center(
                    child: CircularProgressIndicator(color: _blueDark))
                : bytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(bytes, fit: BoxFit.cover),
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
                    : url != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(url, fit: BoxFit.cover),
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
                              const Icon(Icons.add_a_photo,
                                  color: _blueDark, size: 32),
                              const SizedBox(height: 12),
                              Text(photoLabels[index],
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF666666)),
                                  textAlign: TextAlign.center),
                            ],
                          ),
          ),
        );
      },
    );
  }
}
