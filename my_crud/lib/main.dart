import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_crud/models/note_database.dart';
import 'package:my_crud/pages/notes_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init database
  await NoteDatabase.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NoteDatabase(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: NotesPage(),
      ),
    );
  }
}