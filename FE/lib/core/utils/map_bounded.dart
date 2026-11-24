/// Runs independent lookups in batches, preserving the input order.
Future<List<R>> mapBounded<T, R>(
  List<T> items,
  Future<R> Function(T) lookup, {
  int concurrency = 5,
}) async {
  if (concurrency < 1) throw ArgumentError.value(concurrency);
  final results = <R>[];
  for (var i = 0; i < items.length; i += concurrency) {
    results.addAll(
      await Future.wait(items.skip(i).take(concurrency).map(lookup)),
    );
  }
  return results;
}
