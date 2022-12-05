import 'package:customer_app/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help Center'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQ'),
              Tab(text: 'Contact Us'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [FAQPage(), ContactUsPage()],
        ),
      ),
    );
  }
}

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Column(
        children: [
          for (var i = 0; i < 10; i++)
            Card(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: const ExpansionTile(
                  title: Text('How to order?'),
                  children: [
                    Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, nunc vel tincidunt lacinia, nisl nisl aliquam mauris, et ultricies nisl nunc vel mauris. Sed euismod, nunc vel tincidunt lacinia, nisl nisl aliquam mauris, et ultricies nisl nunc vel mauris.'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
      child: Column(
        children: const [
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.call_outline),
              title: Text('Customer Support',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          //Whatsapp
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.logo_whatsapp),
              title: Text('Whatsapp',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          //Email
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.mail_outline),
              title:
                  Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          //facebook
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.logo_facebook),
              title: Text('Facebook',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          //Instagram
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.logo_instagram),
              title: Text('Instagram',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          //Twitter
          Card(
            child: ListTile(
              horizontalTitleGap: ThemeConstant.defaultPadding / 2,
              leading: Icon(Ionicons.logo_twitter),
              title: Text('Twitter',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
