import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/card.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as p;

import 'package:funlearn_client/data/apkgImport/ankiDbReader.dart';
import 'package:funlearn_client/data/apkgImport/ankiDbWriter.dart';
import 'package:funlearn_client/data/apkgImport/apkgExtractor.dart';
import 'package:funlearn_client/data/apkgImport/apkgImportService.dart';
import 'package:funlearn_client/data/apkgImport/apkgSource.dart';
import 'apkgImport_test.mocks.dart';

@GenerateMocks([ApkgSource, AnkiDbReader, AnkiDbWriter, ApkgExtractor])
void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper();
    await resetDatabase(dbHelper);
  });
  tearDown(() async {
    await resetDatabase(dbHelper);
  });
  test('getAnkiVersionString returns correct version', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final anki21 = File(p.join(tempDir.path, 'collection.anki21'));
    await anki21.writeAsString('dummy');
    expect(await getAnkiVersionString(tempDir.path), 'collection.anki21');

    final anki2 = File(p.join(tempDir.path, 'collection.anki2'));
    await anki2.writeAsString('dummy');
    await anki21.delete();
    expect(await getAnkiVersionString(tempDir.path), 'collection.anki2');
  });
  group('Apkg import integration', () {
    late Directory tempDir;
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      tempDir = Directory.systemTemp.createTempSync();

      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory' ||
            methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });
    });

    tearDown(() {
      channel.setMockMethodCallHandler(null);
      tempDir.deleteSync(recursive: true);
    });
    test("importing an apkg", () async {
      var mockSource = MockApkgSource();
      when(
        mockSource.getApkgPath(),
      ).thenAnswer((_) async => 'test/assets/Colors_in_Germany.apkg');
      final ApkgImportService importService = ApkgImportService(
        source: mockSource,
        extractor: ApkgExtractor(),
        reader: AnkiDbReader(),
        writer: AnkiDbWriter(dbHelper),
      );
      await importService.importApkg();
      final List<Deck> decks = await dbHelper.getDecks();
      final id = decks.first.deckId;
      expect(decks.length, 1);
      expect(decks.first.name, 'Farben');
      final cards = await dbHelper.getCardsByDeck(id!);
      expect(cards.length, isNotNull);
    });
    test("null as path", () async {
      var mockSource = MockApkgSource();
      final mockExtractor = MockApkgExtractor();
      final mockReader = MockAnkiDbReader();
      final mockWriter = MockAnkiDbWriter();
      when(mockSource.getApkgPath()).thenAnswer((_) async => null);
      final ApkgImportService importService = ApkgImportService(
        source: mockSource,
        extractor: mockExtractor,
        reader: mockReader,
        writer: mockWriter,
      );
      await importService.importApkg();
      verifyNever(mockExtractor.extract(any));
      verifyNever(mockReader.read(any));
      verifyNever(mockWriter.save(any));
    });
    test("apkgExtractor works", () async {
      var path = 'test/assets/Colors_in_Germany.apkg';
      final extractor = ApkgExtractor();
      final extractPath = await extractor.extract(path);
      final extractedFile = File(p.join(extractPath, 'collection.anki2'));
      expect(await extractedFile.exists(), true);
    });
  });
  test("ankiDbWriter correctly writes deck and cards to DB", () async {
    var deck = Deck(deckId: 1, name: "Test Deck A");
    var card = Card(cardId: 1, deckId: 1, front: "Front", back: "Back");
    final writer = AnkiDbWriter(dbHelper);
    await writer.save(([deck], [card]));
    final List<Deck> decks = await dbHelper.getDecks();
    final id = decks.first.deckId;
    expect(decks.length, 1);
    expect(decks.first.name, 'Test Deck A');
    final cards = await dbHelper.getCardsByDeck(id!);
    expect(cards.length, isNotNull);
    expect(cards.first.front, "Front");
    expect(cards.first.back, "Back");
  });
}

Future<void> resetDatabase(DatabaseHelper dbHelper) async {
  final db = await dbHelper.database;
  await db.delete('Card');
  await db.delete('Deck');
  // Reset auto-increment counters
  await db.execute("DELETE FROM sqlite_sequence WHERE name='Deck'");
  await db.execute("DELETE FROM sqlite_sequence WHERE name='Card'");
}
