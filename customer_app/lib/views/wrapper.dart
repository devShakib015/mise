import 'package:customer_app/l18n/locale_keys.g.dart';
import 'package:customer_app/views/home/home_page.dart';
import 'package:customer_app/views/orders/orders_page.dart';
import 'package:customer_app/views/profile/profile_page.dart';
import 'package:customer_app/views/wallet/wallet_page.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:easy_localization/easy_localization.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: _wrapperBodyItems
            .map((item) => item.bottomNavigationBarItem)
            .toList(),
      ),
      body: _wrapperBodyItems[_currentIndex].body,
    );
  }
}

class WrapperBodyItem {
  BottomNavigationBarItem bottomNavigationBarItem;
  Widget body;
  WrapperBodyItem({
    required this.bottomNavigationBarItem,
    required this.body,
  });
}

List<WrapperBodyItem> _wrapperBodyItems = [
  WrapperBodyItem(
    bottomNavigationBarItem: BottomNavigationBarItem(
        icon: const Icon(Ionicons.home_outline),
        activeIcon: const Icon(Ionicons.home),
        label: LocaleKeys.HOME.tr()),
    body: const HomePage(),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: BottomNavigationBarItem(
      icon: const Icon(Ionicons.list_outline),
      activeIcon: const Icon(Ionicons.list),
      label: LocaleKeys.ORDERS.tr(),
    ),
    body: const OrdersPage(),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: BottomNavigationBarItem(
      icon: const Icon(Ionicons.wallet_outline),
      activeIcon: const Icon(Ionicons.wallet),
      label: LocaleKeys.WALLET.tr(),
    ),
    body: const WalletPage(),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: BottomNavigationBarItem(
      icon: const Icon(Ionicons.person_outline),
      activeIcon: const Icon(Ionicons.person),
      label: LocaleKeys.PROFILE.tr(),
    ),
    body: const ProfilePage(),
  ),
];
