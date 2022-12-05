import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/wallet/components/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Ionicons.search_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          children: [
            for (var i = 0; i < 20; i++) const TransactionListTile(),
          ],
        ),
      ),
    );
  }
}
