import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _newTypeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  NoteType _selectedType = NoteType.personal;
  Color _selectedColor = Colors.blue;
  late StreamSubscription<QuerySnapshot> _typesSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to custom types
    _typesSubscription = _firestoreService.getCustomNoteTypes().listen((snapshot) {
      setState(() {
        NoteType.customTypes.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          NoteType.customTypes.add(
            NoteType(
              data['name'],
              NoteType.colorFromString(data['color']),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _typesSubscription.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _newTypeController.dispose();
    super.dispose();
  }

  void openNoteBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add a new note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Enter note title",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: "Enter note content",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            _buildNoteTypeSelector(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearControllers();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && 
                  _contentController.text.isNotEmpty) {
                _firestoreService.addNote(
                  title: _titleController.text,
                  content: _contentController.text,
                  type: _selectedType,
                );
                _clearControllers();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _titleController.clear();
    _contentController.clear();
    _selectedType = NoteType.personal;
  }

  void _addCustomNoteType() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Note Type"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newTypeController,
                decoration: const InputDecoration(
                  hintText: "Enter type name",
                ),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                onColorChanged: (color) {
                  setDialogState(() {
                    _selectedColor = color;
                  });
                },
                pickerColor: _selectedColor,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (_newTypeController.text.isNotEmpty) {
                // Save to Firestore first
                await _firestoreService.addCustomNoteType(
                  _newTypeController.text,
                  _selectedColor,
                );
                
                setState(() {
                  NoteType.customTypes.add(
                    NoteType(_newTypeController.text, _selectedColor),
                  );
                });
                
                _newTypeController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<NoteType>(
            value: _selectedType,
            items: NoteType.allTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: type.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(type.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (NoteType? value) {
              setState(() {
                _selectedType = value ?? NoteType.personal;
              });
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addCustomNoteType,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Notes"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: NoteType.fromString(data['type']).color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(data['title'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['content'] ?? ''),
                        Chip(
                          backgroundColor: NoteType.fromString(data['type']).color.withOpacity(0.2),
                          label: Text(
                            data['type'],
                            style: TextStyle(
                              color: NoteType.fromString(data['type']).color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showUpdateDialog(
                            doc.id,
                            data['title'],
                            data['content'],
                            NoteType.allTypes.firstWhere(
                              (e) => e.toString() == data['type'],
                              orElse: () => NoteType.personal,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _firestoreService.deleteNote(doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showUpdateDialog(
    String docId,
    String currentTitle,
    String currentContent,
    NoteType currentType,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);
    var selectedType = currentType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit note"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: "Enter note title",
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: "Enter note content",
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<NoteType>(
                      value: selectedType,
                      items: NoteType.allTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: type.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(type.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (NoteType? value) {
                        setDialogState(() {
                          selectedType = value ?? NoteType.personal;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.pop(context);
                      _addCustomNoteType();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && 
                  contentController.text.isNotEmpty) {
                _firestoreService.updateNote(
                  docID: docId,
                  title: titleController.text,
                  content: contentController.text,
                  type: selectedType,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}