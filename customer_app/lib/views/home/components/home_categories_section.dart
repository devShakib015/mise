import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/categories/categories_page.dart';
import 'package:customer_app/widgets/category_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeCategoriesSection extends StatelessWidget {
  const HomeCategoriesSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ThemeConstant.defaultPadding / 2,
      runSpacing: ThemeConstant.defaultPadding,
      alignment: WrapAlignment.center,
      children: categories.take(8).map((e) {
        return CategoryItemWidget(category: e);
      }).toList(),
    );
  }
}
