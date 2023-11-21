# Pharaoh 🏇

[![Dart CI](https://github.com/codekeyz/pharaoh/workflows/Dart/badge.svg)](https://github.com/codekeyz/pharaoh/actions/workflows/dart.yml)
[![Pub Version](https://img.shields.io/pub/v/pharaoh?color=green)](https://pub.dev/packages/pharaoh)
[![popularity](https://img.shields.io/pub/popularity/pharaoh?logo=dart)](https://pub.dev/packages/pharaoh/score)
[![likes](https://img.shields.io/pub/likes/pharaoh?logo=dart)](https://pub.dev/packages/pharaoh/score)
[![style: flutter lints](https://img.shields.io/badge/linter-dart__lints-blue)](https://pub.dev/packages/lints)

## Features

- Robust routing
- Focus on high performance
- Super-high test coverage _(need more hands, peep the issues and contribute)_
- HTTP helpers (just like ExpressJS)
- Interoperability with Shelf Middlewares [See here](SHELF_INTEROP.md)

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharaoh: ^0.0.4 # requires Dart => ^3.0.0
```

## Basic Usage:

```dart
import 'package:pharaoh/pharaoh.dart';

final app = Pharaoh();

void main() async {

  app.use(logRequests);

  app.get('/foo', (req, res) => res.ok("bar"));

  final guestRouter = app.router()
    ..get('/user', (req, res) => res.ok("Hello World"))
    ..post('/post', (req, res) => res.json({"mee": "moo"}))
    ..put('/put', (req, res) => res.json({"pookey": "reyrey"}));

  app.group('/guest', guestRouter);

  await app.listen(); // port => 3000
}

```

See the [Pharaoh Examples](./pharaoh_examples/lib/) directory for more practical use-cases.

## Philosophy

Pharaoh emerges as a backend framework, inspired by the likes of ExpressJS, to empower developers in building comprehensive server-side applications using Dart. The driving force behind Pharaoh's creation is a strong belief in the potential of Dart to serve as the primary language for developing the entire architecture of a company's product. Just as the JavaScript ecosystem has evolved, Pharaoh aims to contribute to the Dart ecosystem, providing a foundation for building scalable and feature-rich server-side applications.

## Contributors ✨

The Pharaoh project welcomes all constructive contributions. Contributions take many forms,
from code for bug fixes and enhancements, to additions and fixes to documentation, additional
tests, triaging incoming pull requests and issues, and more!

### Running Tests

To run the test suite, first install the dependencies, then run `dart test`:

```console
$ dart pub get
$ dart test
```

## People

The original author of Pharaoh is [Chima Precious](https://github.com/codekeyz)

[List of all contributors](https://github.com/codekeyz/pharaoh/graphs/contributors)

## License

[MIT](LICENSE)
