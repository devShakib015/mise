import 'dart:math';
import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/date_formatter.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isFood = Random().nextBool();

    return GestureDetector(
      onTap: () {
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (context) => const FoodDetailsPage()));
      },
      child: Card(
        child: ListTile(
            leading: isFood
                ? CircleAvatar(
                    backgroundImage: AssetImage(Images.foodItems.first),
                  )
                : const CircleAvatar(
                    child: Icon(Ionicons.wallet),
                  ),
            title: Text(
              isFood ? foodItemNames.first : "Wallet Top Up",
              style: Theme.of(context)
                  .textTheme
                  .bodyText1!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormatter.toWholeDateTime(DateTime.now())),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${(Random().nextDouble() * 100).toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: ThemeConstant.defaultPadding / 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isFood ? "Orders" : "Top Up",
                      style: Theme.of(context).textTheme.caption,
                    ),
                    const SizedBox(width: ThemeConstant.defaultPadding / 4),
                    Icon(
                      !isFood
                          ? Ionicons.arrow_up_circle
                          : Ionicons.arrow_down_circle,
                      size: 14,
                      color: !isFood
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
