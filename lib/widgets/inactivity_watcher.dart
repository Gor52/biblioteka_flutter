import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _dialogOpen = false;

  static const _totalTimeout = Duration(minutes: 3);
  static const _warningTime = Duration(seconds: 30);

  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _startTimers();
  }

  bool _onKey(KeyEvent event) {
    _handleInteraction();
    return false; 
  }

  void _handleInteraction() {
    final now = DateTime.now();
    if (now.difference(_lastInteraction).inMilliseconds > 500) {
      _lastInteraction = now;
      _startTimers();
    }
  }

  void _startTimers() {
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }

    _warningTimer?.cancel();
    _logoutTimer?.cancel();

    _warningTimer = Timer(_totalTimeout - _warningTime, _showWarning);
    _logoutTimer = Timer(_totalTimeout, _performLogout);
  }

  void _showWarning() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Сессия истекает'),
        content: Text('Вы будете отключены через ${_warningTime.inSeconds} секунд из-за неактивности.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); 
              _dialogOpen = false;
              _handleInteraction(); 
            },
            child: const Text('Остаться'),
          ),
        ],
      ),
    ).then((_) => _dialogOpen = false);
  }

  void _performLogout() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }

    auth.logout();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleInteraction(),
      onPointerMove: (_) => _handleInteraction(),
      onPointerSignal: (_) => _handleInteraction(), 
      child: widget.child,
    );
  }
}