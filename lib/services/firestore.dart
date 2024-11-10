import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // get collection reference
  final CollectionReference notes = 
      FirebaseFirestore.instance.collection('notes');

  // CREATE : add a new note
  Future<void> addNote(String note) async {
    await notes.add({
      'note': note,
      'timestamp': Timestamp.now(),
    });
  }

  // READ : get notes from database
  Stream<QuerySnapshot> getNotes() {
    final notesStream = 
        notes.orderBy('timestamp', descending: true).snapshots();
    return notesStream;
  }

  // UPDATE : update an existing note given a doc id
  Future<void> updateNote(String docID, String newNote) async {
    await notes.doc(docID).update({
      'note': newNote,
      'timestamp': Timestamp.now(),
    });
  }

  // DELETE : delete an existing note given a doc id
  Future<void> deleteNote(String docID) async {
    await notes.doc(docID).delete();
  }
}