import 'package:pharaoh/pharaoh_next.dart';
import 'package:spookie/spookie.dart';

import './router_test.reflectable.dart';
import 'core/core_test.dart';

class TestController extends HTTPController {
  void create() {}

  void index() {}

  void show() {}

  void update() {}

  void delete() {}
}

void main() {
  setUpAll(initializeReflectable);

  group('Router', () {
    group('when route group', () {
      test('with routes', () {
        final group = Route.group('merchants', [
          Route.get('/get', (TestController, #index)),
          Route.delete('/delete', (TestController, #delete)),
          Route.put('/update', (TestController, #update)),
        ]);

        expect(group.paths, [
          '[GET]: /merchants/get',
          '[DELETE]: /merchants/delete',
          '[PUT]: /merchants/update',
        ]);
      });

      test('with prefix', () {
        final group = Route.group(
          'Merchants',
          [
            Route.get('/foo', (TestController, #index)),
            Route.delete('/bar', (TestController, #delete)),
            Route.put('/moo', (TestController, #update)),
          ],
          prefix: 'foo',
        );

        expect(group.paths, [
          '[GET]: /foo/foo',
          '[DELETE]: /foo/bar',
          '[PUT]: /foo/moo',
        ]);
      });

      test('with handler', () {
        final group = Route.group('users', [
          Route.route(HTTPMethod.GET, '/my-name', (req, res) => null),
        ]);
        expect(group.paths, ['[GET]: /users/my-name']);
      });

      test('with sub groups', () {
        final group = Route.group('users', [
          Route.get('/get', (TestController, #index)),
          Route.delete('/delete', (TestController, #delete)),
          Route.put('/update', (TestController, #update)),
          //
          Route.group('customers', [
            Route.get('/foo', (TestController, #index)),
            Route.delete('/bar', (TestController, #delete)),
            Route.put('/set', (TestController, #update)),
          ]),
        ]);

        expect(group.paths, [
          '[GET]: /users/get',
          '[DELETE]: /users/delete',
          '[PUT]: /users/update',
          '[GET]: /users/customers/foo',
          '[DELETE]: /users/customers/bar',
          '[PUT]: /users/customers/set',
        ]);
      });

      group('when middlewares used', () {
        test('should add to routes', () {
          final group = Route.group('users', [
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            //
            Route.group('customers', [
              Route.get('/foo', (TestController, #index)),
              Route.delete('/bar', (TestController, #delete)),
              Route.put('/set', (TestController, #update)),
            ]),
          ]);

          expect(group.paths, [
            '[GET]: /users/get',
            '[DELETE]: /users/delete',
            '[PUT]: /users/update',
            '[GET]: /users/customers/foo',
            '[DELETE]: /users/customers/bar',
            '[PUT]: /users/customers/set',
          ]);
        });

        test('should handle nested groups', () {
          final group = Route.group('users', [
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            //
            Route.group('customers', [
              Route.get('/foo', (TestController, #index)),
              Route.delete('/bar', (TestController, #delete)),
              Route.put('/set', (TestController, #update)),
            ]),
          ]);

          expect(group.paths, [
            '[GET]: /users/get',
            '[DELETE]: /users/delete',
            '[PUT]: /users/update',
            '[GET]: /users/customers/foo',
            '[DELETE]: /users/customers/bar',
            '[PUT]: /users/customers/set',
          ]);
        });
      });

      test('when handle route resource', () {
        final group =
            Route.group('foo', [Route.resource('bar', TestController)])
              ..middleware([
                (req, res, next) => next(),
                (req, res, next) => next(),
              ]);

        expect(group.paths, [
          '[ALL]: /foo',
          '[GET]: /foo/bar',
          '[GET]: /foo/bar/<barId>',
          '[POST]: /foo/bar',
          '[PUT]: /foo/bar/<barId>',
          '[PATCH]: /foo/bar/<barId>',
          '[DELETE]: /foo/bar/<barId>'
        ]);
      });

      test('when handle route resource', () {
        final group = Route.group('foo', [
          Route.resource('bar', TestController),
        ]);

        expect(group.paths, [
          '[GET]: /foo/bar',
          '[GET]: /foo/bar/<barId>',
          '[POST]: /foo/bar',
          '[PUT]: /foo/bar/<barId>',
          '[PATCH]: /foo/bar/<barId>',
          '[DELETE]: /foo/bar/<barId>'
        ]);
      });

      test('when used with middleware', () {
        TestKidsApp();

        final group = Route.middleware('api').group('merchants', [
          Route.route(HTTPMethod.GET, '/create', (req, res) => null),
          Route.group('users', [
            Route.get('/get', (TestController, #index)),
            Route.delete('/delete', (TestController, #delete)),
            Route.put('/update', (TestController, #update)),
            Route.middleware('api').group('hello', [
              Route.get('/world', (TestController, #index)),
            ])
          ]),
        ]);

        expect(group.paths, [
          '[ALL]: /merchants',
          '[GET]: /merchants/create',
          '[GET]: /merchants/users/get',
          '[DELETE]: /merchants/users/delete',
          '[PUT]: /merchants/users/update',
          '[ALL]: /merchants/users/hello',
          '[GET]: /merchants/users/hello/world'
        ]);

        var route = Route.middleware('api').routes([
          Route.get('/get', (TestController, #index)),
        ]);

        expect(route.paths, ['[ALL]: /', '[GET]: /get']);

        route = Route.group('users', [route]);
        expect(route.paths, ['[ALL]: /users', '[GET]: /users/get']);

        route = Route.group('admin', [
          route,
          Route.middleware('api').routes([
            Route.get('/boys', (TestController, #index)),
          ])
        ]);

        expect(route.paths, [
          '[ALL]: /admin/users',
          '[GET]: /admin/users/get',
          '[ALL]: /admin',
          '[GET]: /admin/boys'
        ]);
      });
    });

    test('should error when controller method not found', () {
      expect(
        () => Route.group(
            'Merchants', [Route.get('/foo', (TestController, #foobar))],
            prefix: 'foo'),
        throwsA(isA<ArgumentError>().having((p0) => p0.message, '',
            'TestController does not have method  #foobar')),
      );
    });
  });
}
