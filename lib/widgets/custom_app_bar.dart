// Custom AppBar Widget
// Related: T034, FR-044, T066
// Unified app bar with profile icon for all main screens, with optional bottom widget

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({super.key, required this.title, this.bottom});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      bottom: bottom,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Mi Perfil',
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
