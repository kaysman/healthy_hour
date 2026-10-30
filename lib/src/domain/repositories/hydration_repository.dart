abstract class HydrationRepository {
  /// The most recent logged drink, or `null` if none has ever been logged.
  Stream<DateTime?> watchLastDrink();

  /// Every logged drink at or after [from], oldest first.
  Stream<List<DateTime>> watchDrinks({DateTime? from});

  Future<void> logDrink(DateTime at);

  /// Removes the drink logged at exactly [at]. A no-op if there is none.
  Future<void> removeDrink(DateTime at);
}
