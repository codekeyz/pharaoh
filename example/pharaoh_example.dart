import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final app = Pharaoh();

void main() async {
  /// Using shelf_cors_header with Pharoah
  app.use(useShelfMiddleware(corsHeaders()));
  app.use(logRequests);

  app.get(
    '/chima',
    (req, res) => res.json({"name": "Chima"}),
  );

  final guestRouter = app.router()
    ..get('/user', (req, res) => res.ok("Hello World"))
    ..post('/post', (req, res) => res.json({"mee": "moo"}))
    ..put('/put', (req, res) => res.json({"pookey": "reyrey"}));

  final adminRouter = app.router()
    ..get('/user', (req, res) => res.json({"chima": "happy"}))
    ..put('/hello', (req, res) => res.json({"name": "chima"}))
    ..post('/say-hello', (req, res) => res.notFound())
    ..delete('/delete', (req, res) => res.json(req.body));

  app.group('/admin', adminRouter);

  app.group('/guest', guestRouter);

  await app.listen();
}
