import 'package:bloc_macros/bloc_macros.dart';
import 'package:json/json.dart';

@JsonCodable()
@Copyable()
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final double price;
}
