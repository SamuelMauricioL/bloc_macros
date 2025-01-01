import 'package:bloc_macros/bloc_macros.dart';
import 'package:equatable/equatable.dart';
import 'package:example/products/entities/product.dart';

enum ProductsStatus { loading, loaded, error, orderPlaced }

@Props()
class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.loading,
    this.products = const [],
    this.error,
  });

  final ProductsStatus status;
  final List<Product> products;
  final Object? error;

  // ProductsState copyWith({
  //   ProductsStatus? status,
  //   List<Product>? products,
  //   Object? error,
  // }) {
  //   return ProductsState(
  //     status: status ?? this.status,
  //     products: products ?? this.products,
  //     error: error,
  //   );
  // }
}
