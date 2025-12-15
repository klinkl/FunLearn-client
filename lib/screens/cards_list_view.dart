import 'package:flutter/material.dart';

import '../data/databaseHelper.dart';
import '../data/models/deck.dart';
import '../data/sqliteReader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int _counter = 0;
  List<Deck> decks = [];

  Future<void> addNewDeck() async {
    await sqliteReader();
    await _loadDecks();
    //setState((){
    //});
  }

  @override
  void initState() {
    super.initState();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    final dbHelper = DatabaseHelper();
    final fetchedDecks = await dbHelper.getDecks();
    print(fetchedDecks.length);
    setState(() {
      decks = fetchedDecks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
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
            return Card(child: _SampleCard(cardName: decks[index].name));
          },
        ),
      ),
      //maybe use the floatingActionButton as a button to add new Anki sets?
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 70,
        childrenAnimation: ExpandableFabAnimation.none,
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.white.withOpacity(0.5),
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
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Quests'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String cardName;

  const _SampleCard({required this.cardName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 100,
      child: Center(child: Text(cardName)),
    );
  }
}
