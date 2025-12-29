import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../databaseHelper.dart';

class AnkiDbReader {
  Future<(List<Deck>, List<Flashcard>)> read(String folderPath) async {
    final dbFileName = await getAnkiVersionString(folderPath);
    final appDir = await getApplicationDocumentsDirectory();

    final source = File(p.join(folderPath, dbFileName));
    final dest = File(p.join(appDir.path, dbFileName));

    if (await dest.exists()) await dest.delete();
    await source.copy(dest.path);

    final db = await openDatabase(dest.path, readOnly: true);

    final deckJSON = await db.query("col", columns: ["decks"]);
    final deck = jsonDecode(deckJSON.first["decks"] as String) as Map<String, dynamic>;

    List<Map<String, Object?>> result = [];
    String deckName = "";
    List<Deck> deckList = [];
    List<Flashcard> cardList = [];
    for (final entry in deck.entries) {
      final deckId = int.parse(entry.key);
      deckName = entry.value["name"];
      //ignore default as default is always contained in col
      if(deckName =="Default"){
        continue;
      }
      if (kDebugMode) {
        print("ID: $deckId   | Name: $deckName");
      }
      //from the database structure as defined here:
      // https://github.com/ankidroid/Anki-Android/wiki/Database-Structure
       result = await db.rawQuery(
        "SELECT DISTINCT notes.sfld, notes.flds "
            "FROM notes, cards WHERE cards.nid = notes.id AND cards.did = ?",
        [deckId],
      );
      deckList.add(Deck(deckId: deckId, name: deckName));
      if (result.isNotEmpty){
        for (var row in result) {
          cardList.add(Flashcard(deckId: deckId,front: row["sfld"] as String, back: row["flds"] as String));
        }
      }

    }
    await db.close();
    return (deckList, cardList);
  }
}
//newer Anki packages have both collection.anki2 and collection.anki21
// with the main information being in collection.anki21
//old: only collection.anki2
Future<String> getAnkiVersionString(String folderPath) async {
  final fileAnki21 = File(p.join(folderPath, 'collection.anki21'));
  final existsAnki21 = await fileAnki21.exists();
  if (existsAnki21){
    return "collection.anki21";
  } else {
    return "collection.anki2";
  }
}
