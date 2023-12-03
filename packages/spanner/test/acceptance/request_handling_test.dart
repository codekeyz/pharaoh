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
            '{"path":"/something-new-is-here","method":"GET","message":"Route not found: /something-new-is-here"}')
        .test();

    await (await request(app))
        .delete('/home/chima')
        .expectStatus(200)
        .expectBody('Item deleted')
        .test();
  });

  group('execute middleware and request', () {
    test('of level 1', () async {
      final app = Pharaoh()
        ..use((req, res, next) => next(req..setParams('name', 'Chima')))
        ..get(
            '/foo/bar', (req, res) => res.ok('Name: ${req.params['name']} 🚀'));

      await (await request(app))
          .get('/foo/bar')
          .expectStatus(200)
          .expectBody('Name: Chima 🚀')
          .test();
    });

    test('of level 2', () async {
      final app = Pharaoh()
        ..use((req, res, next) => next(req..setParams('name', 'Chima')))
        ..use((req, res, next) => next(req..setParams('age', '14')))
        ..get('/foo/bar', (req, res) => res.json(req.params));

      await (await request(app))
          .get('/foo/bar')
          .expectStatus(200)
          .expectBody({'name': 'Chima', 'age': '14'}).test();
    });

    test('of level 3', () async {
      final app = Pharaoh()
        ..use((req, res, next) => next(req..setParams('points', '4000')))
        ..use((req, res, next) => next(req..setParams('name', 'Chima')))
        ..use((req, res, next) => next(req..setParams('age', '14')))
        ..get('/foo/bar', (req, res) => res.json(req.params));

      await (await request(app))
          .get('/foo/bar')
          .expectStatus(200)
          .expectBody({'points': '4000', 'name': 'Chima', 'age': '14'}).test();
    });

    test('in right order', () async {
      final app = Pharaoh()
        ..use((req, res, next) => next(req..setParams('name', 'Chima')))
        ..use((req, res, next) => next(req..setParams('points', '4000')))
        ..use((req, res, next) => next(req..setParams('age', '14')))
        ..get('/foo/bar', (req, res) => res.json(req.params));

      await (await request(app))
          .get('/foo/bar')
          .expectStatus(200)
          .expectBody({'name': 'Chima', 'points': '4000', 'age': '14'}).test();
    });

    test('if only request not ended', () async {
      final app = Pharaoh()
        ..use((req, res, next) => next(req..setParams('name', 'Chima')))
        ..use((req, res, next) => next(res.ok('Say hello')))
        ..get('/foo/bar', (req, res) => res.json(req.params));

      await (await request(app))
          .get('/foo/bar')
          .expectStatus(200)
          .expectBody('Say hello')
          .test();
    });
  });
}
