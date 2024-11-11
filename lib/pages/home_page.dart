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
  final ValueNotifier<List<NoteType>> _typesNotifier = 
      ValueNotifier<List<NoteType>>([...NoteType.defaultTypes]);

  @override
  void initState() {
    super.initState();
    _typesSubscription = _firestoreService
        .getCustomNoteTypes()
        .listen((types) {
      if (mounted) {
        NoteType.customTypes.clear();
        NoteType.customTypes.addAll(types);
        _typesNotifier.value = [...NoteType.allTypes];
        
        if (!NoteType.allTypes.contains(_selectedType)) {
          _selectedType = NoteType.personal;
          _selectedTypeNotifier.value = NoteType.personal;
        }
      }
    });
  }

  @override
  void dispose() {
    _typesSubscription.cancel();
    _typesNotifier.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _newTypeController.dispose();
    super.dispose();
  }

  void openNoteBox() {
    _selectedType = NoteType.personal; // Add this line
    _selectedTypeNotifier.value = NoteType.personal; // Add this line
    
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
    _selectedTypeNotifier.value = NoteType.personal; // Add this line
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
                  if (_typesNotifier.value.any((type) => 
                      type.name.toLowerCase() == value.toLowerCase())) {
                    return 'Type name already exists';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            ColorPicker(
              onColorChanged: (color) => setDialogState(() => _selectedColor = color),
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
          onPressed: () {
            if (_newTypeController.text.isNotEmpty) {
              _handleAsyncOperation(() async {
                await _firestoreService.addCustomNoteType(
                  _newTypeController.text,
                  _selectedColor,
                );
                _newTypeController.clear();
                if (mounted) { // Add mounted check before using context
                  Navigator.pop(context);
                }
              });
            }
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}

  Widget _buildNoteTypeSelector() {
  return ValueListenableBuilder<List<NoteType>>(
    valueListenable: _typesNotifier,
    builder: (context, types, _) {
      return ValueListenableBuilder<NoteType>(
        valueListenable: _selectedTypeNotifier,
        builder: (context, selectedType, _) {
          final uniqueTypes = types.toSet().toList();

          if (!uniqueTypes.contains(selectedType)) {
            _selectedType = NoteType.personal;
            _selectedTypeNotifier.value = NoteType.personal;
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: DropdownButton<NoteType>(
                  isExpanded: true,
                  value: selectedType,
                  items: uniqueTypes.map((type) {
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
                          Expanded(
                            child: Text(
                              type.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!NoteType.defaultTypes.contains(type))
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () async {
                                // Show confirmation dialog
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Note Type'),
                                    content: Text('Are you sure you want to delete "${type.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true && context.mounted) {
                                  await FirestoreService().deleteNoteType(type.id);
                                  // Force update the notifier
                                  _typesNotifier.value = [...NoteType.allTypes];
                                  if (selectedType == type) {
                                    _selectedType = NoteType.personal;
                                    _selectedTypeNotifier.value = NoteType.personal;
                                  }
                                }
                              },
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
                
                // Use enhanced fromString method with typeId and color
                final noteType = NoteType.fromString(
                  data['type'],
                  typeId: data['typeId'],
                  colorValue: data['color'],
                );
                
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: noteType.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(data['title'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['content'] ?? ''),
                        Chip(
                          backgroundColor: noteType.color.withOpacity(0.2),
                          label: Text(
                            data['type'],
                            style: TextStyle(
                              color: noteType.color,
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
                            noteType, // Pass the noteType instead of searching again
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _handleAsyncOperation(() => 
                            _firestoreService.deleteNote(doc.id)
                          ),
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
  final typeNotifier = ValueNotifier<NoteType>(currentType);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Edit note"),
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: titleController,
              hint: "Enter note title",
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: contentController,
              hint: "Enter note content",
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<NoteType>(
              valueListenable: typeNotifier,
              builder: (context, selectedType, _) {
                return NoteTypeSelector(
                  selectedType: selectedType,
                  onTypeChanged: (value) {
                    setDialogState(() {
                      typeNotifier.value = value;
                    });
                  },
                  onAddPressed: () {
                    Navigator.pop(context);
                    _addCustomNoteType();
                  },
                  typesNotifier: _typesNotifier,
                );
              },
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
              _handleAsyncOperation(() async {
                await _firestoreService.updateNote(
                  docID: docId,
                  title: titleController.text,
                  content: contentController.text,
                  type: typeNotifier.value,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            }
          },
          child: const Text("Update"),
        ),
      ],
    ),
  );
}
}

// First, create a reusable note type selector widget
class NoteTypeSelector extends StatelessWidget {
  final NoteType selectedType;
  final ValueChanged<NoteType> onTypeChanged;
  final VoidCallback onAddPressed;
  final ValueNotifier<List<NoteType>> typesNotifier;

  const NoteTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onAddPressed,
    required this.typesNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NoteType>>(
      valueListenable: typesNotifier,
      builder: (context, types, _) {
        final uniqueTypes = types.toSet().toList();

        return Row(
          children: [
            Expanded(
              child: DropdownButton<NoteType>(
                isExpanded: true,
                value: uniqueTypes.contains(selectedType) ? selectedType : NoteType.personal,
                isDense: true, // Make dropdown more compact
                underline: Container(
                  height: 2,
                  color: Colors.blue.shade300,
                ),
                items: uniqueTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: type.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: type.color.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: type == selectedType ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!NoteType.defaultTypes.contains(type))
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.delete, size: 20, color: Colors.red),
                                ),
                                onTap: () async {
                                  // Show confirmation dialog with custom animation
                                  final shouldDelete = await showGeneralDialog<bool>(
                                    context: context,
                                    pageBuilder: (context, animation, secondaryAnimation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: AlertDialog(
                                          title: Row(
                                            children: [
                                              const Icon(Icons.warning, color: Colors.amber),
                                              const SizedBox(width: 8),
                                              const Text('Delete Note Type'),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Are you sure you want to delete "${type.name}"?'),
                                              const SizedBox(height: 8),
                                              Text(
                                                'This action cannot be undone.',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 200),
                                    barrierDismissible: true,
                                  );

                                  if (shouldDelete == true && context.mounted) {
                                    try {
                                      // Show loading overlay
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => WillPopScope(
                                          onWillPop: () async => false,
                                          child: Center(
                                            child: Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(),
                                                    const SizedBox(height: 16),
                                                    Text('Deleting ${type.name}...'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      await FirestoreService().deleteNoteType(type.id);
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context); // Remove loading overlay
                                        
                                        // Force immediate UI update
                                        NoteType.customTypes.removeWhere((t) => t.id == type.id);
                                        final updatedTypes = [...NoteType.allTypes];
                                        
                                        // Update both notifiers
                                        typesNotifier.value = updatedTypes;
                                        
                                        if (selectedType == type) {
                                          onTypeChanged(NoteType.personal);
                                        }

                                        // Show success feedback
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text('Note type "${type.name}" deleted'),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        );

                                        // Force rebuild with animation
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          typesNotifier.notifyListeners();
                                        });
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Remove loading overlay
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text('Failed to delete: $e')),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onTypeChanged(value);
                  }
                },
                dropdownColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAddPressed,
            ),
          ],
        );
      },
    );
  }
}