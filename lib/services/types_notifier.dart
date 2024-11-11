// types_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:pensieve/services/firestore.dart';

class TypesNotifier extends ChangeNotifier {
  List<NoteType> _types = [...NoteType.defaultTypes];
  NoteType _selectedType = NoteType.personal;

  // Getter for types list
  List<NoteType> get types => _types;
  
  // Getter for selected type
  NoteType get selectedType => _selectedType;

  void updateTypes(List<NoteType> newTypes) {
    _types = [...NoteType.defaultTypes, ...newTypes];
    notifyListeners();
  }

  void setSelectedType(NoteType type) {
    _selectedType = type;
    notifyListeners();
  }

  void removeType(String typeId) {
    _types.removeWhere((type) => type.id == typeId);
    if (_selectedType.id == typeId) {
      _selectedType = NoteType.personal;
    }
    notifyListeners();
  }
}