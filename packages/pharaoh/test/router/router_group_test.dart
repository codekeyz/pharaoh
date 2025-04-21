import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  group('router', () {
    test('should execute middlewares in group', () async {
      final app = Pharaoh()..post('/', (req, res) => res.json(req.body));

      final adminRouter = Pharaoh.router
        ..get('/', (req, res) => res.ok('Holy Moly 🚀'))
        ..post('/hello', (req, res) => res.json(req.body));
      app.group('/admin', adminRouter);

      final appTester = await request<Pharaoh>(app);

      await appTester
          .post('/', {'_': 'Hello World 🚀'})
          .expectBody({"_": "Hello World 🚀"})
          .expectStatus(200)
          .test();

      await appTester
          .post('/admin/hello', {'_': 'Hello World 🚀'})
          .expectBody({"_": "Hello World 🚀"})
          .expectStatus(200)
          .test();

      await appTester
          .get('/admin')
          .expectBody('Holy Moly 🚀')
          .expectStatus(200)
          .test();
    });
  });
}
