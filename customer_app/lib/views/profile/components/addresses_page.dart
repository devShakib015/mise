import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Ionicons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        children: [
          // ignore: prefer_const_constructors
          for (var i = 0; i < 10; i++) AddressListTile(),
        ],
      ),
    );
  }
}

class AddressListTile extends StatelessWidget {
  final Widget? trailing;
  const AddressListTile({
    Key? key,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Ionicons.location_sharp, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                'Home',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (true)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstant.defaultPadding / 2,
                    vertical: ThemeConstant.defaultPadding / 4),
                margin: const EdgeInsets.only(
                    left: ThemeConstant.defaultPadding / 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(ThemeConstant.defaultRadius / 3),
                ),
                child: Text(
                  'Default',
                  style: Theme.of(context).textTheme.caption!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
        subtitle: const Text('123 Main St, New York, NY 10001'),
        trailing: trailing ??
            IconButton(
              onPressed: () {},
              icon: Icon(Ionicons.create_outline,
                  color: Theme.of(context).colorScheme.primary),
            ),
      ),
    );
  }
}
