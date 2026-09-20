import 'dart:async';

import 'package:flutter/material.dart';

/// Brief full-screen logo while the app window opens (macOS dock icon uses AppIcon).
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.child});

  final Widget child;

  static const _asset = 'assets/brand/launch_logo.png';

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> {
  var _visible = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900)).then((_) {
        if (mounted) setState(() => _visible = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible)
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Image.asset(LaunchSplash._asset, fit: BoxFit.contain),
              ),
            ),
          ),
      ],
    );
  }
}
