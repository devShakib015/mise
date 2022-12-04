import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/home/cart_page.dart';
import 'package:customer_app/views/home/notification_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class HomePageTopBar extends StatelessWidget {
  const HomePageTopBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstant.defaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: ThemeConstant.defaultRadius * 1.5,
            backgroundImage: CachedNetworkImageProvider(
                "https://newprofilepic2.photo-cdn.net//assets/images/article/profile.jpg"),
          ),
          const DefaultHorizontalSpacer(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                //TODO: Select deliver address
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Deliver to",
                      style: Theme.of(context).textTheme.caption),
                  Row(
                    children: [
                      Text("Home",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: ThemeConstant.defaultPadding / 4),
                      Icon(Ionicons.caret_down,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const DefaultHorizontalSpacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()));
            },
            icon: const Icon(Ionicons.notifications_outline),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CartPage()));
            },
            icon: const Icon(Ionicons.bag_outline),
          ),
        ],
      ),
    );
  }
}
