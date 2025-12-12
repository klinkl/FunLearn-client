import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import '../widgets/navigationBar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: _SampleCard(cardName: 'Card 1')),
                SizedBox(width: 16),
                Card(child: _SampleCard(cardName: 'Card 2')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: _SampleCard(cardName: 'Card 3')),
                SizedBox(width: 16),
                Card(child: _SampleCard(cardName: 'Card 4')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Card(child: _SampleCard(cardName: 'Card 5')),
                SizedBox(width: 16),
                Card(child: _SampleCard(cardName: 'Card 6')),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        backgroundColor: customColors.addButton,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String cardName;
  const _SampleCard({required this.cardName, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    return SizedBox(
      width: 150,
      height: 100,
      child: Card(
        color: customColors.card,
        child: Center(
          child: Text(cardName, style: TextStyle(color: cs.onSurface)),
        ),
      ),
    );
  }
}
