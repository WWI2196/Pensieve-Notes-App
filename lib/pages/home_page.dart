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
  late StreamSubscription<List<NoteType>> _typesSubscription;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<NoteType> _selectedTypeNotifier = ValueNotifier(NoteType.personal);

  @override
  void initState() {
    super.initState();
    _typesSubscription = _firestoreService
        .getCustomNoteTypes()
        .listen((List<NoteType> types) {
      setState(() {
        NoteType.customTypes
          ..clear()
          ..addAll(types);
        // Reset selected type if it was deleted
        if (!NoteType.allTypes.contains(_selectedType)) {
          _selectedType = NoteType.personal;
          _selectedTypeNotifier.value = NoteType.personal;
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
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _titleController,
                hint: "Enter note title",
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _contentController,
                hint: "Enter note content",
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _buildNoteTypeSelector(),
            ],
          ),
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
              if (_formKey.currentState?.validate() ?? false) {
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
              Form(
                child: _buildTextField(
                  controller: _newTypeController,
                  hint: "Enter type name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Type name cannot be empty';
                    }
                    if (NoteType.allTypes.any((type) => 
                        type.name.toLowerCase() == value.toLowerCase())) {
                      return 'Type name already exists';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                onColorChanged: (color) {
                  setDialogState(() => _selectedColor = color);
                },
                pickerColor: _selectedColor,
                enableAlpha: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newTypeController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = _newTypeController.text;
              if (name.isNotEmpty) {
                try {
                  await _firestoreService.addCustomNoteType(name, _selectedColor);
                  _newTypeController.clear();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding note type: $e')),
                  );
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTypeSelector() {
    return ValueListenableBuilder<NoteType>(
      valueListenable: _selectedTypeNotifier,
      builder: (context, selectedType, _) {
        final types = NoteType.allTypes;
        // Ensure selected type exists in items
        final currentType = types.contains(selectedType) ? 
            selectedType : NoteType.personal;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: DropdownButton<NoteType>(
                isExpanded: true,
                value: currentType,
                items: types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        Flexible(
                          child: Text(
                            type.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!NoteType.defaultTypes.contains(type))
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _handleAsyncOperation(() async {
                                await _firestoreService.deleteNoteType(type.id);
                              }),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      _selectedTypeNotifier.value = value;
                    });
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCustomNoteType,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator ?? _validateInput,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
    );
  }

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  Future<void> _handleAsyncOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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