import 'package:funlearn_client/data/archiveExtractor.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
Future<void> sqliteReader() async{
  final path = archiveExtractor();
  final filename = p.join(path as String, "collection.anki2");
  print(filename);

  var db = await openDatabase('anki.db');
  
}
