import 'package:pharaoh/src/server.dart';

final pharaoh = Pharaoh();

void main() async {
  pharaoh.router.get('/', (req, [args, hello]) async {
    return {"name": "John"};
  });

  pharaoh.router.post('/', (req) async {
    return null;
  });

  pharaoh.router.delete('/user', (req) => 'Some Error');

  await pharaoh.listen();
}
