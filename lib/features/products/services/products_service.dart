import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/product.dart';

class ProductsService {
  final ApiClient _apiClient;

  ProductsService(this._apiClient);

  Future<List<Product>> getProducts({
    String? search,
    String? category,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load products: ${e.message}');
    }
  }

  Future<Product> getProduct(String id) async {
    final products = await getProducts();
    return products.firstWhere(
      (product) => product.id == id,
      orElse: () => throw Exception('Product not found'),
    );
  }

  // Alias dla kompatybilności
  Future<Product> getProductById(String id) => getProduct(id);

  Future<List<String>> getCategories() async {
    try {
      final response = await _apiClient.get('/products/categories');
      final List<dynamic> data = response.data;
      return data.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    }
  }
}
