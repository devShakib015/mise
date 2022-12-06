import 'dart:async';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  late Timer timer;
  int _time = 60;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_time > 0) {
          _time--;
        } else {
          timer.cancel();
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var defaultPinTheme = PinTheme(
      width: ThemeConstant.defaultPadding * 3,
      height: ThemeConstant.defaultPadding * 3.5,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius),
      ),
    );

    var focusPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(ThemeConstant.defaultRadius / 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DefaultVerticalSpacer(),
            const Text(
              "Code has been sent to +1 234 567 890",
              textAlign: TextAlign.center,
            ),
            const DefaultVerticalSpacer(),
            const DefaultVerticalSpacer(),
            Pinput(
              controller: pinController,
              focusNode: focusNode,
              listenForMultipleSmsOnAndroid: true,
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              length: 6,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              onCompleted: (value) {
                print(value);
              },
              separator:
                  const SizedBox(width: ThemeConstant.defaultPadding / 2),
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusPinTheme,
            ),
            const DefaultVerticalSpacer(),
            const DefaultVerticalSpacer(),
            _time > 0
                ? Text.rich(
                    TextSpan(
                      text: "Resend code in ",
                      style: Theme.of(context).textTheme.caption,
                      children: [
                        TextSpan(
                          text: "$_time",
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        TextSpan(
                          text: " seconds",
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                : TextButton(
                    onPressed: () {},
                    child: const Text("Resend code"),
                  ),
            const SizedBox(height: ThemeConstant.defaultPadding * 3),
            Padding(
              padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Verify"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
