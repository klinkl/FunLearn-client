import 'ankiDbReader.dart';
import 'ankiDbWriter.dart';
import 'apkgExtractor.dart';
import 'apkgSource.dart';

class ApkgImportService {
  final ApkgSource source;
  final ApkgExtractor extractor;
  final AnkiDbReader reader;
  final AnkiDbWriter writer;

  ApkgImportService({
    required this.source,
    required this.extractor,
    required this.reader,
    required this.writer,
  });

  Future<void> importApkg() async {
    final apkgPath = await source.getApkgPath();
    if (apkgPath == null) return;
    final extractedPath = await extractor.extract(apkgPath);
    final anki = await reader.read(extractedPath);
    await writer.save(anki);
  }
}
