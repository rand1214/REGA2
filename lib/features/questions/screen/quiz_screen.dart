import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_supabase_app/core/services/quiz_history_service.dart';
import '../../home/models/chapter_model.dart';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex; // 0=a, 1=b, 2=c, 3=d
  final String? explanation;
  final int? pageNumber;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.pageNumber,
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    final opts = <String>[
      j['option_a'] as String,
      j['option_b'] as String,
      j['option_c'] as String,
      if (j['option_d'] != null) j['option_d'] as String,
    ];
    const letterMap = {'a': 0, 'b': 1, 'c': 2, 'd': 3};
    final correct = letterMap[j['correct_option'] as String] ?? 0;
    return Question(
      id: j['id'] as String,
      text: j['text'] as String,
      options: opts,
      correctIndex: correct,
      explanation: j['explanation'] as String?,
      pageNumber: j['page_number'] as int?,
    );
  }
}

class QuizScreen extends StatefulWidget {
  final Chapter chapter;

  const QuizScreen({super.key, required this.chapter});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _isLoading = true;
  List<Question> _questions = [];
  final List<QuizAnswerEntry> _answers = [];
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final res = await Supabase.instance.client
          .from('questions')
          .select()
          .eq('chapter_id', widget.chapter.id)
          .eq('is_active', true)
          .order('"order"', ascending: true);
      if (mounted) {
        setState(() {
          _questions = (res as List).map((e) => Question.fromJson(e)).toList();
          _isLoading = false;
        });
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered) return;
    final q = _questions[_currentIndex];
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == q.correctIndex) _score++;
      _answers.add(QuizAnswerEntry(
        questionText: q.text,
        options: q.options,
        selectedIndex: index,
        correctIndex: q.correctIndex,
        isCorrect: index == q.correctIndex,
        explanation: q.explanation,
      ));
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      _slideController.reset();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _slideController.forward();
    } else {
      QuizHistoryService.save(
          QuizHistoryEntry(
            chapterTitle: widget.chapter.largeTitle.isNotEmpty
                ? widget.chapter.largeTitle
                : widget.chapter.circleTitle,
            score: _score,
            total: _questions.length,
            date: DateTime.now(),
          ),
          _answers);
      Navigator.of(context).pop();
    }
  }

  Color _optionColor(int index) {
    if (!_answered) return Colors.white;
    if (index == _questions[_currentIndex].correctIndex) {
      return const Color(0xFFE8F5E9);
    }
    if (index == _selectedOption) return const Color(0xFFFFEBEE);
    return Colors.white;
  }

  Color _optionBorderColor(int index) {
    if (!_answered) {
      return _selectedOption == index
          ? const Color(0xFF0080C8)
          : Colors.transparent;
    }
    if (index == _questions[_currentIndex].correctIndex) return Colors.green;
    if (index == _selectedOption) return Colors.red;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F1F1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('هیچ پرسیارێک نییە بۆ ئەم بەشە',
                  style:
                      TextStyle(fontFamily: 'Peshang', fontSize: 16 * scale)),
              SizedBox(height: 16 * scale),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('گەڕانەوە',
                    style:
                        TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale)),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final total = _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0080C8), Color(0xFF004A73)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  16 * scale, 12 * scale, 16 * scale, 16 * scale),
              child: Row(
                children: [
                  // ── Left: question list panel ──────────────────
                  Container(
                    width: screenWidth * 0.22,
                    height: 80 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_currentIndex + 1}/$total',
                          style: TextStyle(
                            fontFamily: 'Prototype',
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          'پرسیار',
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 11 * scale,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12 * scale),

                  // ── Right: chapter title + progress ───────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.chapter.largeTitle.isNotEmpty
                              ? widget.chapter.largeTitle
                              : widget.chapter.circleTitle,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4 * scale),
                          child: LinearProgressIndicator(
                            value: (_currentIndex + 1) / total,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6 * scale,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'دەرچوون',
                                style: TextStyle(
                                  fontFamily: 'Peshang',
                                  fontSize: 11 * scale,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(width: 4 * scale),
                              Icon(Icons.close_rounded,
                                  size: 14 * scale, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Question + options ────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8 * scale),

                      // Question card
                      Container(
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              offset: Offset(0, 4 * scale),
                              blurRadius: 12 * scale,
                            ),
                          ],
                        ),
                        child: Text(
                          question.text,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      SizedBox(height: 20 * scale),

                      // Options
                      ...List.generate(question.options.length, (i) {
                        final isCorrect = i == question.correctIndex;
                        final isSelected = i == _selectedOption;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12 * scale),
                          child: GestureDetector(
                            onTap: () => _selectOption(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 14 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: _optionColor(i),
                                borderRadius: BorderRadius.circular(14 * scale),
                                border: Border.all(
                                  color: _optionBorderColor(i),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    offset: Offset(0, 2 * scale),
                                    blurRadius: 6 * scale,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Option letter badge
                                  Container(
                                    width: 28 * scale,
                                    height: 28 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _answered
                                          ? (isCorrect
                                              ? Colors.green
                                              : isSelected
                                                  ? Colors.red
                                                  : Colors.grey.shade200)
                                          : const Color(0xFF0080C8)
                                              .withValues(alpha: 0.1),
                                    ),
                                    child: _answered &&
                                            (isCorrect || isSelected)
                                        ? Icon(
                                            isCorrect
                                                ? Icons.check_rounded
                                                : Icons.close_rounded,
                                            size: 16 * scale,
                                            color: Colors.white,
                                          )
                                        : Center(
                                            child: Text(
                                              String.fromCharCode(
                                                  65 + i), // A, B, C
                                              style: TextStyle(
                                                fontSize: 12 * scale,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0080C8),
                                              ),
                                            ),
                                          ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Text(
                                      question.options[i],
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: 'Peshang',
                                        fontSize: 13 * scale,
                                        height: 1.5,
                                        color: _answered
                                            ? (isCorrect
                                                ? Colors.green.shade800
                                                : isSelected
                                                    ? Colors.red.shade800
                                                    : Colors.black54)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: 8 * scale),

                      // Explanation bulb — shows after answering if available
                      if (_answered &&
                          _questions[_currentIndex].explanation != null)
                        _ExplanationBulb(
                          explanation: _questions[_currentIndex].explanation!,
                          scale: scale,
                        ),

                      // Next button — only shows after answering
                      if (_answered)
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14 * scale),
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          child: InkWell(
                            onTap: _next,
                            borderRadius: BorderRadius.circular(14 * scale),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0080C8),
                                    Color(0xFF004A73)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(14 * scale),
                              ),
                              child: Container(
                                height: 50 * scale,
                                alignment: Alignment.center,
                                child: Text(
                                  _currentIndex < _questions.length - 1
                                      ? 'پرسیاری دواتر ←'
                                      : 'تەواوکردن ✓',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationBulb extends StatefulWidget {
  final String explanation;
  final double scale;
  const _ExplanationBulb({required this.explanation, required this.scale});

  @override
  State<_ExplanationBulb> createState() => _ExplanationBulbState();
}

class _ExplanationBulbState extends State<_ExplanationBulb> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14 * scale, vertical: 10 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18 * scale, color: const Color(0xFFB8860B)),
                  ),
                  const Spacer(),
                  Text('ڕوونکردنەوە',
                      style: TextStyle(
                        fontFamily: 'Peshang',
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB8860B),
                      )),
                  SizedBox(width: 8 * scale),
                  Image.asset('assets/icons/bulb.png',
                      width: 18 * scale, height: 18 * scale),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              margin: EdgeInsets.only(top: 4 * scale),
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.explanation,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 12 * scale,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
