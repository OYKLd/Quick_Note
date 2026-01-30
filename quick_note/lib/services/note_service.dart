import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NoteService {
  static const String _notesKey = 'saved_notes';
  
  // Sauvegarder les notes
  static Future<void> saveNotes(List<Map<String, String>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = jsonEncode(notes);
    await prefs.setString(_notesKey, notesJson);
  }

  // Charger les notes sauvegardées
  static Future<List<Map<String, String>>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(_notesKey);
    
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      return decoded.cast<Map<String, String>>();
    }
    
    return [];
  }
}