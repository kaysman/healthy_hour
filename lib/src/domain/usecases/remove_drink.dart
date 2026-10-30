import 'package:healthy_hour/src/domain/repositories/hydration_repository.dart';

/// Deletes one logged drink — from the hour sheet, or when a just-logged
/// drink is undone. The water countdown falls back to the drink before it.
class RemoveDrink {
  const RemoveDrink(this._repo);
  final HydrationRepository _repo;

  Future<void> call(DateTime at) => _repo.removeDrink(at);
}
