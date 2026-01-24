import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/database_helper.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({
    super.key,
    this.note,
  });

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _databaseHelper = DatabaseHelper();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.note == null) {
        // Créer une nouvelle note
        final note = Note(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
        await _databaseHelper.insertNote(note);
      } else {
        // Mettre à jour une note existante
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
        await _databaseHelper.updateNote(updatedNote);
      }

      if (mounted) {
        Navigator.pop(context, true); // Retour à l'écran précédent avec succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Une erreur est survenue lors de la sauvegarde')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_titleController.text.trim().isNotEmpty ||
            _contentController.text.trim().isNotEmpty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Annuler les modifications ?'),
              content: const Text(
                  'Voulez-vous vraiment quitter sans enregistrer les modifications ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ANNULER'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('QUITTER'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Modifier la note' : 'Nouvelle note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveNote,
            ),
          ],
        ),
        body: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Titre',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 8),
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Modifié le ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.note!.updatedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Commencez à écrire...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        style: const TextStyle(fontSize: 18),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
