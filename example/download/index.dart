import 'dart:io';

import 'package:pharaoh/pharaoh.dart';

final app = Pharaoh();

void main() async {
  final scriptDir = Directory.current;
  final publicDir = '${scriptDir.path}/example/download/public';

  app.get('/', (req, res) async {
    final file = File('$publicDir/index.html');
    final exists = await file.exists();
    if (!exists) {
      return res.status(404).send('"Cant find that file, sorry!"');
    }

    res.type(ContentType.html).send(file.openRead());
  });

  app.get('/files/:file(.*)', (req, res) async {
    final file = File('$publicDir/${req.path}');
    final exists = await file.exists();
    if (!exists) return res.notFound('File not found');

    res.send(file.openRead());
  });

  await app.listen(port: 3000);
}
