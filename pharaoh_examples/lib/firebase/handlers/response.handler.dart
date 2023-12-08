import 'package:pharaoh/pharaoh.dart';
import '../handlers/handler.utils.dart';
import '../utils.dart';

class ResponseHandler {
  Response res;
  ResponseHandler(this.res);

  success(String? message) {
    return res.status(HttpStatus.success).json({
      "success": true,
      "message": message ?? 'Success',
    });
  }

  error(ApiError error) {
    return res.status(error.statusCode).json({
      "success": false,
      "message": error.message,
    });
  }

  successWithData<T>(T data, {String? message}) {
    return res.status(HttpStatus.success).json({
      "success": true,
      "message": message ?? 'Success',
      "data": data,
    });
  }
}
