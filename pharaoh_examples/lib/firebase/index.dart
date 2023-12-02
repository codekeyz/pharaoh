import 'dart:io';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/auth.dart';

import '../firebase/routes/todo.routes.dart';
import '../firebase/routes/user.routes.dart';
import '../firebase/utils.dart';
import '../firebase/locator/locator.dart';

final app = Pharaoh();

void main() async {
  final admin = FirebaseAdminApp.initializeApp(
    envVariables['PROJECT_ID'],
    Credential.fromServiceAccount(File("$publicDir/serviceAccountKey.json")),
  );

  final auth = Auth(admin);
  final firestore = Firestore(admin);

  locator.initAuth(auth);
  locator.initStore(firestore);

  app.group('/api/users', userRoutes);
  app.group('/api/todo', todoRoutes);

  await app.listen(port: 8080);
}
