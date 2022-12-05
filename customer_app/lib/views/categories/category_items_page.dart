import 'package:customer_app/views/categories/categories_page.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CategoryItemsPage extends StatefulWidget {
  final String title;
  const CategoryItemsPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      initialIndex:
          categories.indexWhere((element) => element.title == widget.title),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Categories"),
          bottom: TabBar(
            isScrollable: true,
            tabs: categories.map((e) {
              return Tab(
                text: e.title,
              );
            }).toList(),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Ionicons.search_outline),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Ionicons.ellipsis_horizontal_circle_outline),
            ),
          ],
        ),
        body: TabBarView(
          children: categories.map((e) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < 10; i++) const FoodItemListTile(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
