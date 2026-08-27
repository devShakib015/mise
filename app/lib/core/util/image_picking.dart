import 'package:file_picker/file_picker.dart';

import '../../data/repositories/menu_repository.dart';

/// Largest image we will upload. Menu photos come off phones at 5-10MB, which
/// is wasted bytes for a tile that renders a couple of hundred pixels wide.
const _maxUploadBytes = 3 * 1024 * 1024;

class ImagePickResult {
  const ImagePickResult({this.upload, this.error});

  final ImageUpload? upload;
  final String? error;

  bool get cancelled => upload == null && error == null;
}

/// Opens the platform file picker and returns the chosen image in memory.
///
/// Reads the bytes rather than keeping a path, so the same code works on web
/// where there is no filesystem path to hand back.
Future<ImagePickResult> pickImage() async {
  final PlatformFile? file;
  try {
    file = await FilePicker.pickFile(
      dialogTitle: 'Choose an image',
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
  } catch (err) {
    return ImagePickResult(error: 'Could not open the file picker: $err');
  }

  if (file == null) return const ImagePickResult();

  try {
    // Check the size before reading, so a huge file is rejected rather than
    // pulled into memory first.
    if (await file.length() > _maxUploadBytes) {
      final mb = (await file.length() / (1024 * 1024)).toStringAsFixed(1);
      return ImagePickResult(
        error: 'That image is ${mb}MB. Please use one under 3MB.',
      );
    }

    final bytes = await file.readAsBytes();
    return ImagePickResult(
      upload: ImageUpload(filename: file.name, bytes: bytes),
    );
  } catch (err) {
    return ImagePickResult(error: 'That file could not be read: $err');
  }
}
