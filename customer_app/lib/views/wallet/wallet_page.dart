import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/wallet/components/recent_transactions_section.dart';
import 'package:customer_app/views/wallet/components/wallet_balance_section.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text("Wallet"),
        leading: const Icon(Ionicons.wallet_outline),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Ionicons.search_outline),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(90),
          child: WalletBalanceSection(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: ThemeConstant.defaultPadding,
            vertical: ThemeConstant.defaultPadding / 2),
        child: RecentTransactionsSection(),
      ),
    );
  }
}
