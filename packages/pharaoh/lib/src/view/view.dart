import 'dart:async';
import 'dart:isolate';

import '../core.dart';

import '../router/router_handler.dart';
import '../utils/exceptions.dart';
import '../shelf_interop/shelf.dart' as shelf;

abstract class ViewEngine {
  String get name;

  FutureOr<String> render(String template, Map<String, dynamic> data);
}

class ViewRenderData {
  final String name;
  final Map<String, dynamic> data;
  const ViewRenderData(this.name, this.data);
}

final ReqResHook viewRenderHook = (ReqRes reqRes) async {
  var res = reqRes.res;
  final viewData = res.viewToRender;
  if (viewData == null) return reqRes;

  final viewEngine = $PharaohImpl.viewEngine_;
  if (viewEngine == null) throw PharaohException('No view engine found');

  try {
    final result = await Isolate.run(
      () => viewEngine.render(viewData.name, viewData.data),
    );
    res = res.end()..body = shelf.ShelfBody(result);
  } catch (e) {
    throw PharaohException.value('Failed to render view ${viewData.name}', e);
  }

  return reqRes.merge(res);
};
