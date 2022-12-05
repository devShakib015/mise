import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/wallet/components/wallet_top_up_page.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class WalletBalanceSection extends StatelessWidget {
  const WalletBalanceSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: ThemeConstant.defaultPadding * 2,
        right: ThemeConstant.defaultPadding * 1.5,
        top: 0,
        bottom: ThemeConstant.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Balance",
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Colors.white70),
          ),
          Row(
            children: [
              Text(
                "\$ 4,500.50",
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ThemeConstant.defaultPadding * 2,
                      letterSpacing: -1,
                    ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConstant.defaultPadding,
                      vertical: ThemeConstant.defaultPadding / 2),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(ThemeConstant.defaultRadius / 2),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const WalletTopUpPage();
                    }),
                  );
                },
                icon: Icon(
                  Ionicons.add_circle_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  "Top Up",
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
