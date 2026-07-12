import 'dart:async';

import 'package:flutter/material.dart';

/// Logs out a floor session after [timeout] with no pointer/keyboard activity.
class IdleLogoutScope extends StatefulWidget {
  const IdleLogoutScope({
    super.key,
    required this.enabled,
    required this.onIdle,
    required this.child,
    this.timeout = const Duration(seconds: 30),
  });

  final bool enabled;
  final VoidCallback onIdle;
  final Widget child;
  final Duration timeout;

  @override
  State<IdleLogoutScope> createState() => _IdleLogoutScopeState();
}

class _IdleLogoutScopeState extends State<IdleLogoutScope> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant IdleLogoutScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled || widget.timeout != oldWidget.timeout) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    if (!widget.enabled) return;
    _timer = Timer(widget.timeout, widget.onIdle);
  }

  void _bump() {
    if (!widget.enabled) return;
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _bump(),
      onPointerMove: (_) => _bump(),
      onPointerSignal: (_) => _bump(),
      child: Focus(
        autofocus: widget.enabled,
        onKeyEvent: (_, __) {
          _bump();
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
