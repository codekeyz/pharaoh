import 'package:pharaoh/src/server.dart';

final pharaoh = Pharaoh();

void main() async {
  final app = pharaoh.router;

  app.use((req, res) {
    print('Incoming request ${req.method}');
  });

  app.get(
    '/test-json',
    (req, res) => res.json({"name": "Chima", "age": 24}),
  );

  app.get(
    '/redirect',
    (req, res) => res.redirect('http://google.com'),
  );

  await pharaoh.listen();
}
