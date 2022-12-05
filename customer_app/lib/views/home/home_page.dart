import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/home/components/discount_guaranteed_section.dart';
import 'package:customer_app/views/home/components/home_page_top_bar.dart';
import 'package:customer_app/views/home/components/home_search_bar.dart';
import 'package:customer_app/views/home/components/recommended_for_you_section.dart';
import 'package:customer_app/views/home/components/banners_and_categories_section.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HomePageTopBar(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        children: const [
          HomeSearchBar(),
          BannersAndCategoriesSection(),
          DiscountGuaranteedSection(),
          RecommendedForYouSection(),
          DefaultVerticalSpacer(),
        ],
      ),
    );
  }
}
