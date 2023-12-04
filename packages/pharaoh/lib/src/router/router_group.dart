import 'package:spanner/spanner.dart';
import 'router_mixin.dart';
import 'router_contract.dart';

class GroupRouter extends RouterContract<GroupRouter>
    with RouteDefinitionMixin {
  GroupRouter() {
    useSpanner(Spanner());
  }
}
