import 'package:supabase_flutter/supabase_flutter.dart';

class QuizAnswerEntry {
  final String questionText;
  final List<String> options;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String? explanation;

  QuizAnswerEntry({
    required this.questionText,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'question_text': questionText,
        'options': options,
        'selected_index': selectedIndex,
        'correct_index': correctIndex,
        'is_correct': isCorrect,
        if (explanation != null) 'explanation': explanation,
      };

  factory QuizAnswerEntry.fromJson(Map<String, dynamic> j) => QuizAnswerEntry(
        questionText: j['question_text'] as String,
        options: List<String>.from(j['options'] as List),
        selectedIndex: j['selected_index'] as int,
        correctIndex: j['correct_index'] as int,
        isCorrect: j['is_correct'] as bool,
        explanation: j['explanation'] as String?,
      );
}

class QuizHistoryEntry {
  final String id;
  final String chapterTitle;
  final int score;
  final int total;
  final DateTime date;
  final List<QuizAnswerEntry> answers;

  QuizHistoryEntry({
    this.id = '',
    required this.chapterTitle,
    required this.score,
    required this.total,
    required this.date,
    this.answers = const [],
  });

  factory QuizHistoryEntry.fromJson(Map<String, dynamic> j) {
    final rawAnswers = j['answers'] as List? ?? [];
    return QuizHistoryEntry(
      id: j['id'] as String? ?? '',
      chapterTitle: j['chapter_title'] as String,
      score: j['score'] as int,
      total: j['total'] as int,
      date: DateTime.parse(j['created_at'] as String),
      answers: rawAnswers
          .map((a) => QuizAnswerEntry.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizHistoryService {
  static final _db = Supabase.instance.client;

  static Future<List<QuizHistoryEntry>> load() async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await _db
          .from('quiz_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      final list = (res as List)
          .map((e) => QuizHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      await _db.from('quiz_history').delete().eq('user_id', userId);
    } catch (_) {}
  }

  static Future<void> save(
      QuizHistoryEntry entry, List<QuizAnswerEntry> answers) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      await _db.from('quiz_history').insert({
        'user_id': userId,
        'chapter_title': entry.chapterTitle,
        'score': entry.score,
        'total': entry.total,
        'answers': answers.map((a) => a.toJson()).toList(),
      });
    } catch (_) {}
  }
}
