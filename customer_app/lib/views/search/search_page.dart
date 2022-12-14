import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/field_card.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FieldCard(
          child: TextField(
            controller: _searchController,
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search',
              prefixIcon: const Icon(Ionicons.search_outline),
              suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Ionicons.close_outline)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          children: [
            for (var i = 0; i < 10; i++) const FoodItemListTile(),
          ],
        ),
      ),
    );
  }
}
