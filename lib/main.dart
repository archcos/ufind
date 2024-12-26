import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/display/about_us.dart';
import 'package:untitled/display/browse_items.dart';
import 'package:untitled/display/create_ticket.dart';
import 'package:untitled/display/contact_us.dart';
import 'package:untitled/display/home_page.dart';
import 'package:untitled/display/landing-page.dart';
import 'package:untitled/display/message_list.dart';
import 'package:untitled/display/my_ticket.dart';
import 'package:untitled/display/profile_page.dart';
import 'package:untitled/display/registration.dart';
import 'package:untitled/display/signin_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _initializeNotifications(BuildContext context) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Request notification permission for Android 13 and higher
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Notification permission granted");
  } else {
    print("Notification permission denied");
  }

  // Register notification tap handling
  flutterLocalNotificationsPlugin
      .initialize(initializationSettings, onDidReceiveNotificationResponse: (response) {
    if (response.payload != null) {
      print('Notification tapped with payload: ${response.payload}');
      _onSelectNotification(context, response.payload);
    }
  });
}

Future<String?> _getSchoolId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_school_id');
}

Future<void> _onSelectNotification(BuildContext context, String? payload) async {
  if (payload != null) {
    print('Notification payload: $payload');
    if (payload == 'unread_messages') {
      String? userId = await _getSchoolId(); // Await the result of _getSchoolId

      if (userId != null) {
        // Use the awaited userId for navigation
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MessagesListPage(userId: userId)),
        );
      } else {
        // Handle the case when userId is null
        print('User ID is null');
      }
    }
  }
}

Future<void> fetchUnreadMessages() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_school_id');

  if (userId != null) {
    final unreadsStream = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();

    unreadsStream.listen((snapshot) {
      int unreadCount = snapshot.docs.length;

      if (unreadCount > 0) {
        _showNotification(unreadCount);
      }
    });
  }
}

Future<void> _showNotification(int unreadCount) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'unread_messages_channel',
    'Unread Messages',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    0,
    'New Unread Messages',
    'You have $unreadCount unread messages.',
    platformChannelSpecifics,
    payload: 'unread_messages', // Set the payload
  );
}

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  print('[BackgroundFetch] Headless task: ${task.taskId}');
  await fetchUnreadMessages();
  BackgroundFetch.finish(task.taskId);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://tqvgagdffmjtxswldtgm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxdmdhZ2RmZm1qdHhzd2xkdGdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI3MTExMTgsImV4cCI6MjA0ODI4NzExOH0.nf0tUCRt36slpg5H-f7FUQEdrU3FUe5KNtQoX56xHXY',  // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize notifications with context
    _initializeNotifications(context);

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
        '/contact-us': (context) => ContactUsPage(),
        '/create-ticket': (context) => TicketDetailsPage(),
        '/browse-items': (context) => ItemsListPage(),
        '/my-tickets': (context) => MyTicketPage(),
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

  Future<void> checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _navigateTo(HomePage());
    } else {
      if (isFirstTime) {
        await prefs.setBool('first_time', false);
        _navigateTo(const LandingPage());
      } else {
        _navigateTo(const SigninPage());
      }
    }
  }

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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
