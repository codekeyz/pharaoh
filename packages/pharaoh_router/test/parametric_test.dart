import 'package:pharaoh/pharaoh.dart';
import 'package:pharaoh_router/pharaoh_router.dart';
import 'package:test/test.dart';

void main() {
  test('parametric route, request.url contains dash', () {
    final router = RadixRouter()..insert(HTTPMethod.GET, '/a/:param/b');
    final result = router.lookup(HTTPMethod.GET, '/a/foo-bar/b');
    expect(result!.value, {'param': 'foo-bar'});
  });

  test('parametric route with fixed suffix', () {
    final router = RadixRouter()
      ..insert(HTTPMethod.GET, '/a/:param-static')
      ..insert(HTTPMethod.GET, '/b/:param.static');

    expect(router.lookup(HTTPMethod.GET, '/a/param-static')?.value,
        {'param': 'param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param.static')?.value,
        {'param': 'param'});

    expect(router.lookup(HTTPMethod.GET, '/a/param-param-static')?.value,
        {'param': 'param-param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param.param.static')?.value,
        {'param': 'param.param'});

    expect(router.lookup(HTTPMethod.GET, '/a/param.param-static')?.value,
        {'param': 'param.param'});
    expect(router.lookup(HTTPMethod.GET, '/b/param-param.static')?.value,
        {'param': 'param-param'});
  });
}
