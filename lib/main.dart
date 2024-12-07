import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/display/about-us.dart';
import 'display/contact-us.dart';
import 'display/home-page.dart';
import 'display/landing-page.dart';
import 'display/profile-page.dart';
import 'display/registration.dart';
import 'display/signin-page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U-Find',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green[600],
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SplashScreen(),
        '/homepage': (context) => HomePage(),
        '/signin': (context) => SigninPage(),
        '/registration': (context) => RegistrationPage(),
        '/profile': (context) => ProfilePage(),
        '/about-us': (context) => AboutUsPage(),
        '/contact-us': (context) =>  ContactUsPage(), // Add this line

      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkFirstTime();
  }

  /// Asynchronous method to check first-time usage
  Future<void> checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;

    /// Navigate based on first-time status
    if (isFirstTime) {
      await prefs.setBool('first_time', false);
      _navigateTo(const LandingPage());
    } else {
      _navigateTo(const SigninPage());
    }
  }

  /// Centralized navigation method
  void _navigateTo(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Simple splash screen with loading indicator
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
