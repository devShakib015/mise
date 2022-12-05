import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/categories/categories_page.dart';
import 'package:customer_app/views/categories/category_items_page.dart';
import 'package:flutter/material.dart';

class CategoryItemWidget extends StatelessWidget {
  final CategoryModel category;
  const CategoryItemWidget({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryItemsPage(title: category.title),
          ),
        );
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstant.defaultPadding),
              child: CachedNetworkImage(imageUrl: category.image),
            ),
            const SizedBox(height: ThemeConstant.defaultPadding / 4),
            Text(
              category.title,
              style: Theme.of(context).textTheme.caption!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyText1!.color),
            ),
          ],
        ),
      ),
    );
  }
}
