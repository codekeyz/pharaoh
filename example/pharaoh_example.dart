import 'package:pharaoh/pharaoh.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final pharaoh = Pharaoh();

void main() async {
  /// Using shelf_cors_header with Pharoah
  pharaoh.use(useShelfMiddleware(corsHeaders()));
  pharaoh.use(logRequests);

  final guestRouter = pharaoh.router()
    ..use((req, res, next) => null)
    ..get('/user', (req, res) => null)
    ..post('/hello', (req, res) => null)
    ..put('/put', (req, res) => null)
    ..delete('/delete', (req, res) => null);

  final adminRouter = pharaoh.router()
    ..use((req, res, next) => null)
    ..get('/user', (req, res) => null)
    ..post('/hello', (req, res) => null)
    ..put('/put', (req, res) => null)
    ..delete('/delete', (req, res) => null);

  pharaoh.useOnPath('/chief', guestRouter);

  pharaoh.useOnPath('/bigchief', adminRouter);

  await pharaoh.listen();
}
