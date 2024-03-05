import 'dart:io';

import 'package:pharaoh/next/core.dart';
import 'package:pharaoh/next/router.dart';
import 'package:pharaoh/next/validation.dart';

import 'package:spookie/spookie.dart';

import 'meta_test.reflectable.dart';

class TestDTO extends BaseDTO {
  String get username;

  String get lastname;

  int get age;
}

Pharaoh get pharaohWithErrorHdler => Pharaoh()
  ..onError((error, req, res) {
    final exception = error.exception;
    if (exception is RequestValidationError) {
      return res.json(exception.errorBody, statusCode: 422);
    }

    return res.internalServerError(error.toString());
  });

void main() {
  initializeReflectable();

  group('Meta', () {
    group('Param', () {
      test('should use name set in meta', () async {
        final app = pharaohWithErrorHdler
          ..get('/<userId>/hello', (req, res) {
            final actualParam = Param('userId');
            const ctrlMethodParam = ControllerMethodParam('user', String);

            return res.ok(actualParam.process(req, ctrlMethodParam));
          });

        await (await request(app))
            .get('/234/hello')
            .expectStatus(200)
            .expectBody('234')
            .test();
      });

      test(
          'should use controller method property name if meta name not provided',
          () async {
        final app = pharaohWithErrorHdler
          ..get('/boys/<user>', (req, res) {
            const ctrlMethodParam = ControllerMethodParam('user', String);

            final result = param.process(req, ctrlMethodParam);
            return res.ok(result);
          });

        await (await request(app))
            .get('/boys/499')
            .expectStatus(200)
            .expectBody('499')
            .test();
      });

      test('when param value not valid', () async {
        final app = pharaohWithErrorHdler
          ..get('/test/<userId>', (req, res) {
            const ctrlMethodParam = ControllerMethodParam('userId', int);

            final result = Param().process(req, ctrlMethodParam);
            return res.ok(result.toString());
          });

        await (await request(app))
            .get('/test/asfkd')
            .expectStatus(422)
            .expectJsonBody({
          'location': 'param',
          'errors': ['userId must be a int type']
        }).test();

        await (await request(app))
            .get('/test/2345')
            .expectStatus(200)
            .expectBody('2345')
            .test();
      });
    });

    group('Query', () {
      test('should use name set in query', () async {
        final app = pharaohWithErrorHdler
          ..get('/foo', (req, res) {
            final actualParam = Query('userId');
            const ctrlMethodParam = ControllerMethodParam('user', String);

            final result = actualParam.process(req, ctrlMethodParam);
            return res.ok(result);
          });

        await (await request(app))
            .get('/foo?userId=Chima')
            .expectStatus(200)
            .expectBody('Chima')
            .test();
      });

      test(
          'should use controller method property name if Query name not provided',
          () async {
        final app = pharaohWithErrorHdler
          ..get('/bar', (req, res) {
            const ctrlMethodParam = ControllerMethodParam('userId', String);

            final result = query.process(req, ctrlMethodParam);
            return res.ok(result);
          });

        await (await request(app))
            .get('/bar?userId=Precious')
            .expectStatus(200)
            .expectBody('Precious')
            .test();
      });

      test('when Query value not valid', () async {
        final app = pharaohWithErrorHdler
          ..get('/moo', (req, res) {
            const ctrlMethodParam = ControllerMethodParam('name', int);

            final result = query.process(req, ctrlMethodParam);
            return res.ok(result.toString());
          });

        await (await request(app))
            .get('/moo?name=Chima')
            .expectStatus(422)
            .expectJsonBody({
          'location': 'query',
          'errors': ['name must be a int type']
        }).test();

        await (await request(app))
            .get('/moo')
            .expectStatus(422)
            .expectBody('{"location":"query","errors":["name is required"]}')
            .test();

        await (await request(app))
            .get('/moo?name=244')
            .expectStatus(200)
            .expectBody('244')
            .test();
      });
    });

    group('Header', () {
      test('should use name set in meta', () async {
        final app = pharaohWithErrorHdler
          ..get('/foo', (req, res) {
            final actualParam = Header(HttpHeaders.authorizationHeader);
            const ctrlMethodParam = ControllerMethodParam('token', String);

            final result = actualParam.process(req, ctrlMethodParam);
            return res.json(result);
          });

        await (await request(app))
            .get('/foo', headers: {
              HttpHeaders.authorizationHeader: 'foo token',
            })
            .expectStatus(200)
            .expectJsonBody('[foo token]')
            .test();
      });

      test(
          'should use controller method property name if meta name not provided',
          () async {
        final app = pharaohWithErrorHdler
          ..get('/bar', (req, res) {
            final result =
                header.process(req, ControllerMethodParam('token', String));
            return res.ok(result);
          });

        await (await request(app))
            .get('/bar', headers: {'token': 'Hello Token'})
            .expectStatus(200)
            .expectBody('[Hello Token]')
            .test();
      });

      test('when Header value not valid', () async {
        final app = pharaohWithErrorHdler
          ..get('/moo', (req, res) {
            final result =
                header.process(req, ControllerMethodParam('age_max', String));
            return res.ok(result.toString());
          });

        await (await request(app))
            .get('/moo', headers: {'age_max': 'Chima'})
            .expectStatus(200)
            .expectBody('[Chima]')
            .test();

        await (await request(app))
            .get('/moo')
            .expectStatus(422)
            .expectBody(
                '{"location":"header","errors":["age_max is required"]}')
            .test();
      });
    });

    group('Body', () {
      test('should use name set in meta', () async {
        final app = pharaohWithErrorHdler
          ..post('/hello', (req, res) {
            final actualParam = Body();
            final result = actualParam.process(
                req, ControllerMethodParam('reqBody', dynamic));
            return res.json(result);
          });
        await (await request(app))
            .post('/hello', {'foo': "bar"})
            .expectStatus(200)
            .expectJsonBody({'foo': 'bar'})
            .test();
      });

      test('when body not provided', () async {
        final app = pharaohWithErrorHdler
          ..post('/test', (req, res) {
            final result =
                body.process(req, ControllerMethodParam('reqBody', dynamic));
            return res.ok(result.toString());
          });

        await (await request(app))
            .post('/test', null)
            .expectStatus(422)
            .expectJsonBody({
          'location': 'body',
          'errors': ['body is required']
        }).test();

        await (await request(app))
            .post('/test', {'hello': 'Foo'})
            .expectStatus(200)
            .expectBody('{hello: Foo}')
            .test();
      });

      test('when dto provided', () async {
        final dto = TestDTO();
        final testData = {'username': 'Foo', 'lastname': 'Bar', 'age': 22};

        final app = pharaohWithErrorHdler
          ..post('/mongo', (req, res) {
            final actualParam = Body();
            final result = actualParam.process(
                req, ControllerMethodParam('reqBody', TestDTO, dto: dto));
            return res
                .json({'username': result is TestDTO ? result.username : null});
          });

        await (await request(app))
            .post('/mongo', {})
            .expectStatus(422)
            .expectJsonBody({
              'location': 'body',
              'errors': [
                'username: The field is required',
                'lastname: The field is required',
                'age: The field is required'
              ]
            })
            .test();

        await (await request(app))
            .post('/mongo', testData)
            .expectStatus(200)
            .expectJsonBody({'username': 'Foo'}).test();
      });
    });
  });
}
