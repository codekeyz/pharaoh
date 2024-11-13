import 'package:collection/collection.dart';
import 'package:pharaoh/src/_next/router.dart';

class OpenApiGenerator {
  static Map<String, dynamic> generateOpenApi(
    List<OpenApiRoute> routes, {
    required String apiName,
    required List<String> serverUrls,
  }) {
    return {
      "openapi": "3.0.0",
      "info": {"title": apiName, "version": "1.0.0"},
      "servers": serverUrls.map((e) => {'url': e}).toList(),
      "paths": _generatePaths(routes),
      "components": {"schemas": _generateSchemas(routes)}
    };
  }

  static Map<String, dynamic> _generatePaths(List<OpenApiRoute> routes) {
    final paths = <String, Map<String, dynamic>>{};

    for (final route in routes) {
      final pathParams = route.args.where((e) => e.meta is Param).toList();
      final bodyParam = route.args.firstWhereOrNull((e) => e is Body);

      var path = route.route;
      // Convert Express-style path params (:id) to OpenAPI style ({id})
      for (final param in pathParams) {
        path = path.replaceAll('<${param.name}>', '{${param.name}}');
      }

      paths[path] = paths[path] ?? {};
      paths[path]![route.method.name.toLowerCase()] = {
        "summary": "", // Could be added as a parameter
        "parameters": _generateParameters(route.args),
        "responses": {
          "200": {"description": "Successful response"}
        }
      };

      if (bodyParam != null) {
        paths[path]![route.method.name.toLowerCase()]["requestBody"] = {
          "required": !bodyParam.optional,
          "content": {
            "application/json": {"schema": _generateSchema(bodyParam)}
          }
        };
      }
    }

    return paths;
  }

  static List<Map<String, dynamic>> _generateParameters(
    List<ControllerMethodParam> args,
  ) {
    final parameters = <Map<String, dynamic>>[];

    for (final arg in args) {
      final parameterLocation = _getParameterLocation(arg.meta);
      if (parameterLocation == null) continue;

      final parameterSchema = _generateSchema(arg);

      // Add default value if available and not a path parameter
      if (arg.defaultValue != null && parameterLocation != "path") {
        parameterSchema["default"] = arg.defaultValue;
      }

      final param = {
        "name": arg.name,
        "in": parameterLocation,
        "required": parameterLocation == "path" ? true : !arg.optional,
        "schema": parameterSchema,
      };

      parameters.add(param);
    }

    return parameters;
  }

  static String? _getParameterLocation(RequestAnnotation? annotation) {
    return switch (annotation) {
      const Header() => "header",
      const Query() => "query",
      const Param() => "path",
      _ => null,
    };
  }

  static Map<String, dynamic> _generateSchema(ControllerMethodParam param) {
    if (param.dto != null) {
      return {
        "\$ref": "#/components/schemas/${param.dto.runtimeType.toString()}"
      };
    }

    return _typeToOpenApiType(param.type);
  }

  static Map<String, dynamic> _typeToOpenApiType(Type type) {
    switch (type.toString()) {
      case "String":
        return {"type": "string"};
      case "int":
        return {"type": "integer", "format": "int32"};
      case "double":
        return {"type": "number", "format": "double"};
      case "bool":
        return {"type": "boolean"};
      case "DateTime":
        return {"type": "string", "format": "date-time"};
      default:
        return {"type": "object"};
    }
  }

  static Map<String, dynamic> _generateSchemas(List<OpenApiRoute> routes) {
    final schemas = <String, dynamic>{};

    for (final route in routes) {
      for (final arg in route.args) {
        final dto = arg.dto;
        if (dto == null) continue;

        schemas[dto.runtimeType.toString()] = {
          "type": "object",
          "properties": dto.properties.fold({},
              (preV, curr) => preV..[curr.name] = _typeToOpenApiType(curr.type))
        };
      }
    }

    return schemas;
  }
}
