# Pharaoh 🏇

[![Dart CI](https://github.com/codekeyz/pharaoh/workflows/Dart/badge.svg)](https://github.com/codekeyz/pharaoh/actions/workflows/dart.yml)
[![Pub Version](https://img.shields.io/pub/v/pharaoh?color=green)](https://pub.dev/packages/pharaoh)
[![popularity](https://img.shields.io/pub/popularity/pharaoh?logo=dart)](https://pub.dev/packages/pharaoh/score)
[![likes](https://img.shields.io/pub/likes/pharaoh?logo=dart)](https://pub.dev/packages/pharaoh/score)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

## Features

- Robust routing
- Focus on high performance
- Super-high test coverage
- HTTP helpers (just like ExpressJS)
- Interoperability with Shelf Middlewares [See here](https://github.com/Pharaoh-Framework/pharaoh/blob/main/packages/pharaoh/SHELF_INTEROP.md)

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharaoh: ^0.0.5 # requires Dart => ^3.0.0
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

See the [Pharaoh Examples](https://github.com/Pharaoh-Framework/pharaoh/tree/main/pharaoh_examples) directory for more practical use-cases.

## Philosophy

Pharaoh emerges as a backend framework, inspired by the likes of ExpressJS, to empower developers in building comprehensive server-side applications using Dart. The driving force behind Pharaoh's creation is a strong belief in the potential of Dart to serve as the primary language for developing the entire architecture of a company's product. Just as the JavaScript ecosystem has evolved, Pharaoh aims to contribute to the Dart ecosystem, providing a foundation for building scalable and feature-rich server-side applications.

## Contributors ✨

The Pharaoh project welcomes all constructive contributions. Contributions take many forms,
from code for bug fixes and enhancements, to additions and fixes to documentation, additional
tests, triaging incoming pull requests and issues, and more!

### Contributing Code To Pharaoh 🛠

To setup and contribute to Pharaoh, Install [`Melos`](https://melos.invertase.dev/~melos-latest) as a global package via [`pub.dev`](https://pub.dev/packages/melos);

```console
$ dart pub global activate melos
```

then initialize the workspace using the command below

```console
$ melos bootstrap
```

### Running Tests

To run the tests, you can either run `dart test` in the package you're working on or use the command below to run the full test suite:

```console
$ melos run tests
```

## People

[List of all contributors](https://github.com/codekeyz/pharaoh/graphs/contributors)

## License

[MIT](LICENSE)
