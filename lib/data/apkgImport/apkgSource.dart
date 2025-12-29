import 'package:file_picker/file_picker.dart';

abstract class ApkgSource {
  Future<String?> getApkgPath();
}

class FilePickerApkgSource implements ApkgSource {
  @override
  Future<String?> getApkgPath() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apkg']
    );
    return result?.files.single.path;
  }
}
