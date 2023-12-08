import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_annotation/pharaoh_annotation.dart';

@Controller()
class UserController extends BaseController {
  @override
  List<HandlerFunc> get middlewares => [logRequests];

  @Get()
  Response getUsers(Request request, Response response) {
    return response.ok('Hello WOrld 🚀');
  }

  @Post()
  Future<Response> createUser(Request request, Response response) async {
    /// do some fake loading
    await Future.delayed(const Duration(seconds: 2));

    return response.json({
      'name': 'Chima',
      'age': 22,
      'nationality': 'Lagosian',
    });
  }

  @RouteMapping([HTTPMethod.GET, HTTPMethod.HEAD], '/')
  Future<Response> saySomething(
    Request request,
    Response response,
  ) async {
    return response.ok('Hello World');
  }
}

void main() async {
  final app = Pharaoh();

  app.use(logRequests);

  await app.listen();
}
