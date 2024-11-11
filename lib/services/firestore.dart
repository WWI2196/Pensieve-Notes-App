import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteType {
  final String name;
  final Color color;

  const NoteType(this.name, this.color);

  @override
  String toString() => name;

  static final personal = NoteType('Personal', Colors.blue);
  static final educational = NoteType('Educational', Colors.green);
  static final other = NoteType('Other', Colors.grey);

  static final List<NoteType> defaultTypes = [personal, educational, other];
  static final List<NoteType> customTypes = [];

  static List<NoteType> get allTypes => [...defaultTypes, ...customTypes];

  // Improved fromString factory
  factory NoteType.fromString(String name) {
    try {
      return allTypes.firstWhere(
        (type) => type.name == name,
        orElse: () => other,
      );
    } catch (e) {
      return other;
    }
  }

  // Add color conversion helpers
  static Color colorFromString(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.grey;
    }
  }

  String colorToString() {
    return color.value.toString();
  }
}

class FirestoreService {
  final CollectionReference notes = 
      FirebaseFirestore.instance.collection('notes');
  final CollectionReference noteTypes = 
      FirebaseFirestore.instance.collection('noteTypes');

  // CREATE
  Future<void> addNote({
    required String title,
    required String content,
    required NoteType type,
  }) async {
    await notes.add({
      'title': title,
      'content': content,
      'type': type.toString(),
      'color': type.color.value.toString(),
      'timestamp': Timestamp.now(),
    });
  }

  // READ
  Stream<QuerySnapshot> getNotes() {
    return notes.orderBy('timestamp', descending: true).snapshots();
  }

  // UPDATE
  Future<void> updateNote({
    required String docID,
    required String title,
    required String content,
    required NoteType type,
  }) async {
    await notes.doc(docID).update({
      'title': title,
      'content': content,
      'type': type.toString(),
      'color': type.color.value.toString(),
      'timestamp': Timestamp.now(),
    });
  }

  // DELETE
  Future<void> deleteNote(String docID) async {
    await notes.doc(docID).delete();
  }

  // Add method to save custom type
  Future<void> addCustomNoteType(String name, Color color) async {
    await noteTypes.add({
      'name': name,
      'color': color.value.toString(),
      'timestamp': Timestamp.now(),
    });
  }

  // Get custom types stream
  Stream<QuerySnapshot> getCustomNoteTypes() {
    return noteTypes.orderBy('timestamp').snapshots();
  }
}