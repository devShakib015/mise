import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SpecialOffersSection extends StatelessWidget {
  const SpecialOffersSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Special Offers",
            style: Theme.of(context)
                .textTheme
                .bodyText1!
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(onPressed: () {}, child: const Text(LocaleKeys.SEEALL).tr())
      ],
    );
  }
}
