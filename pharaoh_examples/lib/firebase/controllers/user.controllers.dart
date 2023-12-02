import 'package:dart_firebase_admin/auth.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_examples/firebase/utils.dart';
import 'package:pharaoh_examples/firebase/locator/locator.dart';
import 'package:pharaoh_jwt_auth/pharaoh_jwt_auth.dart';

class UserController {
  /// function to create a user
  static createUser($Request req, $Response res) async {
    try {
      /// Retrieve the body from the response
      Map<String, dynamic> body = req.body;

      String username = body['username'];
      String email = body['email'];
      String password = body['password'];

      /// Create the user using [email] and [password]
      UserRecord savedUser = await locator.auth.createUser(CreateRequest(
        displayName: username,
        email: email,
        password: password,
      ));

      final jwtToken = JWT(
        {
          "userId": savedUser.uid,
          "email": savedUser.email,
        },
      ).sign(SecretKey(envVariables['JWT_SECRET']));

      final userJson = ensureEncodable(savedUser.toJson());

      return res.status(201).json({
        "success": true,
        "user": userJson,
        "token": jwtToken,
      });
    } on FirebaseAuthAdminException catch (err) {
      return res.status(400).json({
        "success": false,
        "error": err.code,
        "message": err.message,
      });
    } catch (err) {
      return res.status(400).makeError(message: err.toString());
    }
  }
}
