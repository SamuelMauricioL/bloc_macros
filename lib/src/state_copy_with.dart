import 'dart:async';
import 'package:macros/macros.dart';

macro class Props implements ClassDeclarationsMacro {
  const Props();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final fields = await builder.fieldsOf(clazz);
    final fieldsName = fields.map((e) => e.identifier.name).toList().join(', ');

    builder.declareInType(
      DeclarationCode.fromString(
'''
  @override
  List<Object?> get props => [$fieldsName];
'''
      ),
    );
  }
}