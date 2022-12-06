import 'dart:math';

import 'package:awesome_rating/awesome_rating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class RatingAndReviewsPage extends StatefulWidget {
  const RatingAndReviewsPage({super.key});

  @override
  State<RatingAndReviewsPage> createState() => _RatingAndReviewsPageState();
}

class _RatingAndReviewsPageState extends State<RatingAndReviewsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating & Reviews'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        children: [
          const Divider(),
          const ReviewTopSection(),
          const Divider(),
          for (var i = 0; i < 10; i++) const ReviewCard(),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const DefaultVerticalSpacer(isHalf: true),
          ListTile(
            dense: true,
            leading: const CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                  "https://media.istockphoto.com/id/1196667159/photo/girl-at-the-restaurant-drinks-juice.jpg?s=170667a&w=0&k=20&c=tov2XjsqgpCDGU1I5O4-AcV-kw-_a8J5NuqrmpFiggM="),
            ),
            title: Text(
              'John Doe',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            trailing: const AwesomeStarRating(
              starCount: 5,
              color: Colors.orange,
              borderColor: Colors.orange,
              rating: 4.1,
              allowHalfRating: true,
              size: ThemeConstant.defaultPadding,
            ),
          ),
          const DefaultVerticalSpacer(isHalf: true),
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: ThemeConstant.defaultPadding),
            child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, nunc vel tincidunt lacinia, nunc nisl aliquam nisl, vel aliquam nunc nisl euismod nisl. Sed euismod, nunc vel tincidunt lacinia, nunc nisl aliquam nisl, vel aliquam nunc nisl euismod nisl.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: ThemeConstant.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Random().nextBool()
                      ? Ionicons.heart
                      : Ionicons.heart_outline),
                  label: Text(
                    Random().nextInt(100).toString(),
                    style: Theme.of(context)
                        .textTheme
                        .caption!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  '2 days ago',
                  style: Theme.of(context)
                      .textTheme
                      .caption!
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewTopSection extends StatelessWidget {
  const ReviewTopSection({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Text(
              '4.4',
              style: Theme.of(context).textTheme.headline4!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
            ),
            const DefaultVerticalSpacer(isHalf: true),
            const AwesomeStarRating(
              starCount: 5,
              color: Colors.orange,
              borderColor: Colors.orange,
              rating: 4.4,
              allowHalfRating: true,
              spacing: 4,
            ),
            const DefaultVerticalSpacer(isHalf: true),
            Text(
              '(4.8k reviews)',
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  color: Theme.of(context).textTheme.bodyText1!.color),
            ),
          ],
        ),
        const DefaultHorizontalSpacer(),
        Container(
          width: 1,
          height: 150,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: ThemeConstant.defaultPadding / 4),
                  child: Row(
                    children: [
                      const DefaultHorizontalSpacer(),
                      Text('${5 - i}',
                          style: Theme.of(context)
                              .textTheme
                              .headline6!
                              .copyWith(fontWeight: FontWeight.bold)),
                      const DefaultHorizontalSpacer(isHalf: true),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              ThemeConstant.defaultRadius / 4),
                          child: LinearProgressIndicator(
                            value: Random().nextDouble(),
                            minHeight: 6,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const DefaultHorizontalSpacer(isHalf: true),
                      Text(
                        '${Random().nextInt(1000)}',
                        style: Theme.of(context).textTheme.caption!.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyText1!.color),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
