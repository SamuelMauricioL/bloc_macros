part of 'products_bloc.dart';

enum ProductsStatus { loading, loaded, error, orderPlaced }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.loading,
    this.products = const [],
    this.error,
  });

  final ProductsStatus status;
  final List<Product> products;
  final Object? error;

  @override
  List<Object?> get props => [status, products, error];

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    Object? error,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error,
    );
  }
}
