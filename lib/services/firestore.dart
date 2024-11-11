import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteType {
  final String name;
  final Color color;
  final String id;

  const NoteType(this.name, this.color, {required this.id});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          id == id;

  @override
  int get hashCode => Object.hash(name, id);

  static final personal = NoteType('Personal', Colors.blue, id: 'personal');
  static final educational = NoteType('Educational', Colors.green, id: 'educational');
  static final other = NoteType('Other', Colors.grey, id: 'other');

  static final List<NoteType> defaultTypes = [personal, educational, other];
  static final List<NoteType> customTypes = [];

  static List<NoteType> get allTypes => [...defaultTypes, ...customTypes];

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color.value.toString(),
        'id': id,
      };

  static NoteType fromMap(Map<String, dynamic> map, String docId) {
    return NoteType(
      map['name'] as String,
      Color(int.parse(map['color'] as String)),
      id: docId,
    );
  }

  static NoteType fromString(String typeName) {
    return allTypes.firstWhere(
      (type) => type.name == typeName,
      orElse: () => other,
    );
  }

  // Add delete method
  Future<void> delete(FirebaseFirestore db) async {
    if (id.isNotEmpty) {
      await db.collection('noteTypes').doc(id).delete();
    }
  }
}

// Update FirestoreService class
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Add custom type
  Future<void> addCustomNoteType(String name, Color color) async {
    final docRef = _db.collection('noteTypes').doc();
    final type = NoteType(name, color, id: docRef.id);
    await docRef.set(type.toMap());
  }

  // Get custom types
  Stream<List<NoteType>> getCustomNoteTypes() {
    return _db.collection('noteTypes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteType.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add note with validation
  Future<void> addNote({
    required String title,
    required String content,
    required NoteType type,
  }) async {
    if (title.isEmpty || content.isEmpty) {
      throw ArgumentError('Title and content cannot be empty');
    }

    await _db.collection('notes').add({
      'title': title,
      'content': content,
      'type': type.name,
      'typeId': type.id,
      'color': type.color.value.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Update note with validation
  Future<void> updateNote({
    required String docID,
    required String title,
    required String content,
    required NoteType type,
  }) async {
    if (title.isEmpty || content.isEmpty) {
      throw ArgumentError('Title and content cannot be empty');
    }

    await _db.collection('notes').doc(docID).update({
      'title': title,
      'content': content,
      'type': type.name,
      'color': type.color.value.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // READ
  Stream<QuerySnapshot> getNotes() {
    return _db.collection('notes').orderBy('timestamp', descending: true).snapshots();
  }

  // DELETE
  Future<void> deleteNote(String docID) async {
    await _db.collection('notes').doc(docID).delete();
  }

  // Add delete note type method
  Future<void> deleteNoteType(String typeId) async {
    await _db.collection('noteTypes').doc(typeId).delete();
  }
}