import 'dart:math';

import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/auth/login_page.dart';
import 'package:customer_app/views/profile/components/addresses_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _tipController = TextEditingController();
  final _adicionalNotesController = TextEditingController();
  final _promoCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Orders'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.all(ThemeConstant.defaultPadding),
                        child: Text(
                          "Delivery To",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Ionicons.storefront_outline, size: 16),
                        label: const Text(
                          "On Premises",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 0),
                  const AddressListTile(
                    trailing: Icon(Ionicons.chevron_forward),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.all(ThemeConstant.defaultPadding),
                        child: Text(
                          "Order Summary",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Ionicons.add, size: 16),
                        label: const Text(
                          "Add More Items",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 0),
                  for (var i = 0; i < 4; i++) const OrderItemListTile(),
                ],
              ),
            ),
            const DefaultVerticalSpacer(isHalf: true),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      "Add Tip (Optional)",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    horizontalTitleGap: 0,
                    leading: Icon(
                      Ionicons.cash_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Ionicons.chevron_forward),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Promo Code (Optional)",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    horizontalTitleGap: 0,
                    leading: Icon(
                      Ionicons.pricetag_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Ionicons.chevron_forward),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text(
                      "Additional Notes (Optional)",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    horizontalTitleGap: 0,
                    leading: Icon(
                      Ionicons.clipboard_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Ionicons.chevron_forward),
                  ),
                ],
              ),
            ),
            const DefaultVerticalSpacer(isHalf: true),
            Card(
              child: Column(
                children: [
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
            const DefaultVerticalSpacer(isHalf: true),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      "Payment Method",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    horizontalTitleGap: 0,
                    leading: Icon(
                      Ionicons.card_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    trailing: const Icon(Ionicons.chevron_forward),
                  ),
                ],
              ),
            ),
            const AgreeTermsAndPrivacySection(
                text: "By placing this order, you agree to our "),
            ElevatedButton(onPressed: () {}, child: const Text("Place Order")),
            const DefaultVerticalSpacer(),
            const DefaultVerticalSpacer(),
          ],
        ),
      ),
    );
  }
}
