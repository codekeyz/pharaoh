import 'dart:io';

import 'package:pharaoh/pharaoh.dart';

final app = Pharaoh();

void main() async {
  /// path to where the files are stored on disk
  final publicDir = '${Directory.current.path}/public/web_demo_1';

  app.get('/', (req, res) async {
    final file = File('$publicDir/index.html');
    final exists = await file.exists();
    if (!exists) {
      return res.status(404).send('"Cant find that file, sorry!"');
    }
    return res.type(ContentType.html).send(file.openRead());
  });

  /// /files/* is accessed via req.params[*]
  /// but here we name it <file>
  app.get('/files/<file>', (req, res) async {
    final pathToFile = req.params['file'];
    final file = File('$publicDir/files/$pathToFile');
    final exists = await file.exists();
    if (!exists) {
      return res.status(404).send('"Cant find that file, sorry!"');
    }

    return res.send(file.openRead());
  });

  await app.listen(port: 3000);
}
