import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/field_card.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Search');
        //TODO: Navigate to the search page
      },
      child: FieldCard(
        prefixIcon: Ionicons.search_outline,
        child: Padding(
          padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
          child: Text(
            "What are you craving?",
            style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).textTheme.caption!.color!,
                ),
          ),
        ),
      ),
    );
  }
}
