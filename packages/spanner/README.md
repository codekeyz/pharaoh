# spanner 🎢

Generic HTTP Router implementation, internally uses a Radix Tree (aka compact Prefix Tree), supports route params, wildcards.

```dart
import 'package:spanner/spanner.dart';

void main() {
  final spanner = Spanner();

  List<String> getUsers() => ['Foo', 'Bar'];

  String getUser(String userId) => 'Hello $userId';

  spanner.addRoute(HTTPMethod.GET, '/', getUsers);

  spanner.addRoute(HTTPMethod.GET, '/<userId>', getUser);

  final result = spanner.lookup(HTTPMethod.GET, '/');
  if (result == null) return;
  

  /// This contains all parameters that were resolved in the route
  final routeParams = result.params; // Map<String, dynamic>

  /// your handler will be in this list.
  ///
  /// If any middlewares where resolved along the route to this handler
  /// they'll be present in the list
  ///
  /// The list is ordered in the exact way you registed your middlewares and handlers
  final resolvedHandler = result.values; // List<dynamic>
}

```