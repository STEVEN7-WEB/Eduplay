import 'dart:convert';

class Pregunta {
  final int id;
  final String text;
  final List<String> options;
  final int correctOption;
  final String subject;
  final int grade;
  final String emoji; // Nuevo campo para el emoji visual

  Pregunta({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOption,
    required this.subject,
    required this.grade,
    required this.emoji,
  });

  // Mapa de emojis según la materia (igual que en la web)
  static final Map<String, String> subjectEmojis = {
    'math': '🔢',
    'memory': '🧠',
    'logic': '🧩',
    'grammar': '✍️',
    'english': '🗣️',
    'geography': '🌎',
    'art': '🎨',
    'science': '🔬',
  };

  factory Pregunta.fromDatabase(Map<String, dynamic> row) {
    // Manejamos las opciones si vienen como texto (A,B,C,D) o como lista JSON
    List<String> rawOptions = [];
    if (row['options'] is String) {
      try {
        rawOptions = List<String>.from(jsonDecode(row['options']));
      } catch (e) {
        rawOptions = row['options'].toString().split(',').map((e) => e.trim()).toList();
      }
    } else {
      rawOptions = List<String>.from(row['options']);
    }

    final sub = row['subject'].toString().toLowerCase();

    return Pregunta(
      id: row['id'],
      text: row['text'],
      options: rawOptions,
      correctOption: row['correct_option'],
      subject: sub,
      grade: row['grade'],
      // Asignamos el emoji o uno por defecto si no existe
      emoji: subjectEmojis[sub] ?? '🎮', 
    );
  }
}