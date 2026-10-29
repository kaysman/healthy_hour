abstract class HydrationRepository {
  /// The most recent logged drink, or `null` if none has ever been logged.
  Stream<DateTime?> watchLastDrink();

  Future<void> logDrink(DateTime at);
}
