class Pregunta {
  final int id;
  final String text;
  final List<dynamic> options;
  final int correctOption;
  final String subject;
  final int grade;

  static const Map<String, String> subjectEmojis = {
    'math': '🔢', 'memory': '🧠', 'logic': '🧩', 'grammar': '✍️',
    'english': '🗣️', 'geography': '🌎', 'art': '🎨', 'science': '🔬'
  };

  Pregunta({
    required this.id, required this.text, required this.options,
    required this.correctOption, required this.subject, required this.grade,
  });

  factory Pregunta.fromDatabase(Map<String, dynamic> dbData) {
    return Pregunta(
      id: dbData['id'],
      text: dbData['text'],
      options: dbData['options'],
      correctOption: dbData['correct_option'],
      subject: dbData['subject'],
      grade: dbData['grade'],
    );
  }
}