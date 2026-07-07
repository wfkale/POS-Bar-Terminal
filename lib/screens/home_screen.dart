import 'package:flutter/material.dart';
import 'package:pos_bar_core/pos_bar_core.dart';

/// Thin alias so bar_terminal keeps its existing import path.
class HomeScreen extends FloorHomeScreen {
  const HomeScreen({
    super.key,
    required super.api,
    required super.session,
    required VoidCallback onLogout,
  }) : super(onLogout: onLogout);
}
