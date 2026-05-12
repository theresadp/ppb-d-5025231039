import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Sentiment Analyzer',
      home: const SentimentPage(),
    );
  }
}

class SentimentPage extends StatefulWidget {
  const SentimentPage({super.key});

  @override
  State<SentimentPage> createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage> {
  final TextEditingController _controller = TextEditingController();

  String result = "";
  bool isLoading = false;

  Future<void> analyzeSentiment() async {
    setState(() {
      isLoading = true;
    });

    try {
      const apiKey = "";

      final response = await http.post(
        Uri.parse(
          "https://router.huggingface.co/hf-inference/models/distilbert/distilbert-base-uncased-finetuned-sst-2-english",
        ),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "inputs": _controller.text,
        }),
      );

      final data = jsonDecode(response.body);

      print(data);

      String label = data[0][0]["label"];
      double score = data[0][0]["score"];

      setState(() {
        if (score < 0.99) {
          result = "NEUTRAL";
        } else {
          result = label;
        }
      });
    } catch (e) {
      setState(() {
        result = "ERROR";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  String getReadableResult() {
    final lower = result.toLowerCase();

    if (lower.contains("positive")) {
      return "Positive";
    }

    if (lower.contains("negative")) {
      return "Negative";
    }

    return "Neutral";
  }

  String getEmoji() {
    final lower = result.toLowerCase();

    if (lower.contains("positive")) {
      return "😊";
    }

    if (lower.contains("negative")) {
      return "😔";
    }

    return "😐";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "AI Sentiment Analyzer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // DESCRIPTION
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Text(
                "This application uses Artificial Intelligence (AI) to analyze the sentiment of your sentence and determine whether it is positive, negative, or neutral.",
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 25),

            // TEXT FIELD
            TextField(
              controller: _controller,
              maxLines: 4,

              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,

                hintText: "Enter your sentence here...",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                    width: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // BUTTON
            ElevatedButton(
              onPressed: analyzeSentiment,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: const Text(
                "Analyze Sentiment",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // LOADING
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              ),

            // RESULT
            if (!isLoading && result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Text(
                      getEmoji(),
                      style: const TextStyle(fontSize: 60),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Your sentence is",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      getReadableResult(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}