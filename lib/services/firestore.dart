import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteType {
  final String name;
  final Color color;
  final String id;

  const NoteType(this.name, this.color, {required this.id});

  // Add static map to track deleted types
  static final Map<String, NoteType> deletedTypes = {};

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

  static List<NoteType> get allTypes {
    final types = [...defaultTypes, ...customTypes];
    return types.toSet().toList(); // Ensure unique items
  }

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

  // Updated fromString method
  static NoteType fromString(String typeName, {String? typeId, String? colorValue}) {
    return allTypes.firstWhere(
      (type) => type.name == typeName,
      orElse: () {
        if (typeId != null && deletedTypes.containsKey(typeId)) {
          return deletedTypes[typeId]!;
        }
        if (colorValue != null) {
          return NoteType(
            typeName,
            Color(int.parse(colorValue)),
            id: typeId ?? 'deleted_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
        return other;
      },
    );
  }

  // Add delete method
  Future<void> delete(FirebaseFirestore db) async {
    if (id.isNotEmpty) {
      await db.collection('noteTypes').doc(id).delete();
    }
  }

  // Add stream controller for type changes
  static final _typeController = StreamController<List<NoteType>>.broadcast();
  static Stream<List<NoteType>> get typeStream => _typeController.stream;

  static void updateTypes(List<NoteType> types) {
    customTypes.clear();
    customTypes.addAll(types);
    _typeController.add(allTypes);
  }

  // Add dispose method
  static void dispose() {
    _typeController.close();
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

  // Added synchronous type fetch method
  Future<List<NoteType>> getCustomNoteTypesSync() async {
    final snapshot = await _db.collection('noteTypes').get();
    return snapshot.docs.map((doc) => NoteType.fromMap(doc.data(), doc.id)).toList();
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
      'typeId': type.id,
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

  // Updated delete note type method
  Future<void> deleteNoteType(String typeId) async {
    final typeDoc = await _db.collection('noteTypes').doc(typeId).get();
    if (typeDoc.exists) {
      final typeData = typeDoc.data()!;
      final deletedType = NoteType.fromMap(typeData, typeId);
      
      // Store deleted type
      NoteType.deletedTypes[typeId] = deletedType;
      
      // Update local state first
      NoteType.customTypes.removeWhere((type) => type.id == typeId);
      NoteType.updateTypes([...NoteType.customTypes]); // Trigger stream update
      
      // Delete from Firestore
      await _db.collection('noteTypes').doc(typeId).delete();
    }
  }
}