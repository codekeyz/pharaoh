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

  // final adminRouter = app.router()
  //   // ..use((req, res, next) {
  //   //   print('Admin was called today');
  //   //   next();
  //   // })
  //   ..get('/user', (req, res) => res.json({"chima": "happy"}))
  //   ..post('/hello', (req, res) => res.json({"name": "chima"}))
  //   ..put('/put', (req, res) => null)
  //   ..delete('/delete', (req, res) => null);

  app.useOnPath('/guest', guestRouter);

  // app.useOnPath('/admin', adminRouter);

  await app.listen();
}
