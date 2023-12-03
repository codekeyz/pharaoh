import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  test('should execute request', () async {
    final app = Pharaoh()
      ..get('/users/<userId>', (req, res) => res.json(req.params))
      ..post('/users/<userId>', (req, res) => res.json(req.params))
      ..get('/home/chima', (req, res) => res.ok('Okay 🚀'))
      ..delete('/home/chima', (req, res) => res.ok('Item deleted'))
      ..post('/home/strange', (req, res) => res.ok('Post something 🚀'));

    await (await request(app))
        .get('/home/chima')
        .expectStatus(200)
        .expectBody('Okay 🚀')
        .test();

    await (await request(app))
        .post('/home/strange', {})
        .expectStatus(200)
        .expectBody('Post something 🚀')
        .test();

    await (await request(app))
        .get('/users/204')
        .expectStatus(200)
        .expectBody({'userId': '204'}).test();

    await (await request(app))
        .post('/users/204398938948374797', {})
        .expectStatus(200)
        .expectBody({'userId': '204398938948374797'})
        .test();

    await (await request(app))
        .get('/something-new-is-here')
        .expectStatus(404)
        .expectBody(
            '{"path":"/something-new-is-here","method":"GET","message":"No handlers registered for path: /something-new-is-here"}')
        .test();

    await (await request(app))
        .delete('/home/chima')
        .expectStatus(200)
        .expectBody('Item deleted')
        .test();
  });
}
