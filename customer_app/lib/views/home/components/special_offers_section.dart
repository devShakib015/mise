import 'package:card_swiper/card_swiper.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SpecialOffersSection extends StatelessWidget {
  const SpecialOffersSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
            TextButton(
                onPressed: () {}, child: const Text(LocaleKeys.SEEALL).tr())
          ],
        ),
        SizedBox(
          height: 160,
          child: Swiper(
            itemCount: Images.foodBanners.length,
            autoplay: true,
            duration: 500,
            itemBuilder: (BuildContext context, int index) {
              return ClipRRect(
                borderRadius:
                    BorderRadius.circular(ThemeConstant.defaultRadius * 2),
                child: Image.asset(
                  Images.foodBanners[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
