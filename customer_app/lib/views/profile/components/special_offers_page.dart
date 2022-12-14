import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

class SpecialOffersPage extends StatelessWidget {
  const SpecialOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Offers'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: Images.foodBanners
              .map(
                (e) => Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: ThemeConstant.defaultPadding / 2,
                    horizontal: ThemeConstant.defaultPadding,
                  ),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ThemeConstant.defaultRadius * 2),
                    image: DecorationImage(
                      image: AssetImage(e),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
