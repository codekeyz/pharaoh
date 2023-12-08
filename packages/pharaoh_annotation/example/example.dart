import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_annotation/pharaoh_annotation.dart';

@Controller(path: '/users')
class UserController extends BaseController {
  @override
  List<HandlerFunc> get middlewares => [logRequests];

  @Get(path: '/<userId>')
  Response getUsers(Request request, Response response) {
    return response.ok('Hello ${request.params['userId']} 🚀');
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

  @RouteMapping([HTTPMethod.ALL], '/hello/<userId>')
  Future<Response> sayHello(Request request, Response response) async {
    final userId = request.params['userId'];
    return response.ok('${request.method} called just now 🚀 with $userId');
  }
}

void main() async {
  var app = Pharaoh();
  app.get('/', (req, res) => res.ok('Hello World 🚀'));

  app = await AppModule(
    custom: app,
    controllers: [UserController()],
  ).build();

  print(app.routeStr);

  await app.listen();
}
