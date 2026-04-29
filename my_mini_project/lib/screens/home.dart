import 'package:my_mini_project/screens/login.dart';
import 'package:my_mini_project/screens/game.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  void logout(context) async {
    await showNotification();
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'pitch_channel',
      'Pitch Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      id: 0,
      title: 'PitchMatch 🎵',
      body: 'Kamu berhasil logout. Sampai jumpa!',
      notificationDetails: details,
    );
  }

  Future<void> requestNotifPermission() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<DocumentSnapshot?> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return await FirebaseFirestore.instance
        .collection('scores')
        .doc(user.uid)
        .get();
  }

  @override
  void initState() {
    super.initState();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    notificationsPlugin.initialize(settings: settings);

    requestNotifPermission();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Information'),
              centerTitle: true,
            ),
            body: FutureBuilder<DocumentSnapshot?>(
              future: getUserData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;

                Timestamp? lastPlayed = data?['lastPlayed'];

                String lastPlayedText = "-";

                if (lastPlayed != null) {
                  final date = lastPlayed.toDate();
                  lastPlayedText =
                  "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Logged in as ${FirebaseAuth.instance.currentUser?.email}'),

                      const SizedBox(height: 16),

                      Text(
                        "Last played: $lastPlayedText",
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'game');
                        },
                        child: const Text("Play Game 🎮"),
                      ),

                      const SizedBox(height: 24),

                      OutlinedButton(
                        onPressed: () => logout(context),
                        child: const Text('Logout'),
                      )
                    ],
                  ),
                );
              },
            ),
            backgroundColor: Colors.grey[100],
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}