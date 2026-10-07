import 'package:flutter/material.dart';

/// Full-screen scaffold for management modules opened from the dashboard hub.
/// List screens stay scaffold-free so they can also be embedded as tabs.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({
    super.key,
    required this.title,
    required this.child,
    this.onAdd,
  });

  final String title;
  final Widget child;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: onAdd == null
          ? null
          : FloatingActionButton(
              onPressed: onAdd,
              tooltip: title,
              child: const Icon(Icons.add),
            ),
      body: child,
    );
  }
}