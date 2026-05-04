import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getActiveProducts();

  Future<List<ProductModel>> getActiveProductsByWorkshop(String workshopId);
}
