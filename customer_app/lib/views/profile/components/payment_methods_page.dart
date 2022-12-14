import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Ionicons.scan_outline)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //PayPal
            const PaymentMethodItemTile(
              title: "PayPal",
              icon: Ionicons.logo_paypal,
            ),
            //Google Pay
            const PaymentMethodItemTile(
              title: "Google Pay",
              icon: Ionicons.logo_google,
            ),
            //Apple Pay
            const PaymentMethodItemTile(
              title: "Apple Pay",
              icon: Ionicons.logo_apple,
            ),
            //Credit Card
            const PaymentMethodItemTile(
              title: "Credit Card",
              icon: Ionicons.card,
            ),
            //AliPay
            const PaymentMethodItemTile(
              title: "AliPay",
              icon: Ionicons.logo_alipay,
            ),
            //WeChat Pay
            const PaymentMethodItemTile(
              title: "WeChat Pay",
              icon: Ionicons.logo_wechat,
            ),
            //bitcoin
            const PaymentMethodItemTile(
              title: "Bitcoin",
              icon: Ionicons.logo_bitcoin,
            ),
            //cash
            const PaymentMethodItemTile(
              title: "Cash",
              icon: Ionicons.cash,
            ),
            const DefaultVerticalSpacer(),
            ElevatedButton(
                onPressed: () {}, child: const Text("Add Payment Method")),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodItemTile extends StatelessWidget {
  final String title;
  final IconData icon;
  const PaymentMethodItemTile({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          "Connected",
          style: Theme.of(context)
              .textTheme
              .subtitle2!
              .copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
