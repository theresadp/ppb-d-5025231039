import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int counter = 4;

  void incrementCounter() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My First App"),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFD6D2D8),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE SECTION
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[200],
              child: Image.network(
                "https://picsum.photos/300", // placeholder image
              ),
            ),

            const SizedBox(height: 16),

            // QUESTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.pink[300],
              child: const Text(
                "What image is that",
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // OPTIONS
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  OptionItem(icon: Icons.fastfood, label: "Food"),
                  OptionItem(icon: Icons.landscape, label: "Scenery"),
                  OptionItem(icon: Icons.people, label: "People"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // COUNTER SECTION
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Counter here: $counter",
                    style: const TextStyle(fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: incrementCounter,
                    child: const Icon(Icons.add),
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

// REUSABLE OPTION WIDGET
class OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const OptionItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}