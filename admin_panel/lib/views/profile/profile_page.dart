import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Profile'),
        actions: [
          ToolBarIconButton(
            label: "Logout",
            icon: const Icon(Icons.logout),
            showLabel: false,
            onPressed: () {},
            tooltipMessage: "Logout",
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Container(
              color: Colors.red,
            );
          },
        ),
      ],
    );
  }
}
