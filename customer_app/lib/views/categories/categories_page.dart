import 'package:customer_app/helpers/theme_constants.dart';
import 'package:customer_app/widgets/category_item.dart';
import 'package:flutter/material.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConstant.defaultPadding),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: ThemeConstant.defaultPadding / 2,
            runSpacing: ThemeConstant.defaultPadding,
            alignment: WrapAlignment.spaceBetween,
            children: categories.map((e) {
              return CategoryItemWidget(category: e);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class CategoryModel {
  final String title;
  final String image;

  CategoryModel({
    required this.title,
    required this.image,
  });
}

List<CategoryModel> categories = [
  CategoryModel(
    title: 'Hamburger',
    image: 'https://img.icons8.com/fluency/512/hamburger.png',
  ),
  //Pizza
  CategoryModel(
    title: 'Pizza',
    image: 'https://img.icons8.com/fluency/512/pizza.png',
  ),
  //Noodles
  CategoryModel(
    title: 'Noodles',
    image: 'https://img.icons8.com/fluency/512/noodles.png',
  ),

  //Meat
  CategoryModel(
    title: 'Meat',
    image: 'https://img.icons8.com/fluency/512/meat.png',
  ),

  //Vegetables
  CategoryModel(
    title: 'Vegetables',
    image: 'https://img.icons8.com/fluency/512/peas.png',
  ),

  //dessert
  CategoryModel(
    title: 'Dessert',
    image: 'https://img.icons8.com/fluency/512/dessert.png',
  ),

  //Drink
  CategoryModel(
    title: 'Drink',
    image: 'https://img.icons8.com/fluency/512/cocktail.png',
  ),

  //Bread
  CategoryModel(
    title: 'Bread',
    image: 'https://img.icons8.com/fluency/512/bread.png',
  ),

  //Cheese
  CategoryModel(
    title: 'Cheese',
    image: 'https://img.icons8.com/fluency/512/cheese.png',
  ),

  //Sandwich
  CategoryModel(
    title: 'Sandwich',
    image: 'https://img.icons8.com/fluency/512/sandwich.png',
  ),

  //taco
  CategoryModel(
    title: 'Taco',
    image: 'https://img.icons8.com/fluency/512/taco.png',
  ),

  //Salad
  CategoryModel(
    title: 'Salad',
    image: 'https://img.icons8.com/fluency/512/salad.png',
  ),

  //Sushi
  CategoryModel(
    title: 'Sushi',
    image: 'https://img.icons8.com/fluency/512/sushi.png',
  ),

  //Fries
  CategoryModel(
    title: 'Fries',
    image: 'https://img.icons8.com/fluency/512/french-fries.png',
  ),

  //Chicken
  CategoryModel(
    title: 'Chicken',
    image: 'https://img.icons8.com/fluency/512/poultry-leg.png',
  ),

  //Other
  CategoryModel(
      title: 'Other',
      image: 'https://img.icons8.com/fluency/512/wicker-basket.png'),
];
