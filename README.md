# Pharoah 🏇

[![Dart CI](https://github.com/codekeyz/pharoah/workflows/Dart/badge.svg)](https://github.com/codekeyz/pharoah/actions/workflows/dart.yml)
[![Pub Version](https://img.shields.io/pub/v/pharoah?color=green)](https://pub.dev/packages/pharoah)
[![popularity](https://img.shields.io/pub/popularity/pharoah?logo=dart)](https://pub.dev/packages/pharoah/score)
[![likes](https://img.shields.io/pub/likes/pharoah?logo=dart)](https://pub.dev/packages/pharoah/score)
[![style: flutter lints](https://img.shields.io/pharoah/style-flutter__lints-blue)](https://pub.dev/packages/flutter_lints)

## Installing:

In your pubspec.yaml

```yaml
dependencies:
  pharoah: ^1.0.0 # requires Dart => ^3.1.5
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

## Contributors ✨

Contributions of any kind welcome!
