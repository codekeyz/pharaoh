# spookie 🎌

Easy & composable tests for your API's. I wrote this to work just like https://www.npmjs.com/package/supertest

## Installing:

In your pubspec.yaml

```yaml
dev_dependencies:
  spookie:
```

## Basic Usage:

```dart
import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

void main() async {

  final app = Pharaoh().get('/', (req, res) {
        return res
            .type(ContentType.parse('application/vnd.example+json'))
            .json({"hello": "world"});
      });

  await app.listen(port: 5000);


  test('should not override previous Content-Types', () async {

      await Spookie.uri(Uri.parse('http://localhost:5000')).get('/')
          .expectStatus(200)
          .expectContentType('application/vnd.example+json')
          .expectBody('{"hello":"world"}')
          .test();

  });
}

```

## Tests

The cases in the `spookie_test.dart` are also used for automated testing. So if you want  
to contribute or just make sure that the package still works, simply run:

```shell
dart test
```
