import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/field_card.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CreateAddressPage extends StatefulWidget {
  const CreateAddressPage({super.key});

  @override
  State<CreateAddressPage> createState() => _CreateAddressPageState();
}

class _CreateAddressPageState extends State<CreateAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressTitleController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldCard(
                child: TextFormField(
                  controller: _addressTitleController,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Address Title',
                    prefixIcon: Icon(Ionicons.location_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Address Line 1',
                    prefixIcon: Icon(Ionicons.home_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Address Line 2',
                    prefixIcon: Icon(Ionicons.home_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'City',
                    prefixIcon: Icon(Ionicons.home_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'State',
                    prefixIcon: Icon(Ionicons.home_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Country',
                    prefixIcon: Icon(Ionicons.globe_outline),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Zip Code',
                    prefixIcon: Icon(Ionicons.code),
                  ),
                ),
              ),
              FieldCard(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Ionicons.call_outline),
                  ),
                ),
              ),
              const DefaultVerticalSpacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {}
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
