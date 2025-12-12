import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import '../widgets/navigationBar.dart';

class SettingView extends StatefulWidget {
  const SettingView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    final isLightActive = widget.themeMode == ThemeMode.light;
    final isDarkActive = widget.themeMode == ThemeMode.dark;

    ButtonStyle adaptiveButtonStyle(bool active) {
      return ElevatedButton.styleFrom(
        backgroundColor: active ? cs.primary : cs.surface,
        foregroundColor: active ? cs.onPrimary : cs.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? cs.primary : cs.onSurface.withOpacity(0.4),
            width: active ? 2 : 1,
          ),
        ),
        elevation: active ? 6 : 0,
      );
    }

    Widget buildIconTextButton({
      required bool active,
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return ElevatedButton(
        onPressed: onPressed,
        style: adaptiveButtonStyle(active),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: buildIconTextButton(
                  active: isLightActive,
                  icon: Icons.light_mode,
                  label: 'Light',
                  onPressed: () {
                    widget.onThemeModeChanged(ThemeMode.light);
                  },
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: buildIconTextButton(
                  active: isDarkActive,
                  icon: Icons.dark_mode,
                  label: 'Dark',
                  onPressed: () {
                    widget.onThemeModeChanged(ThemeMode.dark);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
