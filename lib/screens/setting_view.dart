import 'package:flutter/material.dart';
import '../theme/customColors.dart';

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
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final buttonWidth = screenWidth * 0.2;
      final buttonHeight = screenHeight * 0.1;
      final iconSize = buttonHeight * 0.3;

      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: adaptiveButtonStyle(active),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: buttonHeight * 0.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
    );
  }
}
