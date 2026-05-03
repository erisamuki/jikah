import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'services/theme_service.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const JikahApp());
}

class JikahApp extends StatelessWidget {
  const JikahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Jikah',
            debugShowCheckedModeBanner: false,
            theme: JikahTheme.lightTheme,
            darkTheme: JikahTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
