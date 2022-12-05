import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
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
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        children: [
          for (var i = 0; i < 10; i++) const FoodItemListTile(),
        ],
      ),
    );
  }
}
