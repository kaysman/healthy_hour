import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/settings/settings.dart';

import '../../helpers/fakes.dart';

void main() {
  const window = WorkingWindow(startMinutes: 8 * 60, endMinutes: 17 * 60);
  const tenMinutes = TimerConfig(interval: Duration(minutes: 10));
  const fortyMinutes = TimerConfig(interval: Duration(minutes: 40));

  late FakeSettingsRepository repo;

  setUp(() => repo = FakeSettingsRepository());

  blocTest<SettingsBloc, SettingsState>(
    'hydrates from the repository on start',
    setUp: () => repo = FakeSettingsRepository(
      window: window,
      water: tenMinutes,
      walking: fortyMinutes,
    ),
    build: () => SettingsBloc(repository: repo),
    act: (bloc) => bloc.add(const SettingsStarted()),
    expect: () => [
      const SettingsState(
        window: window,
        water: tenMinutes,
        walking: fortyMinutes,
      ),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'a window change is shown immediately and persisted',
    build: () => SettingsBloc(repository: repo),
    act: (bloc) => bloc.add(const SettingsWindowChanged(window)),
    expect: () => [const SettingsState(window: window)],
    verify: (_) async => expect(await repo.getWorkingWindow(), window),
  );

  blocTest<SettingsBloc, SettingsState>(
    'a water interval change is shown immediately and persisted',
    build: () => SettingsBloc(repository: repo),
    act: (bloc) => bloc.add(const SettingsWaterChanged(tenMinutes)),
    expect: () => [const SettingsState(water: tenMinutes)],
    verify: (_) async => expect(await repo.getWaterConfig(), tenMinutes),
  );

  blocTest<SettingsBloc, SettingsState>(
    'a walking interval change is shown immediately and persisted',
    build: () => SettingsBloc(repository: repo),
    act: (bloc) => bloc.add(const SettingsWalkingChanged(fortyMinutes)),
    expect: () => [const SettingsState(walking: fortyMinutes)],
    verify: (_) async => expect(await repo.getWalkingConfig(), fortyMinutes),
  );

  blocTest<SettingsBloc, SettingsState>(
    'follows changes made elsewhere after start',
    build: () => SettingsBloc(repository: repo),
    act: (bloc) async {
      bloc.add(const SettingsStarted());
      await pumpEventQueue();
      await repo.setWaterConfig(tenMinutes);
    },
    // Bloc always emits the first state, even when it equals the initial one.
    expect: () => [
      const SettingsState(),
      const SettingsState(water: tenMinutes),
    ],
  );
}
