import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService{

  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');

  //create new note
  Future<void> addNote(String title, String content, String label) {
    return notes.add({
      'title': title,
      'content': content,
      'label': label,
      'createdAt': Timestamp.now(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  //fetch all notes
  Stream<QuerySnapshot> getNotesByUser(String userId) {
  return notes
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Future<DocumentSnapshot> getUserById(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  }

  //update notes
  Future<void> updateNote(String id, String title, String content, String label) {
    return notes.doc(id).update({
      'title': title,
      'content': content,
      'label': label,
      'updatedAt': Timestamp.now(),
    });
  }

  //delete notes
  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }

}