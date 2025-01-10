import 'dart:developer';

import 'package:example/products/bloc/products_bloc.dart';
import 'package:example/products/bloc/products_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductsBloc>(
      create: (_) => ProductsBloc()..add(const ProductsLoad()),
      child: const ProductsBody(),
    );
  }
}

class ProductsBody extends StatelessWidget {
  const ProductsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          if (state.status == ProductsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == ProductsStatus.loaded) {
            return ListView.builder(
              itemCount: state.products.length,
              itemBuilder: (context, i) {
                final product = state.products[i];
                return GestureDetector(
                  onTap: () {
                    log(product.toJson().toString());
                  },
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(product.description),
                    trailing: Text('${product.price}'),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}
