import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:my_mini_project/screens/leaderboard.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final player = AudioPlayer();
  final recorder = AudioRecorder();
  late Stream<List<int>> audioStream;
  
  final pitchDetector = PitchDetector();
  double? detectedPitch;

  bool isRecording = false;

  double targetPitch = 440; // A4
  double? score;
  String feedback = "";

  bool alreadySaved = false;

  StreamSubscription? audioSubscription;

  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    requestNotifPermission();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    notificationsPlugin.initialize(
      settings: settings,
    );
  }

  Future<void> requestNotifPermission() async {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 🎵 Play tone
  void playTone() async {
    await player.play(AssetSource('audio/tone_440.wav'));
  }

  // 🎤 Start recording
  Future<void> startRecording() async {
    if (await recorder.hasPermission()) {

      alreadySaved = false;
      detectedPitch = null;
      score = null;
      feedback = "";

      audioStream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      listenToAudio();

      setState(() {
        isRecording = true;
      });
    }
  }

  // ⏹ Stop recording
  Future<void> stopRecording() async {
    await recorder.stop();
    await audioSubscription?.cancel();
    await showNotification();

    setState(() {
      isRecording = false;
    });

    if (detectedPitch != null && score != null) {
      await saveOrUpdateScore();
    }
  }

  void listenToAudio() {
    audioSubscription = audioStream.listen((data) async {
      List<double> samples = [];

      for (int i = 0; i < data.length - 1; i += 2) {
        int sample = data[i] | (data[i + 1] << 8);
        if (sample > 32767) sample -= 65536;
        samples.add(sample.toDouble());
      }

      if (samples.length > 1024) {
        final result =
        await pitchDetector.getPitchFromFloatBuffer(samples);

        if (result.pitched) {
          setState(() {
            detectedPitch = detectedPitch == null
                ? result.pitch
                : (detectedPitch! * 0.7 + result.pitch * 0.3);

            score = calculateScore(detectedPitch!);
            feedback = getFeedback(detectedPitch!);
          });
        }
      }
    });
  }

  double calculateScore(double userPitch) {
    double diff = (targetPitch - userPitch).abs();
    double result = (100 - (diff / targetPitch * 100)).clamp(0, 100);
    return result;
  }

  String getFeedback(double userPitch) {
    double diff = userPitch - targetPitch;

    if (diff.abs() < 5) {
      return "Perfect! 🎯";
    } else if (diff > 0) {
      return "Too High ⬆️";
    } else {
      return "Too Low ⬇️";
    }
  }

  Future<void> saveOrUpdateScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || score == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('scores')
        .doc(user.uid);

    final doc = await docRef.get();

    if (doc.exists) {
      final oldScore = doc.data()!['score'];

      if (score! > oldScore) {
        await docRef.update({
          'score': score,
          'userPitch': detectedPitch,
          'lastPlayed': FieldValue.serverTimestamp(),
        });

        print("UPDATED (new high score)");
      } else {
        await docRef.update({
          'lastPlayed': FieldValue.serverTimestamp(),
        });

        print("No update (score lower)");
      }
    } else {
      await docRef.set({
        'userId': user.uid,
        'email': user.email,
        'score': score,
        'targetPitch': targetPitch,
        'userPitch': detectedPitch,
        'lastPlayed': FieldValue.serverTimestamp(),
      });

      print("CREATED new score");
    }
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
      body: 'Kamu sudah latihan hari ini 🎯',
      notificationDetails: details,
    );
  }

  @override
  void dispose() {
    recorder.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PitchMatch")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: playTone,
              child: const Text("Play Note 🎵"),
            ),

            const SizedBox(height: 20),

            // 🎤 RECORD BUTTON
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? "Stop Recording ⏹" : "Record 🎤"),
            ),

            const SizedBox(height: 20),

            // if (detectedPitch != null)
            //   Text(
            //     "Your Pitch: ${detectedPitch!.toStringAsFixed(2)} Hz",
            //     style: const TextStyle(fontSize: 18),
            //   ),

            if (detectedPitch != null) ...[
              Text(
                "Target: ${targetPitch.toStringAsFixed(0)} Hz",
                style: const TextStyle(fontSize: 18),
              ),

              Text(
                "Your Pitch: ${detectedPitch!.toStringAsFixed(2)} Hz",
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 10),

              Text(
                "Score: ${score?.toStringAsFixed(0) ?? 0}%",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                feedback,
                style: TextStyle(
                  fontSize: 20,
                  color: feedback.contains("Perfect")
                      ? Colors.green
                      : Colors.orange,
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
                child: const Text("Leaderboard 🏆"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}