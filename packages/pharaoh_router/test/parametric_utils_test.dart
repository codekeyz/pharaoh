import 'package:pharaoh_router/src/helpers/parametric.dart';
import 'package:test/test.dart';

void main() {
  test('parametric no suffix and no prefix', () {
    final param = ParameterDefinition.from('<param1>');
    expect(param.name, 'param1');
    expect(param.prefix, null);
    expect(param.suffix, null);
  });

  test('parametric with prefix and no prefix', () {
    final param = ParameterDefinition.from('hello<param1>');
    expect(param.name, 'param1');
    expect(param.prefix, 'hello');
    expect(param.suffix, null);
  });

  test('parametric with prefix containing symbols and no prefix', () {
    final param = ParameterDefinition.from('hello-.helo<param1>');
    expect(param.name, 'param1');
    expect(param.prefix, 'hello-.helo');
    expect(param.suffix, null);
  });

  test('parametric with suffix and no prefix', () {
    final param = ParameterDefinition.from('<param1>hello-chima');
    expect(param.name, 'param1');
    expect(param.prefix, null);
    expect(param.suffix, 'hello-chima');
  });

  test('parametric with prefix and suffix', () {
    final param = ParameterDefinition.from('hello<param1>.png');
    expect(param.name, 'param1');
    expect(param.prefix, 'hello');
    expect(param.suffix, '.png');
  });

  test('parametric with multiple parametric definitions', () {
    final param = ParameterDefinition.from(
        'hello<param1>.png<param2>hello@gmail.com<param3>');

    expect(param, isA<CompositeParameterDefinition>());
    expect(param.name, 'param1');
    expect(param.prefix, 'hello');
    expect(param.suffix, '.png');

    final subparts = (param as CompositeParameterDefinition).subparts;
    expect(subparts, hasLength(2));

    final subPartsStr = subparts.map((e) => e.toString()).toList();
    expect(subPartsStr, [
      'ParameterDefinition(param2, null, hello@gmail.com, null, false)',
      'ParameterDefinition(param3, null, null, null, true)'
    ]);
  });
}
