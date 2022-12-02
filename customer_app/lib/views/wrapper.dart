import 'package:customer_app/views/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

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
      appBar: AppBar(toolbarHeight: 0),
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
    bottomNavigationBarItem: const BottomNavigationBarItem(
      icon: Icon(Ionicons.home_outline),
      activeIcon: Icon(Ionicons.home),
      label: 'Home',
    ),
    body: const HomePage(),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: const BottomNavigationBarItem(
      icon: Icon(Ionicons.list_outline),
      activeIcon: Icon(Ionicons.list),
      label: 'Orders',
    ),
    body: const Center(child: Text('Orders')),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: const BottomNavigationBarItem(
      icon: Icon(Ionicons.chatbubble_ellipses_outline),
      activeIcon: Icon(Ionicons.chatbubble_ellipses),
      label: 'Message',
    ),
    body: const Center(child: Text('Message')),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: const BottomNavigationBarItem(
      icon: Icon(Ionicons.wallet_outline),
      activeIcon: Icon(Ionicons.wallet),
      label: 'Wallet',
    ),
    body: const Center(child: Text('Wallet')),
  ),
  WrapperBodyItem(
    bottomNavigationBarItem: const BottomNavigationBarItem(
      icon: Icon(Ionicons.person_outline),
      activeIcon: Icon(Ionicons.person),
      label: 'Profile',
    ),
    body: const Center(child: Text('Profile')),
  ),
];
