import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  // Temporarily disable Firebase initialization
  // try {
  //   await Firebase.initializeApp();
  //   print('Firebase initialized successfully');
  // } catch (e) {
  //   print('Failed to initialize Firebase: $e');
  //   // Continue without Firebase for now
  // }
  debugPrint('Firebase initialization skipped');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<ConnectivityResult>(
          create: (_) => Connectivity().onConnectivityChanged,
          initialData: ConnectivityResult.none,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        // Add more providers as needed
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Savessa',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
