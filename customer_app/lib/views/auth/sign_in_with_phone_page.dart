import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/auth/login_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SignInWithPhonePage extends StatelessWidget {
  const SignInWithPhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeConstant.defaultPadding * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ThemeConstant.defaultPadding),
              const Hero(tag: "logo", child: StaticLogoWidget()),
              const SizedBox(height: ThemeConstant.defaultPadding * 2),
              Text(
                "Sign in with phone number",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
              const SizedBox(height: ThemeConstant.defaultPadding * 3),
              const SizedBox(height: ThemeConstant.defaultPadding * 3),
              ElevatedButton(onPressed: () {}, child: const Text("Sign in")),
              const SizedBox(height: ThemeConstant.defaultPadding * 2),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  const SizedBox(width: ThemeConstant.defaultPadding),
                  Text(
                    "or continue with",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  const SizedBox(width: ThemeConstant.defaultPadding),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: ThemeConstant.defaultPadding * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: Hero(
                      tag: "apple",
                      child: Icon(Ionicons.logo_apple,
                          color: Theme.of(context).textTheme.subtitle2!.color),
                    ),
                  ),
                  const DefaultHorizontalSpacer(),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Hero(
                      tag: "google",
                      child: Icon(Ionicons.logo_google, color: Colors.red),
                    ),
                  ),
                  const DefaultHorizontalSpacer(),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Hero(
                      tag: "facebook",
                      child: Icon(Ionicons.logo_facebook, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeConstant.defaultPadding),
              const Hero(tag: "terms", child: AgreeTermsAndPrivacySection()),
              const DefaultVerticalSpacer(),
            ],
          ),
        ),
      ),
    );
  }
}
