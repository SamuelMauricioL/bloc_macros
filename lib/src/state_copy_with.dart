import 'dart:async';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart';

// Libraries used in augmented code.
final dartCore = Uri.parse('dart:core');
final dataClassMacro = Uri.parse('package:data_class/src/_data_class.dart');
// Objects used in augmented code.
const undefined = Object();

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

macro class Copyable implements ClassDeclarationsMacro, ClassDefinitionMacro {
  /// {@macro copyable}
  const Copyable();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) {
    return _declareCopyWith(clazz, builder);
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) {
    return _buildCopyWith(clazz, builder);
  }

  Future<void> _declareCopyWith(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final methods = await builder.fieldsOf(clazz);
    if (methods.any((c) => c.identifier.name == 'copyWith')) {
      throw ArgumentError('A copyWith method already exists.');
    }
    final fields = await builder.allFieldsOf(clazz);

    // Ensure all class fields have a type.
    if (fields.any((f) => f.type.checkNamed(builder) == null)) return null;
    
    if (fields.isEmpty) {
      return builder.declareInType(
        DeclarationCode.fromString(
          'external ${clazz.identifier.name} Function() get copyWith;',
        ),
      );
    }

    final declaration = DeclarationCode.fromParts(
      [
        'external ${clazz.identifier.name} Function({',
        for (final field in fields)
          ...[
            field.type.cast<NamedTypeAnnotation>().identifier,
            if(field.type.cast<NamedTypeAnnotation>().isNullable) '?',
            ' ', field.identifier.name,
            ',',
          ]
        ,'}) get copyWith;',
      ],
    );
    
    return builder.declareInType(declaration);
  }

  Future<void> _buildCopyWith(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final copyWith = methods.firstWhereOrNull(
      (m) => m.identifier.name == 'copyWith',
    );
    if (copyWith == null) return;
    final copyWithMethod = await builder.buildMethod(copyWith.identifier);
    final className = clazz.identifier.name;
    final docComments = CommentCode.fromString('/// Create a copy of [$className] and replace zero or more fields.');

    final defaultConstructor = await builder.defaultConstructorOf(clazz);
    if (defaultConstructor == null) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Class "$className" must have a default constructor',
            target: clazz.asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );
      return null;
    }
    
    final constructorParams = await builder.constructorParamsOf(defaultConstructor, clazz);
    final params = [
      ...constructorParams.positional,
      ...constructorParams.named,
    ];

    if (params.isEmpty) {
      return copyWithMethod.augment(
        FunctionBodyCode.fromParts(['=> ', className, '.new;']),
        docComments: docComments,
      );
    }

    // Ensure all constructor params have a type.
    if (params.any((p) => p.type == null)) return null;

    final (object, undefined) = await (
      builder.codeFrom(dartCore, 'Object'),
      builder.codeFrom(dataClassMacro, 'undefined'),
    ).wait;

    final body = FunctionBodyCode.fromParts(
      [
        '=> ',
        '({',for (final param in params) ...[object, '? ', param.name, ' = ', undefined, ','],'}) { ',
        'return ', className,'(',
        for (final param in params)
          ...[param.name, ': ', param.name, ' == ', undefined, ' ? this.', param.name, ' : ', param.name, ' as ', param.type.code, ','],');',
        '};',
      ],
    );

    return copyWithMethod.augment(body, docComments: docComments);
  }
}