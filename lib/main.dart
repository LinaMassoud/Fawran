import 'package:fawran/Fawran4Hours/hourly_service_screen.dart';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/screens/bookings.dart';
import 'package:fawran/screens/launchScreen.dart';
import 'package:fawran/screens/location_screen.dart';
import 'package:fawran/screens/login_screen.dart';
import 'package:fawran/screens/newcombined.dart';
import 'package:fawran/screens/newhome.dart';
import 'package:fawran/screens/pdf.dart';
import 'package:fawran/screens/select_address.dart';
import 'package:fawran/screens/userProfile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flashy_flushbar/flashy_flushbar.dart';

// Create a global instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// Background message handler - must be top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message: ${message.notification?.title}');
}

Future<void> initLocalNotifications() async {
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      print('Notification tapped: ${response.payload}');
    },
  );
}

Future<void> showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'firebase_channel_id',
    'Firebase Notifications',
    channelDescription: 'Firebase push notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformChannelSpecifics,
    payload: payload,
  );
}

Future<void> initNotificationsIOS() async {
  // Initialize local notifications first
  await initLocalNotifications();
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle notification tap when app is terminated
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print(
        '🚀 App launched from notification: ${initialMessage.notification?.title}');
    // Handle navigation based on notification data
  }

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 Notification tapped: ${message.notification?.title}');
    // Handle navigation based on notification data
  });

  // Handle foreground messages and show local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('📨 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      print('Notification Body: ${message.notification!.body}');

      // Show local notification for iOS foreground messages
      await showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load();
  await initNotificationsIOS();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ User granted permission");

    // iOS only: wait for APNS token
    String? apnsToken = await messaging.getAPNSToken();
    print("📱 APNS Token: $apnsToken");
  } else {
    print("❌ User declined permission");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider); // Reactively watch locale

    return MaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // overrides default gray
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // optional, match AppBar
          elevation: 0,
        ),
      ),
      builder: FlashyFlushbarProvider.init(),
      home: const LaunchScreen(),
      routes: {
        // '/login' key routes to LoginScreen widget
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/bookings': (context) => const BookingsScreen(),
        '/location': (context) => const LocationScreen(),
        '/home': (contex) => Newhome(),
        '/hourly': (context) => HourlyServiceScreen(),
        '/selectAddress': (context) => AddressSelectionScreen(),
        '/pdf': (context) => HtmlToPdfScreen(
            title: "contract", htmlAssetPath: "assets/responsive_my_rep.html")

        // '/profile' key routes to UserProfileScreen widget
      },
    );
  }
}
