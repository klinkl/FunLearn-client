import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? card;
  final Color? navigationBar;
  final Color? navigationIcon;
  final Color? addButton;

  const CustomColors({
    this.card,
    this.navigationBar,
    this.navigationIcon,
    this.addButton,
  });

  @override
  CustomColors copyWith({
    Color? card,
    Color? navigationBar,
    Color? navigationIcon,
    Color? addButton,
  }) {
    return CustomColors(
      card: card ?? this.card,
      navigationBar: navigationBar ?? this.navigationBar,
      navigationIcon: navigationIcon ?? this.navigationIcon,
      addButton: addButton ?? this.addButton,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      card: Color.lerp(card, other.card, t),
      navigationBar: Color.lerp(navigationBar, other.navigationBar, t),
      navigationIcon: Color.lerp(navigationIcon, other.navigationIcon, t),
      addButton: Color.lerp(addButton, other.addButton, t),
    );
  }
}
