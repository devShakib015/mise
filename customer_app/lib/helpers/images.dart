class Images {
  Images._();

  static const String _imagePath = 'assets/images';
  static const String _foodItemsPath = '$_imagePath/food_items';
  static const String _foodBannersPath = '$_imagePath/food_banners';

  static List<String> foodItems = [
    for (int i = 1; i <= 6; i++) '$_foodItemsPath/$i.png'
  ];

  static List<String> foodBanners = [
    for (int i = 1; i <= 4; i++) '$_foodBannersPath/$i.png'
  ];

  static const String logo = '$_imagePath/logo.png';
  static const String loader = '$_imagePath/loader.gif';
}
