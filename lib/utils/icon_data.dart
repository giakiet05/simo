import 'package:flutter/material.dart';

class CategoryIconData {
  static const Map<String, IconData> iconMap = {
    // Income
    'attach_money': Icons.attach_money,
    'money': Icons.money,
    'account_balance': Icons.account_balance,
    'account_balance_wallet': Icons.account_balance_wallet,
    'credit_card': Icons.credit_card,
    'trending_up': Icons.trending_up,
    'payments': Icons.payments,
    'paid': Icons.paid,
    'savings': Icons.savings,
    'currency_exchange': Icons.currency_exchange,

    // Food & Dining
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_pizza': Icons.local_pizza,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    'breakfast_dining': Icons.breakfast_dining,
    'cake': Icons.cake,
    'icecream': Icons.icecream,
    'coffee': Icons.coffee,
    'ramen_dining': Icons.ramen_dining,

    // Transportation
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'directions_subway': Icons.directions_subway,
    'local_taxi': Icons.local_taxi,
    'two_wheeler': Icons.two_wheeler,
    'directions_bike': Icons.directions_bike,
    'flight': Icons.flight,
    'train': Icons.train,
    'local_shipping': Icons.local_shipping,
    'local_gas_station': Icons.local_gas_station,
    'commute': Icons.commute,

    // Shopping
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'store': Icons.store,
    'local_mall': Icons.local_mall,
    'storefront': Icons.storefront,
    'checkroom': Icons.checkroom,
    'receipt': Icons.receipt,
    'receipt_long': Icons.receipt_long,

    // Entertainment
    'movie': Icons.movie,
    'theaters': Icons.theaters,
    'music_note': Icons.music_note,
    'videogame_asset': Icons.videogame_asset,
    'sports_esports': Icons.sports_esports,
    'sports_soccer': Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'casino': Icons.casino,
    'celebration': Icons.celebration,
    'attractions': Icons.attractions,

    // Bills & Utilities
    'lightbulb': Icons.lightbulb,
    'water_drop': Icons.water_drop,
    'phone_android': Icons.phone_android,
    'wifi': Icons.wifi,
    'home': Icons.home,
    'electrical_services': Icons.electrical_services,
    'router': Icons.router,
    'cell_tower': Icons.cell_tower,
    'tv': Icons.tv,

    // Healthcare
    'local_hospital': Icons.local_hospital,
    'medication': Icons.medication,
    'medical_services': Icons.medical_services,
    'vaccines': Icons.vaccines,
    'healing': Icons.healing,
    'favorite': Icons.favorite,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,

    // Education
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'library_books': Icons.library_books,
    'auto_stories': Icons.auto_stories,
    'edit': Icons.edit,
    'create': Icons.create,

    // Pets
    'pets': Icons.pets,

    // Other common
    'star': Icons.star,
    'grade': Icons.grade,
    'work': Icons.work,
    'business_center': Icons.business_center,
    'beach_access': Icons.beach_access,
    'hotel': Icons.hotel,
    'luggage': Icons.luggage,
    'card_giftcard': Icons.card_giftcard,
    'redeem': Icons.redeem,
    'volunteer_activism': Icons.volunteer_activism,
    'handshake': Icons.handshake,
    'favorite_border': Icons.favorite_border,
    'extension': Icons.extension,
    'category': Icons.category,
    'label': Icons.label,
    'help_outline': Icons.help_outline,
  };

  static const List<String> incomeIcons = [
    'attach_money',
    'money',
    'account_balance',
    'account_balance_wallet',
    'credit_card',
    'trending_up',
    'payments',
    'paid',
    'savings',
    'currency_exchange',
  ];

  static const List<String> expenseIcons = [
    'restaurant',
    'fastfood',
    'local_pizza',
    'local_cafe',
    'directions_car',
    'directions_bus',
    'shopping_cart',
    'shopping_bag',
    'movie',
    'music_note',
    'lightbulb',
    'water_drop',
    'phone_android',
    'home',
    'local_hospital',
    'medication',
    'school',
    'pets',
    'card_giftcard',
    'help_outline',
  ];

  static IconData? getIcon(String? iconName) {
    if (iconName == null) return null;
    return iconMap[iconName];
  }

  static List<String> searchIcons(String query) {
    if (query.isEmpty) return iconMap.keys.toList();

    final lowerQuery = query.toLowerCase();
    return iconMap.keys.where((key) => key.contains(lowerQuery)).toList();
  }
}
