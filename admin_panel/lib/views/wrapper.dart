import 'dart:math';

import 'package:admin_panel/helpers/app_constants.dart';
import 'package:admin_panel/views/profile/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: _selectedIndex,
            onChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              SidebarItem(
                label: Text('Dashboard'),
                leading: Icon(CupertinoIcons.square_grid_2x2),
              ),
              SidebarItem(
                label: Text('Catelogues'),
                leading: Icon(CupertinoIcons.square_grid_2x2),
                disclosureItems: [
                  SidebarItem(
                    label: Text('Categories'),
                    leading: Icon(CupertinoIcons.square_grid_2x2),
                  ),
                  SidebarItem(
                    label: Text('Items'),
                    leading: Icon(CupertinoIcons.square_grid_2x2),
                  ),
                ],
              ),
              SidebarItem(
                label: Text('Orders'),
                leading: Icon(CupertinoIcons.square_grid_2x2),
              ),
              if (false)
                SidebarItem(
                  label: Text('Settings'),
                  leading: Icon(CupertinoIcons.settings),
                ),
            ],
          );
        },
        top: const Text(AppConstants.appName),
        bottom: MacosListTile(
          onClick: () {
            showMacosSheet(
              barrierDismissible: true,
              context: context,
              builder: (context) {
                return MacosSheet(child: ProfilePage());
              },
            );
          },
          title: const Text('John Doe'),
          subtitle: const Text('johndoe@email.com'),
          leading: const Icon(CupertinoIcons.person_fill),
        ),
      ),
      child: Center(
        child: Text(_selectedIndex.toString()),
      ),
    );
  }
}
