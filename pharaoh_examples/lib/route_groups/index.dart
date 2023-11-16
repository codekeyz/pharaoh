import 'package:pharaoh/pharaoh.dart';

final app = Pharaoh();

void main() async {
  final guestRouter = app.router()
    ..get('/foo', (req, res) => res.ok("Hello World"))
    ..post('/bar', (req, res) => res.json({"mee": "moo"}))
    ..put('/yoo', (req, res) => res.json({"pookey": "reyrey"}));

  final adminRouter = app.router()
    ..get('/user', (req, res) => res.json({"chima": "happy"}))
    ..put('/hello', (req, res) => res.json({"name": "chima"}))
    ..post('/say-hello', (req, res) => res.notFound())
    ..delete('/delete', (req, res) => res.json(req.body));

  app.group('/admin', adminRouter);

  app.group('/guest', guestRouter);

  await app.listen();
}
