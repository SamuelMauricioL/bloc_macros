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

macro class CopyWith implements ClassDeclarationsMacro, ClassDefinitionMacro  {
  const CopyWith();

  NamedTypeAnnotation? _checkNamedType(TypeAnnotation type, Builder builder) {
    if (type is NamedTypeAnnotation) return type;
    if (type is OmittedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with explicit types are allowed on serializable '
              'classes, please add a type.',
              target: type.asDiagnosticTarget),
          Severity.error));
    } else {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable '
              'classes.',
              target: type.asDiagnosticTarget),
          Severity.error));
    }
    return null;
  }

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final fields = await builder.fieldsOf(clazz);
    final fieldsName = fields.map((f) => f.identifier.name).toList();
    final rawType = clazz.superclass;
    final clazzName = clazz.identifier.name;

    final type = _checkNamedType(rawType!, builder);

    builder.declareInType(
      DeclarationCode.fromString(
'''
  $clazzName copyWith({
    $fieldsName
  }) {
    return $clazzName(
      ${fieldsName.map((e) => '$e: this.$e,').join('\n      ')}
    );
  }
'''
      ),
    );
  }
  
  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final introspectionData = await _SharedIntrospectionData.build(
      builder,
      clazz,
    );

    final fields = introspectionData.fields;
    final fieldsName = fields.map((f) => _checkNamedType(f.type, builder)).toList();
    final classDecl = await fieldsName.map((f) => (f?.classDeclaration(builder))).toList();

    // final builderFields = await builder.declarationOf();
    final fieldsTypeDeclaration = List<String>.empty(growable: true);
    for (var types in classDecl) {
      if (types == null) break;
      final fieldType = (await types)?.identifier.name;
      if (fieldType == null) break;
      fieldsTypeDeclaration.add(fieldType);
    }
    final rawCode = RawCode.fromParts([
            ' as ',
          ]);
  }
}

extension on NamedTypeAnnotation {
  Future<ClassDeclaration?> classDeclaration(DefinitionBuilder builder) async {
    var typeDecl = await builder.typeDeclarationOf(identifier);
    while (typeDecl is TypeAliasDeclaration) {
      final aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'Only fields with named types are allowed on serializable '
                'classes',
                target: asDiagnosticTarget),
            Severity.error));
        return null;
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only classes are supported as field types for serializable '
              'classes',
              target: asDiagnosticTarget),
          Severity.error));
      return null;
    }
    return typeDecl;
  }
}

final _dartCore = Uri.parse('dart:core');

final class _SharedIntrospectionData {
  /// The declaration of the class we are generating for.
  final ClassDeclaration clazz;

  /// All the fields on the [clazz].
  final List<FieldDeclaration> fields;

  /// A [Code] representation of the type [List<Object?>].
  final NamedTypeAnnotationCode jsonListCode;

  /// A [Code] representation of the type [Map<String, Object?>].
  final NamedTypeAnnotationCode jsonMapCode;

  /// The resolved [StaticType] representing the [Map<String, Object?>] type.
  final StaticType jsonMapType;

  /// The resolved identifier for the [MapEntry] class.
  final Identifier mapEntry;

  /// A [Code] representation of the type [Object].
  final NamedTypeAnnotationCode objectCode;

  /// A [Code] representation of the type [String].
  final NamedTypeAnnotationCode stringCode;

  /// The declaration of the superclass of [clazz], if it is not [Object].
  final ClassDeclaration? superclass;

  _SharedIntrospectionData({
    required this.clazz,
    required this.fields,
    required this.jsonListCode,
    required this.jsonMapCode,
    required this.jsonMapType,
    required this.mapEntry,
    required this.objectCode,
    required this.stringCode,
    required this.superclass,
  });

  static Future<_SharedIntrospectionData> build(
      DeclarationPhaseIntrospector builder, ClassDeclaration clazz) async {
    final (list, map, mapEntry, object, string) = await (
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'MapEntry'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'String'),
    ).wait;
    final objectCode = NamedTypeAnnotationCode(name: object);
    final nullableObjectCode = objectCode.asNullable;
    final jsonListCode = NamedTypeAnnotationCode(name: list, typeArguments: [
      nullableObjectCode,
    ]);
    final jsonMapCode = NamedTypeAnnotationCode(name: map, typeArguments: [
      NamedTypeAnnotationCode(name: string),
      nullableObjectCode,
    ]);
    final stringCode = NamedTypeAnnotationCode(name: string);
    final superclass = clazz.superclass;
    final (fields, jsonMapType, superclassDecl) = await (
      builder.fieldsOf(clazz),
      builder.resolve(jsonMapCode),
      superclass == null
          ? Future.value(null)
          : builder.typeDeclarationOf(superclass.identifier),
    ).wait;

    return _SharedIntrospectionData(
      clazz: clazz,
      fields: fields,
      jsonListCode: jsonListCode,
      jsonMapCode: jsonMapCode,
      jsonMapType: jsonMapType,
      mapEntry: mapEntry,
      objectCode: objectCode,
      stringCode: stringCode,
      superclass: superclassDecl as ClassDeclaration?,
    );
  }
}