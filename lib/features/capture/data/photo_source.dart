import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// A photo the user chose, ready to analyze.
class CapturedPhoto {
  const CapturedPhoto({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

enum PhotoOrigin { camera, gallery }

/// Where photos come from. Behind an interface so tests inject bytes without
/// the platform picker.
abstract interface class PhotoSource {
  /// Returns the chosen photo, or null if the user cancelled.
  Future<CapturedPhoto?> pick(PhotoOrigin origin);
}

/// Uses the platform camera and gallery via `image_picker`.
class ImagePickerPhotoSource implements PhotoSource {
  ImagePickerPhotoSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CapturedPhoto?> pick(PhotoOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == PhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Downscale before upload: plenty for recognition, smaller payload.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (file == null) return null;
    return CapturedPhoto(
      bytes: await file.readAsBytes(),
      mimeType: _mimeTypeFor(file),
    );
  }

  static String _mimeTypeFor(XFile file) {
    final declared = file.mimeType;
    if (declared != null && declared.startsWith('image/')) return declared;
    return file.name.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
  }
}
