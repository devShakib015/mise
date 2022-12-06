import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/views/auth/sign_in_with_phone_page.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/custom_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
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
                "Let's you in",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline4!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
              const SizedBox(height: ThemeConstant.defaultPadding * 3),
              OutlinedButton.icon(
                onPressed: () {
                  //TODO: Implement Apple Sign In
                },
                icon: Hero(
                  tag: "apple",
                  child: Icon(Ionicons.logo_apple,
                      color: Theme.of(context).textTheme.subtitle2!.color),
                ),
                label: Text(
                  "Sign in with Apple",
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              const DefaultVerticalSpacer(),
              OutlinedButton.icon(
                onPressed: () {
                  //TODO: Implement Google Sign In
                },
                icon: const Hero(
                    tag: "google",
                    child: Icon(Ionicons.logo_google, color: Colors.red)),
                label: Text(
                  "Sign in with Google",
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              const DefaultVerticalSpacer(),
              OutlinedButton.icon(
                onPressed: () {
                  //TODO: Implement Facebook login
                },
                icon: const Hero(
                    tag: "facebook",
                    child: Icon(Ionicons.logo_facebook, color: Colors.blue)),
                label: Text(
                  "Sign in with Facebook",
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              const DefaultVerticalSpacer(),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  const SizedBox(width: ThemeConstant.defaultPadding),
                  Text(
                    "or",
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  const SizedBox(width: ThemeConstant.defaultPadding),
                  const Expanded(child: Divider()),
                ],
              ),
              const DefaultVerticalSpacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignInWithPhonePage(),
                    ),
                  );
                },
                icon: const Icon(Ionicons.call),
                label: const Text("Sign in with Phone Number"),
              ),
              const DefaultVerticalSpacer(),
              const Hero(tag: "terms", child: AgreeTermsAndPrivacySection()),
              const DefaultVerticalSpacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class AgreeTermsAndPrivacySection extends StatelessWidget {
  final String? text;
  const AgreeTermsAndPrivacySection({
    Key? key,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Text.rich(
        TextSpan(
          text: text ?? "By signing in, you agree to our ",
          style: Theme.of(context).textTheme.caption,
          children: [
            TextSpan(
              text: "Terms of Service",
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print("Terms of Service");
                  //TODO: Navigate to Terms of Service
                },
              style: Theme.of(context)
                  .textTheme
                  .caption!
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print("Privacy Policy");
                  //TODO: Navigate to Privacy Policy
                },
              style: Theme.of(context).textTheme.caption!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
