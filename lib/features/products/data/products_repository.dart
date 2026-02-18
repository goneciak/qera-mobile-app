import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/providers.dart';
import '../models/product.dart';

class ProductsRepository {
  final ApiClient _apiClient;

  ProductsRepository(this._apiClient);

  /// Pobiera aktywne produkty (dla REP)
  Future<List<Product>> getActiveProducts() async {
    final response = await _apiClient.get('/rep/products');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Wyszukuje produkty po nazwie lub SKU
  List<Product> searchProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
             product.sku.toLowerCase().contains(lowerQuery) ||
             (product.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Filtruje produkty po kategorii
  List<Product> filterByCategory(List<Product> products, String? category) {
    if (category == null || category.isEmpty) return products;
    return products.where((p) => p.category == category).toList();
  }

  /// Pobiera unikalne kategorie z listy produktów
  List<String> getCategories(List<Product> products) {
    final categories = products
        .map((p) => p.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductsRepository(apiClient);
});
