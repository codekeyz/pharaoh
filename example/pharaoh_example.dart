import 'package:pharaoh/src/server.dart';

final pharaoh = Pharaoh();

void main() async {
  final app = pharaoh.router;

  app.use((req, res) {});

  app.get(
    '/:user/json',
    (req, res) => res.json({"name": "Chima", "age": 31}),
  );

  app.get(
    '/redirect',
    (req, res) => res.redirect('http://google.com'),
  );

  app.group('/api/v1', (router) {
    router.get('/version', (req, res) => res.ok('1.0.0'));

    router.get('/ping', (req, res) => res.ok('2.0.0'));

    router.get(
      '/:user/boy',
      (req, res) => res.json({"name": "Chima Precious"}),
    );

    router.post('/sign-in', (req, res) => res.ok());
  });

  await pharaoh.listen();
}
