import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:my_mini_project/screens/leaderboard.dart';

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

      listenToAudio(); // 🔥 penting

      setState(() {
        isRecording = true;
      });
    }
  }

  // ⏹ Stop recording
  Future<void> stopRecording() async {
    await recorder.stop();
    await audioSubscription?.cancel();

    setState(() {
      isRecording = false;
    });

    if (detectedPitch != null && score != null) {
      await saveScoreToFirestore();
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

  Future<void> saveScoreToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || detectedPitch == null || score == null) return;

    await FirebaseFirestore.instance.collection('scores').add({
      'userId': user.uid,
      'email': user.email,
      'targetPitch': targetPitch,
      'userPitch': detectedPitch,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
    });
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