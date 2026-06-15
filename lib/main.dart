import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teams_chat/core/router/app_router.dart';
import 'package:teams_chat/core/theme/app_theme.dart';
import 'package:teams_chat/data/datasources/local/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences must be loaded before any provider reads it synchronously.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the pre-loaded SharedPreferences instance so providers that
        // call ref.read(sharedPreferencesProvider) get the real object.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TeamsChatApp(),
    ),
  );
}

class TeamsChatApp extends ConsumerWidget {
  const TeamsChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Teams Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
