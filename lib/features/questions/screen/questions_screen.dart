import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_supabase_app/features/home/models/chapter_model.dart';
import 'package:flutter_supabase_app/core/services/supabase_service.dart';
import 'package:flutter_supabase_app/features/questions/screen/quiz_screen.dart';
import 'package:flutter_supabase_app/features/questions/widgets/quiz_chapters_card.dart';
import 'package:flutter_supabase_app/features/questions/screen/quiz_history_screen.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with TickerProviderStateMixin {
  final SupabaseService _service = SupabaseService();

  List<Chapter> _chapters = [];
  bool _isLoading = true;
  final Set<int> _selectedIndices = {};

  late AnimationController _historyIconController;

  @override
  void initState() {
    super.initState();
    _historyIconController = AnimationController(vsync: this);
    _loadChapters();
  }

  @override
  void dispose() {
    _historyIconController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _service.getChaptersWithProgress();
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startQuiz() {
    if (_selectedIndices.isEmpty) return;

    final chapter = _chapters[_selectedIndices.first];

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => QuizScreen(chapter: chapter),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E7BBF), Color(0xFF0E5A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20 * scale),
                bottomRight: Radius.circular(20 * scale),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005B8C).withValues(alpha: 0.3),
                  blurRadius: 20 * scale,
                  offset: Offset(0, 8 * scale),
                  spreadRadius: -4 * scale,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20 * scale),
                      bottomRight: Radius.circular(20 * scale),
                    ),
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset(
                        'assets/icons/blue-traffic-pattern-for-bg.png',
                        fit: BoxFit.cover,
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
                
                // Glow circle
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      18 * scale,
                      12 * scale,
                      18 * scale,
                      19 * scale,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, 7 * scale),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تاقیکردنەوە',
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 16.5 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'بەشەکانی دەوێت هەڵبژێرە و دەستت پێبکە',
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 10.5 * scale,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                        ),
                        const Spacer(),
                        Transform.translate(
                          offset: Offset(0, 4 * scale),
                          child: GestureDetector(
                          onTap: () {
                            if (_historyIconController.duration != null) {
                              _historyIconController.forward(from: 0);
                            }
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, animation, __) =>
                                    const QuizHistoryScreen(),
                                transitionsBuilder: (_, animation, __, child) =>
                                    SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            ).then((_) {});
                          },
                          child: Container(
                            width: 42 * scale,
                            height: 42 * scale,
                            alignment: Alignment.center,
                            child: Container(
                              width: 38 * scale,
                              height: 38 * scale,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12 * scale),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF2C6EA3), Color(0xFF1F5E8E)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12 * scale,
                                    offset: Offset(0, 4 * scale),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(9 * scale),
                                child: Lottie.asset(
                                  'assets/icons/system-solid-141-history-hover-history.json',
                                  controller: _historyIconController,
                                  onLoaded: (c) =>
                                      _historyIconController.duration = c.duration,
                                  repeat: false,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      16 * scale,
                      16 * scale,
                      24 * scale,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 12 * scale,
                                  offset: Offset(0, 4 * scale),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16 * scale),
                            child: QuizChaptersCard(
                              chapters: _chapters,
                              selectedIndices: _selectedIndices,
                              onToggle: (i) => setState(() {
                                if (_selectedIndices.contains(i)) {
                                  _selectedIndices.remove(i);
                                } else {
                                  _selectedIndices.add(i);
                                }
                              }),
                              onStart: _startQuiz,
                              scale: scale,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}