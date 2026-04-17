import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on phone; allow all on tablet/web
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.boxSettings);
  await Hive.openBox(AppConstants.boxOfflineQueue);

  // Load .env
  await dotenv.load(fileName: '.env');

  // Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // DI
  await setupInjection();

  runApp(const YadatiApp());
}

class YadatiApp extends StatefulWidget {
  const YadatiApp({super.key});
  @override State<YadatiApp> createState() => _YadatiAppState();
}

class _YadatiAppState extends State<YadatiApp> {
  // Read saved locale from Hive
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.boxSettings);
    final savedLocale = box.get(AppConstants.keyLocale, defaultValue: 'ar') as String;
    final savedTheme = box.get(AppConstants.keyThemeMode, defaultValue: 'light') as String;
    _locale = Locale(savedLocale);
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }



  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp.router(
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
      ),
    );
  }
}
