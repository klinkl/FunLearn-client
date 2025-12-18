import 'package:flutter/material.dart';
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

  void _nextCard() {
    // temporary
    _frontController.clear();
    _backController.clear();
  }

  void _saveCard() {
    // temporary
    print('Titre: ${_titleController.text}');
    print('Front: ${_frontController.text}');
    print('Back: ${_backController.text}');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Card saved !')));
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
                        hintText: 'Flashcard Title',
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
                            onPressed: _nextCard,
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveCard,
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
