import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import './card_creation_view.dart';
import '../widgets/user_info.dart';
import '../widgets/sample_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: SampleCard(cardName: 'addition')),
                SizedBox(width: 16),
                Card(child: SampleCard(cardName: 'addition')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: SampleCard(cardName: 'addition')),
                SizedBox(width: 16),
                Card(child: SampleCard(cardName: 'english-french')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: SampleCard(cardName: 'english-french')),
                SizedBox(width: 16),
                Card(child: SampleCard(cardName: 'english-french')),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FlashcardCreatorView()),
          );
        },
        backgroundColor: customColors.addButton,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
