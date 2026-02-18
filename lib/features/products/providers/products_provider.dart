import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../services/products_service.dart';
import '../models/product.dart';

final productsServiceProvider = Provider<ProductsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductsService(apiClient);
});

final productsProvider = FutureProvider.family<List<Product>, ProductsFilter>((ref, filter) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProducts(
    search: filter.search,
    category: filter.category,
  );
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  final service = ref.watch(productsServiceProvider);
  return service.getProductById(id);
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getCategories();
});

class ProductsFilter {
  final String? search;
  final String? category;

  ProductsFilter({this.search, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          category == other.category;

  @override
  int get hashCode => search.hashCode ^ category.hashCode;
}

class ProductsProvider extends ChangeNotifier {
  final ProductsService _productsService;

  ProductsProvider(this._productsService);

  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<Product> get filteredProducts {
    var filtered = _products;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    return filtered;
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productsService.getProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _productsService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadProducts();
    await loadCategories();
  }
}
