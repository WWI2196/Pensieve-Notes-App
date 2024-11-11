import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/constants.dart';
import 'package:crudtutorial/services/animations.dart';
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
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
  late final AnimationController _animationController = AnimationController(
    duration: AnimationConstants.normalDuration,
    vsync: this,
  );

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.note_add_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text("Create Note"),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Title",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hint: "Enter note title",
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(Icons.title_outlined, 
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Content",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _contentController,
                    hint: "Enter note content",
                    maxLines: 5,
                    prefixIcon: Icon(Icons.text_fields_outlined,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Note Type",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
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
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _clearControllers();
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _firestoreService.addNote(
                  title: _titleController.text,
                  content: _contentController.text,
                  type: _selectedType,
                );
                _clearControllers();
                Navigator.pop(context);
                
                // Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('Note added successfully'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green.shade600,
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: const Text("Create"),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side with type info
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                  Flexible(
                                    child: Text(
                                      type.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: type == _typesNotifier.selectedType ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side with delete button for custom types
                            if (!NoteType.defaultTypes.contains(type))
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    // Prevent dropdown from closing
                                    Future.delayed(Duration.zero, () async {
                                      // Show confirmation dialog
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
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
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
                                        barrierLabel: 'Dismiss',
                                        barrierColor: Colors.black54,
                                      );

                                      if (shouldDelete == true) {
                                        try {
                                          await FirestoreService().deleteNoteType(type.id);
                                          if (context.mounted) {
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
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error deleting note type: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red.shade300,
                                    ),
                                  ),
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
    Widget? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator ?? _validateInput,
      style: Theme.of(context).textTheme.bodyMedium,
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
              
              return SlideTransition(
                position: SharedAnimations.slideIn(_animationController),
                child: FadeTransition(
                  opacity: SharedAnimations.fadeIn(_animationController),
                  child: _buildNoteCard(doc, data, noteType, theme),
                ),
              );
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
        duration: AnimationConstants.quickDuration,
        curve: AnimationConstants.defaultCurve,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        _buildTypeIcon(noteType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: noteType.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: noteType.color.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      noteType.name,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: noteType.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              AnimatedOpacity(
                                duration: AnimationConstants.quickDuration,
                                opacity: 0.6,
                                child: Text(
                                  _formatDate(data['timestamp'] ?? Timestamp.now()),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (data['content']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        data['content'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildNoteActions(doc.id, data, noteType, theme),
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

Widget _buildTypeIcon(NoteType noteType) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: noteType.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: noteType.color.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: noteType.color.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: AnimatedScale(
      duration: AnimationConstants.quickDuration,
      scale: 1.0,
      child: Icon(
        _getNoteTypeIcon(noteType.name),
        color: noteType.color,
        size: 20,
      ),
    ),
  );
}

IconData _getNoteTypeIcon(String typeName) {
  switch (typeName.toLowerCase()) {
    case 'personal':
      return Icons.person_outline;
    case 'educational':
      return Icons.school_outlined;
    default:
      return Icons.note_outlined;
  }
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
  final screenSize = MediaQuery.of(context).size;
  final maxHeight = screenSize.height * 0.8;
  final maxWidth = min(screenSize.width * 0.9, 600.0);
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          minHeight: 200,
          minWidth: 300,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: noteType.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with icon and close button
                    Row(
                      children: [
                        _buildTypeIcon(noteType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Metadata row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: noteType.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getNoteTypeIcon(noteType.name),
                                size: 16,
                                color: noteType.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['type'] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: noteType.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(data['timestamp'] ?? Timestamp.now()),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rest of the dialog content remains the same
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: SelectableText(
                      data['content'] ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
              // Actions container remains the same
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: noteType.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showUpdateDialog(
                          doc.id,
                          data['title'],
                          data['content'],
                          noteType,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
      AnimatedContainer(
        duration: AnimationConstants.quickDuration,
        child: IconButton(
          icon: Icon(Icons.edit_outlined),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showUpdateDialog(docId, data['title'], data['content'], noteType),
        ),
      ),
      const SizedBox(width: 8),
      AnimatedContainer(
        duration: AnimationConstants.quickDuration,
        child: IconButton(
          icon: Icon(Icons.delete_outline),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.error.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _handleAsyncOperation(() => _firestoreService.deleteNote(docId)),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text("Edit Note"),
        ],
      ),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Title",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: titleController,
                hint: "Enter note title",
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(Icons.title_outlined,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                "Content",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: contentController,
                hint: "Enter note content",
                maxLines: 5,
                prefixIcon: Icon(Icons.text_fields_outlined,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 16),
              Text(
                "Note Type",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
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
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
                  
                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Note updated successfully'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade600,
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side with type info
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                              Flexible(
                                child: Text(
                                  type.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: type == selectedType ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right side with delete button for custom types
                        if (!NoteType.defaultTypes.contains(type))
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                // Prevent dropdown from closing
                                Future.delayed(Duration.zero, () async {
                                  // Show confirmation dialog
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
                                            FilledButton(
                                              style: FilledButton.styleFrom(
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
                                    barrierLabel: 'Dismiss',
                                    barrierColor: Colors.black54,
                                  );

                                  if (shouldDelete == true) {
                                    try {
                                      await FirestoreService().deleteNoteType(type.id);
                                      if (context.mounted) {
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
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error deleting note type: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade300,
                                ),
                              ),
                            ),
                          ),
                      ],
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