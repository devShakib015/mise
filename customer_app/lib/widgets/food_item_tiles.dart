import 'dart:math';
import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/food_details/food_details_page.dart';
import 'package:customer_app/views/orders/order_details_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class FoodItemGridTile extends StatelessWidget {
  const FoodItemGridTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FoodDetailsPage()));
      },
      child: SizedBox(
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
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
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
                const DefaultVerticalSpacer(isHalf: true),
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
                          style: Theme.of(context)
                              .textTheme
                              .headline6!
                              .copyWith(
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
      ),
    );
  }
}

class FoodItemListTile extends StatelessWidget {
  const FoodItemListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FoodDetailsPage()));
      },
      child: SizedBox(
        height: 120,
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
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 16),
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
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(
                                    fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "(${Random().nextInt(1000)})",
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(
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
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FoodDetailsPage()));
      },
      child: SizedBox(
        height: 120,
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
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 16),
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
      ),
    );
  }
}

class CheckoutItemListTile extends StatelessWidget {
  const CheckoutItemListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            "${Random().nextInt(5) + 1} items x \$${(Random().nextDouble() * 20 + 5).toStringAsFixed(2)}",
                            style: Theme.of(context).textTheme.caption!),
                        Text(
                          "\$${(Random().nextDouble() * 100 + 5).toStringAsFixed(2)}",
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        )
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

class OrderItemListTile extends StatelessWidget {
  final int orderStatus; // 0: active, 1: completed, 2: cancelled
  const OrderItemListTile({
    super.key,
    required this.orderStatus,
  });

  @override
  Widget build(BuildContext context) {
    final Color orderStatusColor = orderStatus == 0
        ? Theme.of(context).colorScheme.secondary
        : orderStatus == 1
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    final isPaid = Random().nextBool();

    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OrderDetailsPage()));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstant.defaultPadding,
              vertical: ThemeConstant.defaultPadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Order #${Random().nextInt(1000)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ThemeConstant.defaultPadding / 2,
                        vertical: ThemeConstant.defaultPadding / 4),
                    decoration: BoxDecoration(
                      color: orderStatusColor,
                      borderRadius:
                          BorderRadius.circular(ThemeConstant.defaultRadius),
                    ),
                    child: Text(
                      orderStatus == 0
                          ? "Active"
                          : orderStatus == 1
                              ? "Completed"
                              : "Cancelled",
                      style: Theme.of(context).textTheme.caption!.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const DefaultVerticalSpacer(isHalf: true),
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < Random().nextInt(10) + 1; i++)
                        Padding(
                          padding: const EdgeInsets.only(
                              right: ThemeConstant.defaultPadding / 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                ThemeConstant.defaultRadius),
                            child: Image.asset(
                                Images.foodItems[
                                    Random().nextInt(Images.foodItems.length)],
                                fit: BoxFit.cover),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              Text(
                foodItemNames.take(Random().nextInt(10) + 1).join(", "),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.caption!,
              ),
              const DefaultVerticalSpacer(isHalf: true),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        "${Random().nextInt(5) + 1} items x \$${(Random().nextDouble() * 20 + 5).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.caption!),
                  ),
                  Row(
                    children: [
                      Text(
                        "\$${(Random().nextDouble() * 100 + 5).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const DefaultHorizontalSpacer(isHalf: true),
                      //Payment status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: ThemeConstant.defaultPadding / 2,
                            vertical: ThemeConstant.defaultPadding / 4),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(
                              ThemeConstant.defaultRadius),
                        ),
                        child: Text(
                          isPaid ? "Paid" : "Unpaid",
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (orderStatus != 2) const Divider(),
              if (orderStatus != 2)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          padding: const EdgeInsets.symmetric(
                              vertical: ThemeConstant.defaultPadding / 4),
                          textStyle: Theme.of(context)
                              .textTheme
                              .caption!
                              .copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {},
                        child: orderStatus == 0
                            ? const Text("Cancel Order")
                            : orderStatus == 1
                                ? const Text("Leave a Review")
                                : const Text(""),
                      ),
                    ),
                    const DefaultHorizontalSpacer(isHalf: true),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: ThemeConstant.defaultPadding / 4),
                          textStyle: Theme.of(context)
                              .textTheme
                              .caption!
                              .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {},
                        child: orderStatus == 0
                            ? const Text("Track Order")
                            : orderStatus == 1
                                ? const Text("Order Again")
                                : const Text(""),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
