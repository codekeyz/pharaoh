import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_turbo/pharaoh_turbo.dart';

@Controller(path: '/users')
class UserController extends BaseController {
  UserController() {
    // useMdw(logRequests);

    useScopedMdw(logRequests.only([#createUser, #getUsers]));
  }

  @Get()
  Future<Response> createUser(Request request, Response response) async {
    /// do some fake loading
    await Future.delayed(const Duration(seconds: 2));

    return response.json({
      'name': 'Chima',
      'age': 22,
      'nationality': 'Lagosian',
    });
  }

  @Get(path: '/<userId>')
  Response getUsers(Request request, Response response) {
    return response.ok('Hello ${request.params['userId']} 🚀');
  }

  @routeMapping([HTTPMethod.GET, HTTPMethod.POST], '/hello/<userId>')
  Future<Response> sayHello(Request request, Response response) async {
    final userId = request.params['userId'];

    return response.ok('${request.method} called just now 🚀 with $userId');
  }
}

void main() async {
  final app = PharaohTurbo(
    controllers: [UserController()],
  ).create();

  await app.listen();

  print(app.routeStr);
}
