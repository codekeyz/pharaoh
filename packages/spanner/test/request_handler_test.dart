import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() {
  test('should execute request', () async {
    final app = Pharaoh()
      ..get('/users/<userId>', (req, res) => res.json(req.params))
      ..get('/home/chima', (req, res) => res.ok('Okay 🚀'))
      ..post('/home/strange', (req, res) => res.ok('Post something 🚀'));

    await (await request(app))
        .get('/users/234')
        .expectStatus(200)
        .expectBody('{"userId":"234"}')
        .test();

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
        .get('/something-new-is-here')
        .expectStatus(404)
        .expectBody(
            '{"path":"/something-new-is-here","method":"GET","message":"No handlers registered for path: /something-new-is-here"}')
        .test();
  });
}
