import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ApkgExtractor {
  Future<String> extract(String apkgPath) async {
    final bytes = File(apkgPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dir = await getTemporaryDirectory();
    final extractPath = p.join(dir.path, "apkg_${DateTime.now().millisecondsSinceEpoch}");
    await Directory(extractPath).create();

    for (final file in archive) {
      final outPath = p.join(extractPath, file.name);
      if (file.isFile) {
        await File(outPath).create(recursive: true);
        await File(outPath).writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    return extractPath;
  }
}
