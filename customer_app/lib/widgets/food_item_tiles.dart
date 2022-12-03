import 'dart:math';

import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class FoodItemGridTile extends StatelessWidget {
  const FoodItemGridTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ThemeConstant.defaultPadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius),
                child: Image.asset(
                  Images.foodItems[Random().nextInt(Images.foodItems.length)],
                ),
              ),
              const DefaultVerticalSpacer(),
              Text(
                foodItemNames[Random().nextInt(foodItemNames.length)],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Ionicons.star, color: Colors.orange, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    (Random().nextDouble() * 5).toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .caption!
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "(${Random().nextInt(1000)})",
                    style: Theme.of(context)
                        .textTheme
                        .caption!
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
              const DefaultVerticalSpacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "\$${(Random().nextDouble() * 30 + 5).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.headline6!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const DefaultHorizontalSpacer(isHalf: true),
                      Text(
                        "\$${(Random().nextDouble() * 100).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.caption!.copyWith(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ),
                  Random().nextBool()
                      ? const Icon(Ionicons.heart, color: Colors.red)
                      : const Icon(Ionicons.heart_outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FoodItemListTile extends StatelessWidget {
  const FoodItemListTile({super.key});

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.width * 0.3;

    return SizedBox(
      height: cardHeight,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ThemeConstant.defaultPadding / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius),
                child: Image.asset(
                  Images.foodItems[Random().nextInt(Images.foodItems.length)],
                  fit: BoxFit.cover,
                ),
              ),
              const DefaultHorizontalSpacer(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DefaultVerticalSpacer(isHalf: true),
                    Text(
                      foodItemNames[Random().nextInt(foodItemNames.length)],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Ionicons.star,
                            color: Colors.orange, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          (Random().nextDouble() * 5).toStringAsFixed(1),
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${Random().nextInt(1000)})",
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "\$${(Random().nextDouble() * 30 + 5).toStringAsFixed(2)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6!
                                  .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const DefaultHorizontalSpacer(isHalf: true),
                            Text(
                              "\$${(Random().nextDouble() * 100).toStringAsFixed(2)}",
                              style: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .copyWith(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough),
                            ),
                          ],
                        ),
                        Random().nextBool()
                            ? const Icon(Ionicons.heart, color: Colors.red)
                            : const Icon(Ionicons.heart_outline)
                      ],
                    ),
                    const DefaultVerticalSpacer(isHalf: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemListTile extends StatelessWidget {
  const CartItemListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double cardHeight = MediaQuery.of(context).size.width * 0.3;

    return SizedBox(
      height: cardHeight,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ThemeConstant.defaultPadding / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius),
                child: Image.asset(
                  Images.foodItems[Random().nextInt(Images.foodItems.length)],
                  fit: BoxFit.cover,
                ),
              ),
              const DefaultHorizontalSpacer(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DefaultVerticalSpacer(isHalf: true),
                    Text(
                      foodItemNames[Random().nextInt(foodItemNames.length)],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const Spacer(),
                    Text(
                        "${Random().nextInt(5) + 1} items x \$${(Random().nextDouble() * 20 + 5).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.caption!),
                    const Spacer(),
                    Text(
                      "\$${(Random().nextDouble() * 100 + 5).toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.headline6!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const DefaultVerticalSpacer(isHalf: true),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Ionicons.trash_outline,
                    color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
