
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

//follows the .apkg file structure as defined as here: https://github.com/ankidroid/Anki-Android/wiki/Database-Structure
Future<String?> archiveExtractor() async {

  final result = await FilePicker.platform.pickFiles(
    allowedExtensions: ['apkg'],
    type: FileType.custom,
  );
  if (result==null){return null;}
  final apkgPath = result.files.single.path!;
  final bytes = File(apkgPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  // Extract to a temp folder
  final dir = await getTemporaryDirectory();
  final extractPath = p.join(dir.path, "apkg_extract_${DateTime.now().millisecondsSinceEpoch}");
  await Directory(extractPath).create();

  for (final file in archive) {
    final filePath = p.join(extractPath, file.name);
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    } else {
      await Directory(filePath).create(recursive: true);
    }
  }

  return extractPath;
}
