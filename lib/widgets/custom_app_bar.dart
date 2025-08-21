// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:shadow_speak_v2/screens/settings_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSettings;
  final Color backgroundColor;
  final Color titleColor;
  final Color iconColor;

  /// 右側に並べるアクション（自由な Widget を置けます）
  final List<Widget> actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSettings = true,
    this.backgroundColor = Colors.white,
    this.titleColor = Colors.black,
    this.iconColor = Colors.black,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final rightActions = <Widget>[
      ...actions,
      if (showSettings)
        IconButton(
          icon: const Icon(Icons.settings),
          color: iconColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
    ];

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      actions: rightActions.isEmpty ? null : rightActions,
    );
  }
}
