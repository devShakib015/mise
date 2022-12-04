import 'dart:math';

import 'package:awesome_rating/awesome_rating.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

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
        title: Text('Rating & Reviews'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ThemeConstant.defaultPadding),
                  child: Column(
                    children: [
                      Text(
                        '4.4',
                        style: Theme.of(context).textTheme.headline4!.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
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
                            color:
                                Theme.of(context).textTheme.bodyText1!.color),
                      ),
                    ],
                  ),
                ),
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
                                child: LinearProgressIndicator(
                                  value: Random().nextDouble(),
                                  minHeight: 6,
                                  backgroundColor:
                                      Theme.of(context).dividerColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const DefaultHorizontalSpacer(isHalf: true),
                              Text(
                                '${Random().nextInt(1000)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .color),
                              ),
                              const DefaultHorizontalSpacer(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
