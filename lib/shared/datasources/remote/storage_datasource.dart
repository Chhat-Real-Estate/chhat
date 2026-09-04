import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageDatasource {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
  }

  Future<String> uploadPhoto(XFile file, String ownerId) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = '$ownerId/${const Uuid().v4()}.jpg';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('listings').uploadBinary(
            filename,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return supabase.storage.from('listings').getPublicUrl(filename);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
