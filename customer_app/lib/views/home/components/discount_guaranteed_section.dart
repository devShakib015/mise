import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DiscountGuaranteedSection extends StatelessWidget {
  const DiscountGuaranteedSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Discount Guaranteed!!",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
                onPressed: () {}, child: const Text(LocaleKeys.SEEALL).tr())
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 10; i++) const FoodItemGridTile(),
            ],
          ),
        ),
      ],
    );
  }
}
