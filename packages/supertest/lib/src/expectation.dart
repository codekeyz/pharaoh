abstract class ExpectationBase<Actual, Return> {
  ExpectationBase(this.actual);

  /// The value that is tested
  final Actual actual;

  Future<void> test();
}
