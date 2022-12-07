import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class WalletTopUpPage extends StatefulWidget {
  const WalletTopUpPage({super.key});

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet Top Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ThemeConstant.defaultPadding),
              Text(
                "Enter the amount you want to top up",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .subtitle2!
                    .copyWith(fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: ThemeConstant.defaultPadding),
              Container(
                margin: const EdgeInsets.all(ThemeConstant.defaultPadding),
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstant.defaultPadding,
                  vertical: ThemeConstant.defaultPadding * 2,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(ThemeConstant.defaultRadius * 2),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyText1!.color,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefix: Text("\$"),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter amount";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: ThemeConstant.defaultPadding / 2),
              Wrap(
                spacing: ThemeConstant.defaultPadding / 2,
                runSpacing: ThemeConstant.defaultPadding / 2,
                alignment: WrapAlignment.center,
                children: [
                  for (final amount in [
                    10,
                    20,
                    50,
                    100,
                    200,
                    250,
                    500,
                    750,
                    1000
                  ])
                    OutlinedButton(
                      onPressed: () {
                        _amountController.text = amount.toString();
                        _amountController.selection =
                            TextSelection.fromPosition(TextPosition(
                                offset: _amountController.text.length));
                      },
                      child: Text("\$$amount"),
                    ),
                ],
              ),
              const SizedBox(height: ThemeConstant.defaultPadding * 2),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    EasyLoading.show(status: "Payment processing...");
                    await Future.delayed(const Duration(seconds: 2));
                    EasyLoading.dismiss();
                  }
                },
                child: const Text("Top Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
