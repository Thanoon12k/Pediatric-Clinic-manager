import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.boxSettings);
  await Hive.openBox(AppConstants.boxOfflineQueue);

  // Do not crash or create a misleading login page when backend settings
  // are missing from a fresh clone or a public CI build.
  if (!EnvConfig.isConfigured) {
    runApp(const _ConfigurationRequiredApp());
    return;
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  setupAuthRedirectListener(appRouter);
  runApp(const ProviderScope(child: YadatiApp()));
}

class _ConfigurationRequiredApp extends StatelessWidget {
  const _ConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'عيادتي',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              height: 88, width: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('عيادتي', style: TextStyle(
              fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'يلزم إعداد اتصال العيادة بقاعدة البيانات قبل البدء.\n'
              'أضف SUPABASE_URL و SUPABASE_ANON_KEY وقت إنشاء التطبيق.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      )),
    ),
  );
}

class YadatiApp extends StatefulWidget {
  const YadatiApp({super.key});
  @override State<YadatiApp> createState() => _YadatiAppState();
}

class _YadatiAppState extends State<YadatiApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.boxSettings);
    final language = box.get(AppConstants.keyLocale, defaultValue: 'ar') as String;
    final theme = box.get(AppConstants.keyThemeMode, defaultValue: 'light') as String;
    _locale = Locale(language == 'en' ? 'en' : 'ar');
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: _themeMode,
    locale: _locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: appRouter,
  );
}
