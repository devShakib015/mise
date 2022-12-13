import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/food_item_tiles.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Orders"),
          leading: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: ThemeConstant.defaultPadding),
            child: Image.asset(Images.logo,
                color: Theme.of(context).colorScheme.primary),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Ionicons.search_outline),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ActiveOrdersSection(),
            CompletedOrdersSection(),
            CancelledOrdersSection(),
          ],
        ),
      ),
    );
  }
}

class ActiveOrdersSection extends StatelessWidget {
  const ActiveOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Column(
        children: [
          for (var i = 0; i < 10; i++) const OrderItemListTile(orderStatus: 0),
        ],
      ),
    );
  }
}

class CompletedOrdersSection extends StatelessWidget {
  const CompletedOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Column(
        children: [
          for (var i = 0; i < 10; i++) const OrderItemListTile(orderStatus: 1),
        ],
      ),
    );
  }
}

class CancelledOrdersSection extends StatelessWidget {
  const CancelledOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Column(
        children: [
          for (var i = 0; i < 10; i++) const OrderItemListTile(orderStatus: 2),
        ],
      ),
    );
  }
}
