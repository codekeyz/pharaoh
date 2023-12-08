import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_examples/firebase/domain/models/user.model.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

import '../handlers/handler.utils.dart';
import '../domain/requests/createUser.request.dart';
import '../services/user.service.dart';
import '../handlers/response.handler.dart';
import '../utils.dart';

class UserController {
  /// function to create a user
  static createUser(Request req, Response res) async {
    try {
      if (req.body is! Map) {
        throw ApiError('Bad request body', HttpStatus.badRequest);
      }

      /// Retrieve the body from the response
      Map<String, dynamic> body = req.body;

      if (!body.containsKey('username') ||
          !body.containsKey('email') ||
          !body.containsKey('password')) {
        throw ApiError('Bad request body', HttpStatus.badRequest);
      }

      String username = body['username'];
      String email = body['email'];
      String password = body['password'];

      final request = CreateUserRequest(username, email, password);

      final userRecord = await UserService.createUser(request);

      final userJson = ensureEncodable(userRecord.toJson());

      final savedUser = User.fromJson(userJson);

      final jwtToken = JWT(
        {
          "userId": savedUser.uid,
          "email": savedUser.email,
        },
      ).sign(SecretKey(envVariables['JWT_SECRET']));

      return ResponseHandler(res).successWithData({
        "user": savedUser.toJson(),
        "token": jwtToken,
      }, message: 'User created successfully');
    } on ApiError catch (err) {
      return ResponseHandler(res).error(err);
    } catch (err, st) {
      print(err.toString());
      print(st);
    }
  }
}
