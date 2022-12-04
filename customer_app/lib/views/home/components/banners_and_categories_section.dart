import 'package:card_swiper/card_swiper.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:customer_app/views/home/category_page.dart';
import 'package:customer_app/views/home/components/home_categories_section.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BannersAndCategoriesSection extends StatelessWidget {
  const BannersAndCategoriesSection({
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
                "Offers & Categories",
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
                    builder: (context) => const CategoryPage(),
                  ),
                );
              },
              child: const Text(LocaleKeys.SEEALL).tr(),
            )
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
        ),
        const DefaultVerticalSpacer(),
        const HomeCategoriesSection(),
        const DefaultVerticalSpacer(),
      ],
    );
  }
}
