import 'dart:convert';
import 'dart:io';

import 'package:funlearn_client/data/archiveExtractor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'databaseHelper.dart';
import 'models/card.dart';
import 'models/deck.dart';

Future<void> sqliteReader() async{
  //sqfliteFfiInit();

  //databaseFactory = databaseFactoryFfi;

  final path = await archiveExtractor();
  if (path==null){
    return;
  }
  print(path);
  //newer Anki .apkg have both collection.anki2 and collection.anki21
  // with the main information being in collection.anki21
  //old: only collection.anki2
  final ankiVersion = await getAnkiVersionString(path as String);
  final fileName = p.join(path as String, ankiVersion);
  final appDocDir = await getApplicationDocumentsDirectory();
  final targetDbPath = p.join(appDocDir.path, ankiVersion);
  final sourceFile = File(fileName);
  final targetFile = File(targetDbPath);
  if (await targetFile.exists()){
    await targetFile.delete();
  }
  await sourceFile.copy(targetDbPath);
  final dbHelper = DatabaseHelper();
  //read the collection.anki2
  final ankidb = await openDatabase(targetDbPath, readOnly: true);
  final db = await dbHelper.database;
  final deckJSON = await ankidb.query("col",columns: ["decks"]);
  print(deckJSON.runtimeType);
  final deck = jsonDecode(deckJSON.first["decks"] as String) as Map<String, dynamic>;
  for (final entry in deck.entries) {
    final deckId = entry.key;
    final name = entry.value["name"];
    print("ID: $deckId   | Name: $name");
    //from the database structure as defined here: https://github.com/ankidroid/Anki-Android/wiki/Database-Structure
    final query = await ankidb.rawQuery("SELECT DISTINCT notes.sfld, notes.flds from notes, cards WHERE cards.nid = notes.id AND ? = cards.did;", [deckId]);
    print(query.length);
    if (query.isNotEmpty) {
      final deckId = await dbHelper.insertDeck(Deck(name: name));
      for (var row in query) {
        await dbHelper.insertCard(Card(deckId: deckId,front: row["sfld"] as String, back: row["flds"] as String));
      }
      (await dbHelper.getCardsByDeck(deckId))
          .forEach((row) => print('${row.deckId}${row.cardId}${row.front}${row.back}'));

    }
  };
  await ankidb.close();
}
Future<String> getAnkiVersionString(String folderPath) async {
  final fileAnki21 = File(p.join(folderPath, 'collection.anki21'));
  final existsAnki21 = await fileAnki21.exists();
  if (existsAnki21){
    return "collection.anki21";
  } else {
    return "collection.anki2";
  }
}
