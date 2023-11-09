import 'package:pharaoh/src/server.dart';

final pharaoh = Pharaoh();

void main() async {
  final router = pharaoh.router;

  router.get(
    '/test-json',
    (_, res) => res.json({"name": "Chima", "age": 24}),
  );

  router.get(
    '/redirect',
    (req, res) => res.redirect('http://google.com'),
  );

  await pharaoh.listen();
}
