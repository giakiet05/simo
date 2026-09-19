import '../agent_tool.dart';
import '../../../models/category.dart';
import '../../../providers/category_provider.dart';

/// Helper to intelligently resolve colors and icon strings for categories.
class CategoryResolverHelper {
  /// Resolves hex color strings or localized color names.
  static String resolveColor(String? colorStr, String type) {
    if (colorStr == null || colorStr.trim().isEmpty) {
      return type == 'income' ? '#10B981' : '#F97316';
    }
    final raw = colorStr.trim().toLowerCase();

    // Check Hex code pattern (#RRGGBB or RRGGBB)
    if (RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(raw)) {
      return raw.startsWith('#') ? raw.toUpperCase() : '#${raw.toUpperCase()}';
    }

    // Named color keywords in Vietnamese and English
    if (raw.contains('đỏ') || raw.contains('red')) return '#EF4444';
    if (raw.contains('cam') || raw.contains('orange')) return '#F97316';
    if (raw.contains('vàng') || raw.contains('yellow') || raw.contains('amber')) return '#F59E0B';
    if (raw.contains('xanh lá') || raw.contains('lục') || raw.contains('green') || raw.contains('emerald')) return '#10B981';
    if (raw.contains('ngọc lam') || raw.contains('teal')) return '#14B8A6';
    if (raw.contains('xanh ngọc') || raw.contains('cyan')) return '#06B6D4';
    if (raw.contains('xanh dương') || raw.contains('xanh biển') || raw.contains('xanh da trời') || raw.contains('blue')) return '#3B82F6';
    if (raw.contains('chàm') || raw.contains('indigo')) return '#6366F1';
    if (raw.contains('tím') || raw.contains('purple') || raw.contains('violet')) return '#8B5CF6';
    if (raw.contains('hồng') || raw.contains('pink')) return '#EC4899';
    if (raw.contains('xám') || raw.contains('grey') || raw.contains('gray') || raw.contains('slate')) return '#64748B';
    if (raw.contains('đen') || raw.contains('black')) return '#1E293B';
    if (raw.contains('xanh')) return '#3B82F6';

    return type == 'income' ? '#10B981' : '#F97316';
  }

  /// Resolves icon strings or semantically matches keywords to supported icon names.
  static String resolveIcon(String? iconStr, String categoryName, String type) {
    final query = '${iconStr ?? ''} $categoryName'.toLowerCase();

    // Exact match with known valid icon identifiers
    if (iconStr != null && iconStr.isNotEmpty) {
      final clean = iconStr.trim().toLowerCase();
      const validIcons = [
        'restaurant', 'fastfood', 'local_pizza', 'local_cafe', 'local_bar', 'lunch_dining',
        'dinner_dining', 'breakfast_dining', 'cake', 'icecream', 'coffee', 'ramen_dining',
        'directions_car', 'directions_bus', 'directions_subway', 'local_taxi', 'two_wheeler',
        'directions_bike', 'flight', 'train', 'local_shipping', 'local_gas_station', 'commute',
        'shopping_cart', 'shopping_bag', 'store', 'local_mall', 'storefront', 'checkroom',
        'receipt', 'receipt_long', 'movie', 'theaters', 'music_note', 'videogame_asset',
        'sports_esports', 'sports_soccer', 'sports_basketball', 'casino', 'celebration',
        'attractions', 'lightbulb', 'water_drop', 'phone_android', 'wifi', 'home',
        'electrical_services', 'router', 'cell_tower', 'tv', 'local_hospital', 'medication',
        'medical_services', 'vaccines', 'healing', 'favorite', 'fitness_center', 'spa',
        'school', 'menu_book', 'library_books', 'auto_stories', 'edit', 'create', 'pets',
        'attach_money', 'money', 'account_balance', 'account_balance_wallet', 'credit_card',
        'trending_up', 'payments', 'paid', 'savings', 'currency_exchange', 'category'
      ];
      if (validIcons.contains(clean)) {
        return clean;
      }
    }

    // Party / Quậy / Bar / Entertainment
    if (query.contains('quậy') || query.contains('nhậu') || query.contains('bia') ||
        query.contains('rượu') || query.contains('bar') || query.contains('pub') ||
        query.contains('tiệc') || query.contains('party') || query.contains('chơi bời')) {
      return 'celebration';
    }
    if (query.contains('game') || query.contains('esport') || query.contains('chơi')) {
      return 'sports_esports';
    }
    if (query.contains('phim') || query.contains('cinema') || query.contains('rạp') || query.contains('movie')) {
      return 'movie';
    }
    if (query.contains('nhạc') || query.contains('music') || query.contains('hát') || query.contains('karaoke')) {
      return 'music_note';
    }

    // Transportation & Fuel (prioritize to avoid substring false positives like 'xăng')
    if (query.contains('xăng') || query.contains('gas') || query.contains('petrol')) {
      return 'local_gas_station';
    }
    if (query.contains('xe máy') || query.contains('honda') || query.contains('motor')) {
      return 'two_wheeler';
    }
    if (query.contains('máy bay') || query.contains('vé máy bay') || query.contains('du lịch') || query.contains('flight')) {
      return 'flight';
    }
    if (query.contains('xe') || query.contains('ô tô') || query.contains('grab') || query.contains('taxi') || query.contains('car') || query.contains('bus')) {
      return 'directions_car';
    }

    // Food & Dining
    if (query.contains('cà phê') || query.contains('cafe') || query.contains('coffee') || query.contains('trà')) {
      return 'coffee';
    }
    if (query.contains('bánh') || query.contains('kem') || query.contains('cake') || query.contains('snack')) {
      return 'cake';
    }
    final isFood = RegExp(r'(^|\s)(ăn|uống|food|phở|cơm|bún|mì|lẩu|nướng|nhà hàng)(\s|$)').hasMatch(query);
    if (isFood) {
      return 'restaurant';
    }

    // Shopping
    if (query.contains('mua sắm') || query.contains('shopping') || query.contains('quần áo') || query.contains('đồ')) {
      return 'shopping_bag';
    }
    if (query.contains('siêu thị') || query.contains('chợ') || query.contains('mart')) {
      return 'shopping_cart';
    }

    // Bills & Living
    if (query.contains('điện') || query.contains('điện lực')) {
      return 'lightbulb';
    }
    if (query.contains('nước') || query.contains('thủy cục')) {
      return 'water_drop';
    }
    if (query.contains('mạng') || query.contains('wifi') || query.contains('internet')) {
      return 'wifi';
    }
    if (query.contains('nhà') || query.contains('phòng') || query.contains('thuê nhà')) {
      return 'home';
    }

    // Health & Beauty
    if (query.contains('thuốc') || query.contains('khám') || query.contains('bệnh') || query.contains('y tế') || query.contains('bác sĩ')) {
      return 'medical_services';
    }
    if (query.contains('gym') || query.contains('thể thao') || query.contains('fitness') || query.contains('chạy bộ')) {
      return 'fitness_center';
    }
    if (query.contains('spa') || query.contains('mỹ phẩm') || query.contains('làm đẹp')) {
      return 'spa';
    }

    // Education
    if (query.contains('học') || query.contains('sách') || query.contains('khoá học') || query.contains('trường')) {
      return 'school';
    }

    // Pets
    if (query.contains('chó') || query.contains('mèo') || query.contains('pet') || query.contains('thú cưng')) {
      return 'pets';
    }

    // Income
    if (type == 'income') {
      if (query.contains('thưởng') || query.contains('bonus')) return 'savings';
      if (query.contains('lãi') || query.contains('đầu tư')) return 'trending_up';
      return 'attach_money';
    }

    return 'shopping_bag';
  }
}

/// Mutation tool to create a new transaction category.
class CreateCategoryTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'category_create';

  @override
  String get description => 'Tạo danh mục thu hoặc chi mới';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['categoryName'],
    'properties': {
      'categoryName': {'type': 'string'},
      'type': {'type': 'string', 'enum': ['expense', 'income']},
      'icon': {'type': ['string', 'null']},
      'color': {'type': ['string', 'null']},
      'budgetLimit': {'type': ['number', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final name = input['categoryName'] as String? ?? input['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return {'isSuccess': false, 'error': 'Tên danh mục không được để trống'};
    }

    final type = input['type'] as String? ?? 'expense';
    final trimmedName = name.trim();

    // Check if category already exists in current snapshot
    var categories = context.ref.read(categoryProvider).value ?? [];
    if (categories.isEmpty) {
      categories = await context.ref.read(categoryRepositoryProvider).getAll();
    }
    final existing = categories.where((c) =>
      c.type == type &&
      c.name.trim().toLowerCase() == trimmedName.toLowerCase()
    ).firstOrNull;

    if (existing != null) {
      return {
        'isSuccess': false,
        'error': 'Danh mục "$trimmedName" đã tồn tại sẵn trong hệ thống (ID: ${existing.id}, Loại: ${existing.type}). Không tạo trùng lặp.',
        'categoryId': existing.id,
        'categoryName': existing.name,
        'type': existing.type,
      };
    }

    final rawIcon = input['icon'] as String?;
    final rawColor = input['color'] as String?;
    final budgetLimit = (input['budgetLimit'] as num?)?.toDouble();

    final icon = CategoryResolverHelper.resolveIcon(rawIcon, trimmedName, type);
    final color = CategoryResolverHelper.resolveColor(rawColor, type);

    try {
      await context.ref.read(categoryProvider.notifier).createCategory(
        trimmedName,
        type,
        icon: icon,
        color: color,
        budgetLimit: budgetLimit,
      );

      final updatedCategories = context.ref.read(categoryProvider).value ?? [];
      final createdCat = updatedCategories.where((c) =>
        c.type == type && c.name.trim().toLowerCase() == trimmedName.toLowerCase()
      ).firstOrNull;

      return {
        'isSuccess': true,
        'categoryId': createdCat?.id,
        'categoryName': trimmedName,
        'type': type,
        'icon': icon,
        'color': color,
        'budgetLimit': budgetLimit,
      };
    } catch (e) {
      return {
        'isSuccess': false,
        'error': e.toString(),
      };
    }
  }
}

/// Mutation tool to update an existing category's properties.
class UpdateCategoryTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'category_update';

  @override
  String get description => 'Cập nhật tên, icon, màu sắc hoặc hạn mức của danh mục';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'categoryId': {'type': ['string', 'null']},
      'categoryName': {'type': ['string', 'null']},
      'newName': {'type': ['string', 'null']},
      'type': {'type': ['string', 'null'], 'enum': ['expense', 'income']},
      'icon': {'type': ['string', 'null']},
      'color': {'type': ['string', 'null']},
      'budgetLimit': {'type': ['number', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final categoryId = input['categoryId'] as String?;
    final categoryName = input['categoryName'] as String?;

    var categories = context.ref.read(categoryProvider).value ?? [];
    if (categories.isEmpty) {
      categories = await context.ref.read(categoryRepositoryProvider).getAll();
    }
    Category? target;

    if (categoryId != null && categoryId.isNotEmpty) {
      target = categories.where((c) => c.id == categoryId).firstOrNull;
    }

    if (target == null && categoryName != null && categoryName.isNotEmpty) {
      final query = categoryName.toLowerCase().trim();
      target = categories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          categories.where((c) => c.name.toLowerCase().contains(query)).firstOrNull;
    }

    if (target == null) return false;

    final updatedName = input['newName'] as String? ?? target.name;
    final updatedType = input['type'] as String? ?? target.type;

    // Check duplicate if name or type is changing
    if (updatedName.trim().toLowerCase() != target.name.trim().toLowerCase() || updatedType != target.type) {
      final duplicate = categories.where((c) =>
        c.id != target!.id &&
        c.type == updatedType &&
        c.name.trim().toLowerCase() == updatedName.trim().toLowerCase()
      ).firstOrNull;
      if (duplicate != null) {
        return false;
      }
    }
    final rawColor = input['color'] as String?;
    final rawIcon = input['icon'] as String?;
    final budgetLimit = (input['budgetLimit'] as num?)?.toDouble() ?? target.budgetLimit;

    final updatedColor = rawColor != null
        ? CategoryResolverHelper.resolveColor(rawColor, updatedType)
        : target.color;
    final updatedIcon = rawIcon != null
        ? CategoryResolverHelper.resolveIcon(rawIcon, updatedName, updatedType)
        : target.icon;

    await context.ref.read(categoryProvider.notifier).updateCategory(
      target.id,
      updatedName.trim(),
      updatedType,
      icon: updatedIcon,
      color: updatedColor,
      budgetLimit: budgetLimit,
    );
    return true;
  }
}

/// Mutation tool to delete an existing transaction category.
class DeleteCategoryTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'category_delete';

  @override
  String get description => 'Xóa một danh mục thu hoặc chi';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'categoryId': {'type': ['string', 'null']},
      'categoryName': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final categoryId = input['categoryId'] as String?;
    final categoryName = input['categoryName'] as String?;

    var categories = context.ref.read(categoryProvider).value ?? [];
    if (categories.isEmpty) {
      categories = await context.ref.read(categoryRepositoryProvider).getAll();
    }
    Category? target;

    if (categoryId != null && categoryId.isNotEmpty) {
      target = categories.where((c) => c.id == categoryId).firstOrNull;
    }

    if (target == null && categoryName != null && categoryName.isNotEmpty) {
      final query = categoryName.toLowerCase().trim();
      target = categories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          categories.where((c) => c.name.toLowerCase().contains(query)).firstOrNull;
    }

    if (target == null) return false;

    // Guard against deleting internal system categories
    if (target.id.startsWith('sys_')) {
      return false;
    }

    await context.ref.read(categoryProvider.notifier).deleteCategory(target.id);
    return true;
  }
}
