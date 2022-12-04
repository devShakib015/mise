import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class MyFavoriteFoodsPage extends StatelessWidget {
  const MyFavoriteFoodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Foods'),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Ionicons.search_outline)),
        ],
      ),
      body: ListView(
        children: const [],
      ),
    );
  }
}
