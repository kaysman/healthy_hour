import 'package:healthy_hour/src/domain/repositories/hydration_repository.dart';

/// Records a drink, which restarts the water countdown. Wired to the `+` on
/// the Water card.
class LogDrink {
  const LogDrink(this._repo);
  final HydrationRepository _repo;

  Future<void> call({required DateTime now}) => _repo.logDrink(now);
}
