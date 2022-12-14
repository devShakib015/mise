import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/helpers/images.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/providers/hive_provider.dart';
import 'package:customer_app/views/profile/components/addresses/addresses_page.dart';
import 'package:customer_app/views/profile/components/edit_profile_page.dart';
import 'package:customer_app/views/profile/components/help_center_page.dart';
import 'package:customer_app/views/profile/components/invite_friends.dart';
import 'package:customer_app/views/profile/components/language_page.dart';
import 'package:customer_app/views/profile/components/my_favorite_foods_page.dart';
import 'package:customer_app/views/profile/components/notification_settings_page.dart';
import 'package:customer_app/views/profile/components/payment_methods_page.dart';
import 'package:customer_app/views/profile/components/security_page.dart';
import 'package:customer_app/views/profile/components/special_offers_page.dart';
import 'package:customer_app/widgets/custom_dialogs.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: ThemeConstant.defaultPadding),
          child: Image.asset(Images.logo,
              color: Theme.of(context).colorScheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DefaultVerticalSpacer(isHalf: true),
            ListTile(
              leading: const CircleAvatar(
                radius: ThemeConstant.defaultRadius * 2,
                backgroundImage: CachedNetworkImageProvider(
                    "https://newprofilepic2.photo-cdn.net//assets/images/article/profile.jpg"),
              ),
              title: const Text("John Doe",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              subtitle: const Text("+1 123 456 7890"),
              trailing: IconButton(
                  onPressed: () {}, icon: const Icon(Ionicons.create_outline)),
            ),
            const DefaultVerticalSpacer(isHalf: true),
            const Divider(height: 0),
            const DefaultVerticalSpacer(isHalf: true),
            ProfileListTile(
              icon: Ionicons.heart_outline,
              title: 'My Favorite Foods',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MyFavoriteFoodsPage()));
              },
            ),
            //Special Offers
            ProfileListTile(
              icon: Ionicons.gift_outline,
              title: 'Special Offers',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SpecialOffersPage()));
              },
            ),
            //Payment Methods
            ProfileListTile(
              icon: Ionicons.card_outline,
              title: 'Payment Methods',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PaymentMethodsPage()));
              },
            ),
            const DefaultVerticalSpacer(isHalf: true),
            const Divider(height: 0),
            const DefaultVerticalSpacer(isHalf: true),
            //Profile
            ProfileListTile(
              icon: Ionicons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const EditProfilePage()));
              },
            ),
            //Address
            ProfileListTile(
              icon: Ionicons.location_outline,
              title: 'Address',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AddressesPage()));
              },
            ),
            //Notifications
            ProfileListTile(
              icon: Ionicons.notifications_outline,
              title: 'Notifications',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage()));
              },
            ),
            //Security
            ProfileListTile(
              icon: Ionicons.lock_closed_outline,
              title: 'Security',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SecurityPage()));
              },
            ),
            //Language
            ProfileListTile(
              icon: Ionicons.language_outline,
              title: 'Language',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const LanguagePage()));
              },
            ),
            //Dark Mode
            Consumer(
              builder: (context, ref, child) {
                final themeRef = ref.watch(themeProvider);
                return ProfileListTile(
                  icon: Ionicons.moon_outline,
                  title: 'Dark Mode',
                  onTap: () {},
                  trailing: CupertinoSwitch(
                    value: themeRef.isDarkTheme ?? false,
                    onChanged: (value) async {
                      await ref.read(themeProvider).saveTheme(value);
                    },
                  ),
                );
              },
            ),
            //Help Center
            ProfileListTile(
              icon: Ionicons.help_outline,
              title: 'Help Center',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const HelpCenterPage()));
              },
            ),
            //Invite Friends
            ProfileListTile(
              icon: Ionicons.people_outline,
              title: 'Invite Friends',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const InviteFriendsPage()));
              },
            ),
            const DefaultVerticalSpacer(isHalf: true),
            const Divider(height: 0),
            const DefaultVerticalSpacer(isHalf: true),
            //Logout
            ProfileListTile(
              icon: Ionicons.log_out_outline,
              title: 'Logout',
              onTap: () async {
                showCustomDialog(
                  context,
                  child: AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              color: Theme.of(context).colorScheme.error,
            ),
            const DefaultVerticalSpacer(),
          ],
        ),
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  const ProfileListTile({
    Key? key,
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: color ?? Theme.of(context).textTheme.headline6!.color),
      horizontalTitleGap: 0,
      title: Text(title,
          style: Theme.of(context).textTheme.subtitle2!.copyWith(color: color)),
      trailing:
          trailing ?? Icon(Ionicons.chevron_forward_outline, color: color),
      onTap: onTap,
    );
  }
}
