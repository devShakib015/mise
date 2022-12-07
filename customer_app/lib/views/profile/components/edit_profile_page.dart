import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/helpers/app_constants.dart';
import 'package:customer_app/helpers/date_formatter.dart';
import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/custom_spacer.dart';
import 'package:customer_app/widgets/field_card.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:ionicons/ionicons.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  final _dateOfBirthController = TextEditingController();
  String? _gender;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _imageUrl != null
                    ? CachedNetworkImageProvider(_imageUrl!)
                    : null,
                child: _imageUrl == null
                    ? const Icon(Ionicons.person, size: 50)
                    : null,
              ),
              const DefaultVerticalSpacer(),
              FieldCard(
                child: TextFormField(
                  controller: _nameController,
                  textAlignVertical: TextAlignVertical.center,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Ionicons.person),
                  ),
                ),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              FieldCard(
                child: TextFormField(
                  controller: _emailController,
                  textAlignVertical: TextAlignVertical.center,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Ionicons.mail),
                  ),
                ),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              FieldCard(
                child: InternationalPhoneNumberInput(
                  countries: AppConstants.appCountryCodes,
                  onInputChanged: (PhoneNumber number) {},
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.onUserInteraction,
                  textFieldController: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  spaceBetweenSelectorAndTextField: 0,
                  formatInput: true,
                  textAlignVertical: TextAlignVertical.top,
                  inputDecoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: "1234567890",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                ),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              FieldCard(
                child: TextField(
                  controller: _dateOfBirthController,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _dateOfBirth = date;
                        _dateOfBirthController.text =
                            DateFormatter.toYearMonthDay(date);
                      });
                    }
                  },
                  readOnly: true,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tap to select date of birth',
                    prefixIcon: Icon(Ionicons.calendar),
                  ),
                ),
              ),
              const DefaultVerticalSpacer(isHalf: true),
              //Gender dropdown
              FieldCard(
                child: DropdownButtonFormField(
                  borderRadius:
                      BorderRadius.circular(ThemeConstant.defaultRadius),
                  dropdownColor: Theme.of(context).cardColor,
                  items: _genders
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  value: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Select your gender',
                  ),
                ),
              ),
              const DefaultVerticalSpacer(),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _genders = ["Male", "Female", "Other"];
