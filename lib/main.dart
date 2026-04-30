import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(const LockerRakshakApp());
}

class LockerRakshakApp extends StatelessWidget {
  const LockerRakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locker Rakshak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          secondary: Color(0xFF34C759),
          surface: Color(0xFF1C1C1E),
        ),
        useMaterial3: true,
      ),
      home: const LockerHomeScreen(),
    );
  }
}
