import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:customer_app/views/wallet/components/transaction%20_history_page.dart';
import 'package:customer_app/views/wallet/components/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RecentTransactionHistorySection extends StatelessWidget {
  const RecentTransactionHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Transaction History",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryPage(),
                  ),
                );
              },
              child: const Text(LocaleKeys.SEEALL).tr(),
            ),
          ],
        ),
        Column(
          children: [
            for (var i = 0; i < 10; i++) const TransactionListTile(),
          ],
        )
      ],
    );
  }
}
