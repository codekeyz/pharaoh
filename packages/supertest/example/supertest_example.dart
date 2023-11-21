import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:supertest/supertest.dart';

void main() async {
  final app = Pharaoh();

  app.get('/', (req, res) {
    return res
        .type(ContentType.parse('application/vnd.example+json'))
        .json({"hello": "world"});
  });

  test('should not override previous Content-Types', () async {
    await (await request<Pharaoh>(app))
        .get('/')
        .status(200)
        .contentType('application/vnd.example+json')
        .body('{"hello":"world"}')
        .test();
  });
}
