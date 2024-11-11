import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/services/firestore.dart';
import 'package:crudtutorial/services/types_notifier.dart';
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
  final TypesNotifier _typesNotifier = TypesNotifier();
  late StreamSubscription<List<NoteType>> _typesSubscription;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<NoteType> _selectedTypeNotifier = ValueNotifier(NoteType.personal);

  @override
  void initState() {
    super.initState();
    _typesSubscription = _firestoreService
        .getCustomNoteTypes()
        .listen((types) {
      if (mounted) {
        _typesNotifier.updateTypes(types);
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
    _selectedType = NoteType.personal;
    _selectedTypeNotifier.value = NoteType.personal;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add a new note"),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8, // Set width constraint
          constraints: const BoxConstraints(maxWidth: 400), // Add max width
          child: SingleChildScrollView( // Add scroll support
            child: Form(
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
    builder: (dialogContext) => AlertDialog(
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
                  if (_typesNotifier.types.any((type) => 
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
            Navigator.pop(dialogContext); // Only close the add type dialog
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
                if (dialogContext.mounted) { // Add mounted check before using context
                  Navigator.pop(dialogContext); // Only close the add type dialog
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
    return ListenableBuilder(
      listenable: _typesNotifier,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity, // Force full width
          child: IntrinsicHeight( // Use IntrinsicHeight
            child: Row(
              mainAxisSize: MainAxisSize.min, // Important
              children: [
                Flexible( // Use Flexible instead of Expanded
                  child: DropdownButtonFormField<NoteType>( // Use FormField version
                    value: _typesNotifier.selectedType,
                    isExpanded: true,
                    items: _typesNotifier.types.map((type) {
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
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _typesNotifier.setSelectedType(value);
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCustomNoteType,
                ),
              ],
            ),
          ),
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

  void onTypeChanged(NoteType type) {
    setState(() {
      _selectedType = type;
      _selectedTypeNotifier.value = type;
    });
  }

  Future<void> deleteNoteType(String typeId) async {
    try {
      await _firestoreService.deleteNoteType(typeId);
      _typesNotifier.removeType(typeId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note type: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 90, // Adjust size as needed
              width: 90,  // Adjust size as needed
            ),
            const SizedBox(width: 1), // Space between icon and text
            // const Text("Pensieve"),  // Optional: keep or remove text
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final noteType = NoteType.fromString(
                data['type'],
                typeId: data['typeId'],
                colorValue: data['color'],
              );
              
              return _buildNoteCard(doc, data, noteType, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a note',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
  QueryDocumentSnapshot doc, 
  Map<String, dynamic> data,
  NoteType noteType,
  ThemeData theme,
) {
  return Hero(
    tag: 'note-${doc.id}',
    child: Material(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shadowColor: theme.colorScheme.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: noteType.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showNoteDetailDialog(doc, data, noteType),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    noteType.color.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: noteType.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: noteType.color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildNoteActions(doc.id, data, noteType, theme),
                      ],
                    ),
                    if (data['content']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        data['content'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: noteType.color.withOpacity(0.1),
                          label: Text(
                            data['type'],
                            style: TextStyle(
                              color: noteType.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        Text(
                          _formatDate(data['timestamp'] ?? Timestamp.now()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _formatDate(Timestamp timestamp) {
  final date = timestamp.toDate();
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}

  void _showNoteDetailDialog(
  QueryDocumentSnapshot doc,
  Map<String, dynamic> data,
  NoteType noteType,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: ConstrainedBox(  // Add this wrapper
        constraints: const BoxConstraints(maxWidth: 300), // Adjust width as needed
        child: Row(
          mainAxisSize: MainAxisSize.min, // Add this
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: noteType.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible( // Change Expanded to Flexible
              child: Text(
                data['title'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox( // Add constraints
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['content'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap( // Use Wrap instead of Row for chips
                spacing: 8,
                children: [
                  Chip(
                    label: Text(data['type']),
                    backgroundColor: noteType.color.withOpacity(0.1),
                    labelStyle: TextStyle(color: noteType.color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _showUpdateDialog(
              doc.id,
              data['title'],
              data['content'],
              noteType,
            );
          },
          child: const Text('Edit'),
        ),
      ],
    ),
  );
}

  Widget _buildNoteActions(
  String docId,
  Map<String, dynamic> data,
  NoteType noteType,
  ThemeData theme,
) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
        tooltip: 'Edit',
        onPressed: () => _showUpdateDialog(
          docId,
          data['title'],
          data['content'],
          noteType,
        ),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        tooltip: 'Delete',
        onPressed: () => _handleAsyncOperation(
          () => _firestoreService.deleteNote(docId),
        ),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.error.withOpacity(0.1),
        ),
      ),
    ],
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
      content: SingleChildScrollView(
        child: StatefulBuilder(
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
                maxLines: 5, // Increased max lines
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
              final currentContext = context;
              _handleAsyncOperation(() async {
                await _firestoreService.updateNote(
                  docID: docId,
                  title: titleController.text,
                  content: contentController.text,
                  type: typeNotifier.value,
                );
                if (currentContext.mounted) {
                  Navigator.pop(currentContext);
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
  final TypesNotifier typesNotifier;  // Change type here

  const NoteTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onAddPressed,
    required this.typesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: typesNotifier,
      builder: (context, _) {
        final uniqueTypes = typesNotifier.types.toSet().toList();

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
                                    barrierLabel: 'Dismiss', // Add this line
                                    barrierColor: Colors.black54, // Optional: customize barrier color
                                  );

                                  if (shouldDelete == true && context.mounted) {
                                    try {
                                      // Show loading overlay
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (loadingContext) => PopScope(
                                          canPop: false,
                                          child: Center(
                                            child: Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Deleting ${type.name}...',
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      await FirestoreService().deleteNoteType(type.id);
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context); // Only close the loading overlay
                                        
                                        // Update state without closing the update dialog
                                        NoteType.customTypes.removeWhere((t) => t.id == type.id);
                                        final updatedTypes = [...NoteType.allTypes];
                                        typesNotifier.updateTypes(updatedTypes);
                                        
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
                                            backgroundColor: Colors.green.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            action: SnackBarAction(
                                              label: 'UNDO',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                // Implement undo functionality if needed
                                              },
                                            ),
                                          ),
                                        );
                                        
                                        // Trigger rebuild with animation
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          typesNotifier.notifyListeners();
                                        });
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Only close the loading overlay
                                        // Show error snackbar without closing dialog
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Failed to delete: $e',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.red.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            duration: const Duration(seconds: 4),
                                            action: SnackBarAction(
                                              label: 'RETRY',
                                              textColor: Colors.white,
                                              onPressed: () async {
                                                // Implement retry functionality
                                                await FirestoreService().deleteNoteType(type.id);
                                              },
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