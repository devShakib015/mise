import 'dart:math';
import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/food_details/food_reviews_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class FoodDetailsPage extends StatefulWidget {
  const FoodDetailsPage({super.key});

  @override
  State<FoodDetailsPage> createState() => _FoodDetailsPageState();
}

class _FoodDetailsPageState extends State<FoodDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstant.defaultPadding,
            vertical: ThemeConstant.defaultPadding / 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Ionicons.remove)),
              Text(
                '4',
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Ionicons.add)),
              const DefaultHorizontalSpacer(),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Add to Cart - \$45.99'),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: Image.asset(
                    Images.foodItems.first,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  child: SafeArea(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: ThemeConstant.defaultPadding / 2),
                      leading: CustomIconButton(
                        icon: Ionicons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconButton(
                            icon: Ionicons.heart_outline,
                            onTap: () {},
                          ),
                          const DefaultHorizontalSpacer(isHalf: true),
                          CustomIconButton(
                            icon: Ionicons.share_outline,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text(
                foodItemNames.first,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              trailing: Text(
                '\$${Random().nextInt(100)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              dense: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RatingAndReviewsPage(),
                  ),
                );
              },
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Ionicons.star, color: Colors.orange, size: 15),
                  const SizedBox(width: ThemeConstant.defaultPadding / 4),
                  Text(
                    '4.5',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const DefaultHorizontalSpacer(isHalf: true),
                  Text(
                    '(4.5k reviews)',
                    style: Theme.of(context)
                        .textTheme
                        .caption!
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                  ),
                ],
              ),
              trailing: const Icon(Ionicons.chevron_forward),
            ),
            const Divider(height: 0),
            const SizedBox(height: ThemeConstant.defaultPadding / 4),
            const ListTile(
              dense: true,
              title: Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
            ),
            const SizedBox(height: ThemeConstant.defaultPadding / 4),
            const Divider(height: 0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ThemeConstant.defaultPadding / 2,
                    horizontal: ThemeConstant.defaultPadding,
                  ),
                  child: Text(
                    "Add Ons",
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                for (var i = 0; i < 5; i++)
                  CheckboxListTile(
                    dense: true,
                    title: Text(
                      "Lorem ipsum dolor sit amet",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    secondary: Text(
                      '\$${Random().nextInt(100)}',
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: true,
                    onChanged: (value) {},
                  ),
              ],
            ),
            const DefaultVerticalSpacer(),
          ],
        ),
      ),
    );
  }
}
