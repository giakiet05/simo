import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getAll();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createCategory(String name, String type) async {
    if (name.trim().isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    try {
      await _repository.create(name.trim(), type);
      await loadCategories();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateCategory(String id, String name, String type) async {
    if (name.trim().isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    try {
      await _repository.update(id, name.trim(), type);
      await loadCategories();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.delete(id);
      await loadCategories();
    } catch (error) {
      rethrow;
    }
  }
}

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryNotifier(repository);
});
