import 'package:echopay/services/auth/auth_gate.dart';
import 'package:echopay/theme/theme_provider.dart';
import 'package:echopay/components/my_navigator_observer.dart';
import 'package:echopay/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

@pragma('vm:entry-point')
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  await Hive.openBox('settings');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("MyApp Rebuilt");

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedTheme(
          duration: const Duration(milliseconds: 300),
          data: themeProvider.themeData,
          child: MaterialApp(
            navigatorObservers: [MyNavigatorObserver()],
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            navigatorKey: navigatorKey,
            home: const AuthGate(),
          ),
        );
      },
    );
  }
}

//flutter build appbundle --release --obfuscate --split-debug-info=./debug-symbols/

//To add new device, dev mode --> adb devices

//firebase deploy --only functions
