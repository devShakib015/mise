import 'dart:math';

import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/profile/components/addresses_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    int orderStatus = Random().nextInt(3);

    final Color orderStatusColor = orderStatus == 0
        ? Theme.of(context).colorScheme.secondary
        : orderStatus == 1
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error;

    final isPaid = Random().nextBool();

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${Random().nextInt(1000)}"),
        actions: [
          Tooltip(
            message: "Download Invoice",
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Ionicons.download_outline),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          children: [
            //Order Status
            Container(
              padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
              decoration: BoxDecoration(
                color: orderStatusColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    orderStatus == 0
                        ? Ionicons.time_outline
                        : orderStatus == 1
                            ? Ionicons.checkmark_circle_outline
                            : Ionicons.close_circle_outline,
                    color: orderStatusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    orderStatus == 0
                        ? "Order Placed"
                        : orderStatus == 1
                            ? "Order Delivered"
                            : "Order Cancelled",
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: orderStatusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const DefaultVerticalSpacer(isHalf: true),

            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
                    child: Text(
                      "Order Items",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Divider(height: 0),
                  for (var i = 0; i < 4; i++) const CheckoutItemListTile(),
                ],
              ),
            ),
            //Delivery Details
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
                    child: Text(
                      "Delivery to",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Divider(height: 0),
                  const AddressListTile(
                    trailing: Icon(Ionicons.chevron_forward),
                  ),
                ],
              ),
            ),
            //Payment Details
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Payment Details",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1!
                                .copyWith(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Text(
                          isPaid ? "Paid" : "Unpaid",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  color: isPaid
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Subtotal",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 100).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Delivery Fee",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 10).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Tip",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 10).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  //Vat
                  ListTile(
                    title: Text(
                      "Vat",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 10).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  //Platform Fee
                  ListTile(
                    title: Text(
                      "Platform Fee",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 10).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  //Promo Code
                  ListTile(
                    title: Text(
                      "Promo Code",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                    dense: true,
                    trailing: Text(
                      "-\$${(Random().nextDouble() * 10).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Total",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    dense: true,
                    trailing: Text(
                      "\$${(Random().nextDouble() * 100).toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            //Order Buttons
            Padding(
              padding: const EdgeInsets.all(ThemeConstant.defaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: orderStatus == 0
                          ? const Text("Cancel Order")
                          : orderStatus == 1
                              ? const Text("Leave a Review")
                              : const Text("Order Again"),
                    ),
                  ),
                  const SizedBox(width: ThemeConstant.defaultPadding / 2),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: orderStatus == 0
                          ? const Text("Track Order")
                          : orderStatus == 1
                              ? const Text("Order Again")
                              : const Text("Order Support"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeConstant.defaultPadding),
          ],
        ),
      ),
    );
  }
}
