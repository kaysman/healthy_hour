import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/features/home/home.dart';
import 'package:healthy_hour/src/features/settings/settings.dart';
import 'package:uuid/uuid.dart';

GoRouter buildRouter({
  required SessionRepository sessions,
  required SettingsRepository settings,
  required HydrationRepository hydration,
}) {
  const uuid = Uuid();
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => BlocProvider(
          create: (_) => HomeBloc(
            sessions: sessions,
            settings: settings,
            hydration: hydration,
            switchActivity: SwitchActivity(sessions),
            getTodaySessions: GetTodaySessions(sessions),
            updateSession: UpdateSession(sessions),
            deleteSession: DeleteSession(sessions),
            logDrink: LogDrink(hydration),
            removeDrink: RemoveDrink(hydration),
            undoSwitchActivity: UndoSwitchActivity(sessions),
            idGenerator: uuid.v4,
          )..add(const HomeStarted()),
          child: HomePage(onOpenSettings: () => context.go('/settings')),
        ),
        // Nested so `/settings` stacks on top of Home: the AppBar gets a
        // back button and Android's back gesture returns to Home.
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, _) => BlocProvider(
              create: (_) => SettingsBloc(repository: settings)
                ..add(const SettingsStarted()),
              child: const SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
