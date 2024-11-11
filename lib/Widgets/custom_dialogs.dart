import 'package:crudtutorial/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/firestore.dart';
import 'note_type_selector.dart';

class CustomDialogs {
  static Future<void> showAddNoteDialog({
    required BuildContext context,
    required TextEditingController titleController,
    required TextEditingController contentController,
    required ValueNotifier<NoteType> selectedTypeNotifier,
    required ValueNotifier<List<NoteType>> typesNotifier,
    required GlobalKey<FormState> formKey,
    required Function() addCustomNoteType,
    required Function(String title, String content, NoteType type) onAdd,
    required Function() clearControllers,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add a new note"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(
                controller: titleController,
                hint: "Enter note title",
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              buildTextField(
                controller: contentController,
                hint: "Enter note content",
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<NoteType>(
                valueListenable: selectedTypeNotifier,
                builder: (context, selectedType, _) {
                  return NoteTypeSelector(
                    selectedType: selectedType,
                    onTypeChanged: (value) {
                      selectedTypeNotifier.value = value;
                    },
                    onAddPressed: addCustomNoteType,
                    typesNotifier: typesNotifier,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              clearControllers();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                onAdd(
                  titleController.text,
                  contentController.text,
                  selectedTypeNotifier.value,
                );
                clearControllers();
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  static Future<void> showUpdateNoteDialog({
    required BuildContext context,
    required String docId,
    required String currentTitle,
    required String currentContent,
    required NoteType currentType,
    required ValueNotifier<List<NoteType>> typesNotifier,
    required Function(String, String, String, NoteType) onUpdate,
    required Function() addCustomNoteType,
  }) {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);
    final typeNotifier = ValueNotifier<NoteType>(currentType);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit note"),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildTextField(
                  controller: titleController,
                  hint: "Enter note title",
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                buildTextField(
                  controller: contentController,
                  hint: "Enter note content",
                  maxLines: 5,
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
                      onAddPressed: addCustomNoteType,
                      typesNotifier: typesNotifier,
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
                onUpdate(
                  docId,
                  titleController.text,
                  contentController.text,
                  typeNotifier.value,
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

  static Widget buildTextField({
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

  static String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }
}
