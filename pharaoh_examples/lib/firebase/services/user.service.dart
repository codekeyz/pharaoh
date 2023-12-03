import 'package:dart_firebase_admin/auth.dart';
import 'package:dart_firebase_admin/firestore.dart';

import '../domain/requests/createUser.request.dart';
import '../handlers/handler.utils.dart';
import '../locator/locator.dart';
import '../utils.dart';

class UserService {
  UserService._();

  static Future<UserRecord> createUser(CreateUserRequest request) async {
    try {
      /// Create the user using [email] and [password]
      final savedUser = await locator.auth.createUser(CreateRequest(
        displayName: request.username,
        email: request.email,
        password: request.password,
      ));

      return savedUser;
    } on FirebaseFirestoreAdminException catch (err) {
      throw ApiError(err.code, HttpStatus.internalServerError);
    }
  }
}
