import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import '../data/userController.dart';

class SettingView extends StatefulWidget {
  const SettingView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.userController,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final UserController userController;

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  int _selectedIndex = 3;

  final _nameCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.userController.currentUser?.username ?? "User";
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Widget _statChip(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withOpacity(0.15)),
      ),
      child: Text("$label: $value", style: TextStyle(color: cs.onSurface)),
    );
  }

  Widget _buildProfileCard(ColorScheme cs) {
    final user = widget.userController.currentUser;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profil",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            isDense: true,
                          ),
                        )
                      : Text(
                          user?.username ?? "User",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                ),

                const SizedBox(width: 8),

                if (_saving)
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (!_editing)
                  IconButton(
                    tooltip: "Change",
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _editing = true),
                  )
                else
                  IconButton(
                    tooltip: "Save",
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      setState(() => _saving = true);

                      await widget.userController.updateUsername(
                        _nameCtrl.text,
                      );
                      final me = widget.userController.currentUser;
                      if (me != null) {
                        final refreshed = await widget.userController
                            .refreshFromServer(me.userId);
                      }
                      setState(() {
                        _saving = false;
                        _editing = false;
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statChip("Level", "${user?.level ?? 1}", cs),
                _statChip("XP", "${user?.totalXP ?? 0}", cs),
                _statChip("Streak", "${user?.currentStreak ?? 0}", cs),
                _statChip(
                  "Cards Learned",
                  "${user?.totalCardsLearned ?? 0}",
                  cs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.userController,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final customColors = Theme.of(context).extension<CustomColors>()!;

        final isLightActive = Theme.of(context).brightness == Brightness.light;
        final isDarkActive = Theme.of(context).brightness == Brightness.dark;

        ButtonStyle adaptiveButtonStyle(bool active) {
          return ElevatedButton.styleFrom(
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,

            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: active ? cs.primary : cs.onSurface.withOpacity(0.25),
                width: active ? 3 : 1,
              ),
            ),
            elevation: active ? 3 : 0,
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
              child: Stack(
                children: [
                  Center(
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
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileCard(cs),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: buildIconTextButton(
                            active: isLightActive,
                            icon: Icons.light_mode,
                            label: 'Light',
                            onPressed: () =>
                                widget.onThemeModeChanged(ThemeMode.light),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: buildIconTextButton(
                            active: isDarkActive,
                            icon: Icons.dark_mode,
                            label: 'Dark',
                            onPressed: () =>
                                widget.onThemeModeChanged(ThemeMode.dark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
