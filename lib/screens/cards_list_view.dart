import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import './card_creation_view.dart';
import '../widgets/user_info.dart';
import '../widgets/sample_card.dart';
import 'package:funlearn_client/data/apkgImport/ankiDbWriter.dart';
import 'package:funlearn_client/screens/learning_view.dart';

import '../data/apkgImport/ankiDbReader.dart';
import '../data/apkgImport/apkgExtractor.dart';
import '../data/apkgImport/apkgImportService.dart';
import '../data/apkgImport/apkgSource.dart';
import '../data/databaseHelper.dart';
import '../data/models/deck.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class CardsListView extends StatefulWidget {
  const CardsListView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CardsListView> createState() => _CardsListViewState();
}

class _CardsListViewState extends State<CardsListView> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  final dbHelper = DatabaseHelper(dbPath: 'database.db');
  List<Deck> decks = [];
  late final ApkgImportService importService = ApkgImportService(
    source: FilePickerApkgSource(),
    extractor: ApkgExtractor(),
    reader: AnkiDbReader(),
    writer: AnkiDbWriter(dbHelper),
  );

  Future<void> addNewDeck() async {
    await importService.importApkg();
    await _loadDecks();
    //setState((){
    //});
  }

  @override
  void initState() {
    super.initState();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    //dbHelper.resetDatabase();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final fetchedDecks = await dbHelper.getDecks();
    if (kDebugMode) {
      print(fetchedDecks.length);
    }
    setState(() {
      decks = fetchedDecks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme
        .of(context)
        .colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final crossAxisCount = width > 1000 ? 3 : 2;

    return Scaffold(
        body: SafeArea(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              const SizedBox(height: 32),

          const Userinfo(
            profilPicture: 'assets/images/default_pfp.png',
            userName: 'Eliott',
            exp: 125,
            expNextLevel: 250,
            level: 12,
            streak: 7,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                itemCount: decks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: width / 80,
                  mainAxisSpacing: width / 80,
                  childAspectRatio: 2,
                ),
                itemBuilder: (context, index) {
                  return Card(child: _SampleCard(cardName: decks[index].name,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LearningView(deck: decks[index])
                          ),
                        );
                      },
                  ),
                  );
                },
              ),
            ),
          ),
              ],
          ),
        ),
      //maybe use the floatingActionButton as a button to add new Anki sets?
    floatingActionButtonLocation: ExpandableFab.location,
    floatingActionButton: ExpandableFab(
    type: ExpandableFabType.up,
    distance: 70,
    childrenAnimation: ExpandableFabAnimation.none,
    overlayStyle: ExpandableFabOverlayStyle(
    color: Colors.white.withOpacity(0.9),
    ),
    children: [
    Row(
    children: [
    Text('Import from .akpg'),
    SizedBox(width: 20),
    FloatingActionButton.small(
    heroTag: null,
    onPressed: () async {
    await addNewDeck();
    },
    child: const Icon(Icons.file_open),
    ),
    ],
    ),
    Row(
    children: [
    Text('Create new deck'),
    SizedBox(width: 20),
    FloatingActionButton.small(
    heroTag: null,
    child: const Icon(Icons.add),
    onPressed: () async{
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => FlashcardCreatorView()),
    );
    }

    ),
    ],
    ),
    ],
    ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String cardName;
  final VoidCallback? onTap;

  const _SampleCard({required this.cardName, this.onTap,});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
          width: 150,
          height: 100,
          child: Center(
              child: Text(cardName))),
    );
  }
}
