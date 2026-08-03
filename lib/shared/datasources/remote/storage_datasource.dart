import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageDatasource {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality:
          80, // FIX: Ye automatic compress kar dega bina quality loss ke
    );
  }

  Future<String> uploadPhoto(XFile file, String ownerId) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = '$ownerId/${const Uuid().v4()}.jpg';

      // firebase_options.dart wala hi default bucket use ho raha hai
      final ref =
          FirebaseStorage.instance.ref().child('listings').child(filename);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
