import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:example/products/bloc/products_state.dart';
import 'package:example/products/entities/product.dart';

part 'products_event.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc() : super(const ProductsState()) {
    on<ProductsLoad>(_onLoad);
  }

  Future<void> _onLoad(ProductsLoad event, Emitter<ProductsState> emit) async {
    emit(state.copyWith(status: ProductsStatus.loading));

    try {
      final products = await Future.delayed(
        const Duration(seconds: 1),
        () => [
          const Product(
            id: '1',
            name: 'Product 1',
            description: 'Description 1',
            price: 10,
          ),
          const Product(
            id: '2',
            name: 'Product 2',
            description: 'Description 2',
            price: 20,
          ),
          const Product(
            id: '3',
            name: 'Product 3',
            description: 'Description 3',
            price: 30,
          ),
        ],
      );

      emit(state.copyWith(status: ProductsStatus.loaded, products: products));
    } catch (e) {
      emit(state.copyWith(status: ProductsStatus.error, error: e));
    }
  }
}
