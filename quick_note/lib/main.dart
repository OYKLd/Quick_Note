import 'package:flutter/material.dart';
import 'screens/note_edit_screen.dart';
import 'services/note_service.dart';

void main() {
  runApp(const QuickNoteApp());
}

class QuickNoteApp extends StatelessWidget {
  const QuickNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const NotesListScreen(),
    );
  }
}

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Map<String, String>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Charger les notes au démarrage
  Future<void> _loadNotes() async {
    final notes = await NoteService.loadNotes();
    setState(() {
      _notes = notes;
    });
  }

  // Sauvegarder les notes
  Future<void> _saveNotes() async {
    await NoteService.saveNotes(_notes);
  }

  // Ajouter une nouvelle note
  void _addNewNote() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => const NoteEditScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _notes.insert(0, {
          'title': result['title'] ?? 'Sans titre',
          'content': result['content'] ?? '',
          'date': DateTime.now().toIso8601String(),
        });
      });
      await _saveNotes();
    }
  }

  // Modifier une note existante
  void _editNote(int index) async {
    final note = _notes[index];
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          initialTitle: note['title'],
          initialContent: note['content'],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _notes[index] = {
          'title': result['title'] ?? 'Sans titre',
          'content': result['content'] ?? '',
          'date': DateTime.now().toIso8601String(),
        };
      });
      await _saveNotes();
    }
  }

  // Supprimer une note
  Future<void> _deleteNote(int index) async {
    setState(() {
      _notes.removeAt(index);
    });
    await _saveNotes();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text(
                'Aucune note pour le moment\nAppuyez sur + pour en créer une',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Dismissible(
                  key: Key(note['date'] ?? index.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteNote(index),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        note['title'] ?? 'Sans titre',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(note['date']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _editNote(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}