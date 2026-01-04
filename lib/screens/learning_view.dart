import 'package:flutter/material.dart';
import '../theme/customColors.dart';
//temporary
////////////////////////////////////////////////////////
import 'package:fsrs/fsrs.dart' show Scheduler, Rating;
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';

import '../data/learningController.dart';
import '../data/databaseHelper.dart';

class MyFlashcardScreen extends StatelessWidget {
  const MyFlashcardScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    return LearningView(deck: deck);
  }
}
class LearningView extends StatefulWidget {
  final Deck deck;

  const LearningView({super.key, required this.deck});

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  Flashcard? _currentCard;
  bool _backShow = false;
  bool _loading = true;
  late final LearningController controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    controller = LearningController.getInstance(DatabaseHelper(dbPath: 'database.db'));
    super.initState();
    _initDailySession();
  }

  Future<void> _initDailySession() async {
    await controller.runDailyNewCardRelease(widget.deck.deckId!);
    await _loadNextCard();
  }

  Future<void> _loadNextCard() async {
    setState(() => _loading = true);
    final nextCard = await controller.getNextCard(widget.deck.deckId!);
    setState(() {
      _currentCard = nextCard;
      _backShow = false;
      _loading = false;
    });
  }

  Future<void> _reviewCard(Rating rating) async {
    if (_currentCard != null) {
      await controller.reviewCard(_currentCard!, rating);
      await _loadNextCard();
    }
  }

  void _show() {
    setState(() {
      _backShow = !_backShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text("Flashcard")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentCard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Flashcard")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("No cards due!", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await controller.scheduleNewCardsOnDemand(
                    widget.deck.deckId!,
                    5,
                  );
                  await _loadNextCard();
                },
                child: const Text("Release more new cards"),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Flashcard")),

      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: customColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onPrimary, width: 2),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    _currentCard!.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),

              Visibility(
                visible: _backShow,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Divider(thickness: 1, color: cs.onPrimary),
              ),

              Expanded(
                child: Visibility(
                  visible: _backShow,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Center(
                    child: Text(
                      _currentCard!.back,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _backShow
          ? Row(
              children: [
                FlashcardButton(
                  label: 'Again',
                  backgroundColor: Colors.red,
                  onPressed: () => _reviewCard(Rating.again),
                ),
                FlashcardButton(
                  label: 'Hard',
                  backgroundColor: Colors.orange,
                  onPressed: () => _reviewCard(Rating.hard),
                ),
                FlashcardButton(
                  label: 'Okay',
                  backgroundColor: Colors.green,
                  onPressed: () => _reviewCard(Rating.good),
                ),
                FlashcardButton(
                  label: 'Easy',
                  backgroundColor: Colors.blue,
                  onPressed: () => _reviewCard(Rating.easy),
                ),
              ],
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
              width: double.infinity,
              child: TextButton(
                onPressed: _show,
                style: TextButton.styleFrom(
                  backgroundColor: customColors.navigationBar,
                  foregroundColor: cs.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: Text("Show the back"),
              ),
            ),
    );
  }
}

class FlashcardButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const FlashcardButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.1,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
