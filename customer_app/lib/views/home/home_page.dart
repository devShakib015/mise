import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/home/components/home_page_top_bar.dart';
import 'package:customer_app/views/home/components/home_search_bar.dart';
import 'package:customer_app/views/home/components/special_section.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        children: const [
          HomePageTopBar(),
          DefaultVerticalSpacer(),
          HomeSearchBar(),
          DefaultVerticalSpacer(isHalf: true),
          SpecialOffersSection(),
          DefaultVerticalSpacer(),
        ],
      ),
    );
  }
}
