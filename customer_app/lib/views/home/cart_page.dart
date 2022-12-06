import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/home/checkout_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 10; i++) const CartItemListTile(),
            const DefaultVerticalSpacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CheckoutPage(),
                  ),
                );
              },
              child: const Text('Checkout'),
            ),
            const DefaultVerticalSpacer(),
            const DefaultVerticalSpacer(),
          ],
        ),
      ),
    );
  }
}
