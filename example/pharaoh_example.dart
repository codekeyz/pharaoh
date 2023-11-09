import 'package:pharaoh/src/server.dart';

final pharaoh = Pharaoh();

void main() async {
  pharaoh.router.get('/', (req) async {
    print(req.certificate);
    return null;
  });

  pharaoh.router.post('/', (req) async {
    print(req.certificate);
    return null;
  });

  pharaoh.router.delete('/user', (req) => null);

  await pharaoh.listen();

  print('Server started');
  print(pharaoh.router.routes);
}
