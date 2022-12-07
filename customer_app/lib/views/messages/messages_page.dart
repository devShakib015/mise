import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        leading: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: ThemeConstant.defaultPadding),
          child: Image.asset(Images.logo,
              color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Ionicons.search_outline),
          ),
        ],
      ),
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      //   child: Column(
      //     children: [
      //       for (var i = 0; i < 20; i++)
      //         Card(
      //           child: const ListTile(

      //             title: Text(
      //               "Lisa Kudrow",
      //               style: TextStyle(fontWeight: FontWeight.bold),
      //             ),
      //           ),
      //         ),
      //     ],
      //   ),
      // ),
    );
  }
}
