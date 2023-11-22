import 'dart:io';

import 'package:pharaoh/pharaoh.dart';
import 'package:spookie/spookie.dart';

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
        .expectStatus(200)
        .expectContentType('application/vnd.example+json')
        .expectBody('{"hello":"world"}')
        .test();
  });
}
