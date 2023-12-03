import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

import '../domain/requests/createUser.request.dart';
import '../services/user.service.dart';
import '../handlers/response.handler.dart';
import '../utils.dart';

class UserController {
  /// function to create a user
  static createUser($Request req, $Response res) async {
    try {
      /// Retrieve the body from the response
      Map<String, dynamic> body = req.body;

      String username = body['username'];
      String email = body['email'];
      String password = body['password'];

      final request = CreateUserRequest(username, email, password);

      final savedUser = await UserService.createUser(request);

      final jwtToken = JWT(
        {
          "userId": savedUser.uid,
          "email": savedUser.email,
        },
      ).sign(SecretKey(envVariables['JWT_SECRET']));

      final userJson = ensureEncodable(savedUser.toJson());

      return ResponseHandler(res).successWithData({
        "user": userJson,
        "token": jwtToken,
      });
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    }
  }
}
