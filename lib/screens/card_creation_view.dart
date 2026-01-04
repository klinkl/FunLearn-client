import 'package:flutter/material.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import '../data/databaseHelper.dart';
import '../theme/customColors.dart';

class FlashcardCreatorView extends StatefulWidget {
  const FlashcardCreatorView({super.key});

  @override
  State<FlashcardCreatorView> createState() => _FlashcardCreatorViewState();
}

class _FlashcardCreatorViewState extends State<FlashcardCreatorView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  final List<Map<String, String>> _tempCards = [];
  var currentIndex = 0;

  void _loadCard() {
    if (currentIndex < 0) {
      currentIndex = 0;
    }
    if (currentIndex >= _tempCards.length) {
      if (currentIndex > _tempCards.length) {
        currentIndex = currentIndex - 1;
      }
      _frontController.clear();
      _backController.clear();
      return;
    }
    _frontController.text = _tempCards[currentIndex]['front']!;
    _backController.text = _tempCards[currentIndex]['back']!;
  }

  void _lastCard() {
    setState(() {
      _saveCard();
      currentIndex = currentIndex - 1;
      _loadCard();
    });
  }

  void _nextCard() {
    setState(() {
      _saveCard();
      currentIndex = currentIndex + 1;
      _loadCard();
    });
  }

  void _saveCard() {
    if (_frontController.text.isEmpty || _backController.text.isEmpty) return;

    if (currentIndex < _tempCards.length) {
      _tempCards[currentIndex] = {
        'front': _frontController.text,
        'back': _backController.text,
      };
    } else {
      _tempCards.add({
        'front': _frontController.text,
        'back': _backController.text,
      });
    }
    _frontController.clear();
    _backController.clear();
  }

  Future<void> _saveDeck() async {
    // temporary
    if (_titleController.text.isEmpty) return;

    if (_frontController.text.isNotEmpty && _backController.text.isNotEmpty) {
      _tempCards.add({
        'front': _frontController.text,
        'back': _backController.text,
      });
    }
    if (_tempCards.isEmpty) return;
    final dbHelper = DatabaseHelper(dbPath: 'database.db');
    final deckId = await dbHelper.insertDeck(Deck(name: _titleController.text));
    for (var card in _tempCards) {
      await dbHelper.insertCard(
        Flashcard(deckId: deckId, front: card['front']!, back: card['back']!),
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deck saved !')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: screenHeight * 0.33,
              padding: const EdgeInsets.all(16),
              color: cs.surface,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Center(
                    child: TextField(
                      controller: _titleController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Deck Title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: cs.surface,
                child: Column(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _frontController,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            labelText: 'Front',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Flexible(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _backController,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            labelText: 'Back',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: _lastCard,
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveDeck,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: _nextCard,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      flex: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Card ${currentIndex + 1} of ${_tempCards.length + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
