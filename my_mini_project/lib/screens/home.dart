import 'package:my_mini_project/screens/login.dart';
import 'package:my_mini_project/screens/game.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Logged in as ${snapshot.data?.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GameScreen()),
                      );
                    },
                    child: const Text("Play Game 🎮"),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () => logout(context),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
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