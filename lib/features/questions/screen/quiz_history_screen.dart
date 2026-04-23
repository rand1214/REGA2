import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_supabase_app/core/services/quiz_history_service.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen>
    with TickerProviderStateMixin {
  List<QuizHistoryEntry> _history = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  late AnimationController _reloadController;
  late AnimationController _trashController;
  late AnimationController _crossController;

  @override
  void initState() {
    super.initState();
    _reloadController = AnimationController(vsync: this);
    _trashController = AnimationController(vsync: this);
    _crossController = AnimationController(vsync: this);
    _load();
  }

  @override
  void dispose() {
    _reloadController.dispose();
    _trashController.dispose();
    _crossController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final h = await QuizHistoryService.load();
    if (mounted) {
      setState(() {
        _history = h;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await QuizHistoryService.clear();
    if (mounted) {
      setState(() => _history = []);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.length == _history.length) {
      await _clearAll();
    } else {
      _history.removeWhere((item) {
        final key =
            item.id.isEmpty ? '${item.chapterTitle}_${item.date}' : item.id;
        return _selectedIds.contains(key);
      });
    }

    if (mounted) {
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
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
                  color: const Color.fromRGBO(0, 91, 140, 0.3),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(255, 255, 255, 0.08),
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
                                  'مێژووی تاقیکردنەوە',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 16.5 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'دوایین تاقیکردنەوەکانت لێرەدا دەبینیت',
                                  style: TextStyle(
                                    fontFamily: 'Peshang',
                                    fontSize: 10.5 * scale,
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Transform.translate(
                            offset: Offset(0, 4 * scale),
                            child: GestureDetector(
                              onTap: () async {
                                if (_reloadController.duration != null) {
                                  _reloadController.forward(from: 0);
                                }
                                await _load();
                              },
                              child: Container(
                                width: 42 * scale,
                                height: 42 * scale,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12 * scale),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C6EA3),
                                        Color(0xFF1F5E8E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                          0,
                                          0,
                                          0,
                                          0.15,
                                        ),
                                        blurRadius: 12 * scale,
                                        offset: Offset(0, 4 * scale),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(9 * scale),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      child: Lottie.asset(
                                        'assets/icons/Reload.json',
                                        controller: _reloadController,
                                        onLoaded: (c) =>
                                            _reloadController.duration = c.duration,
                                        repeat: false,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Transform.translate(
                            offset: Offset(0, 4 * scale),
                            child: GestureDetector(
                              onTap: () async {
                                if (_trashController.duration != null) {
                                  _trashController.forward(from: 0);
                                }
                                _toggleSelectionMode();
                              },
                              child: Container(
                                width: 42 * scale,
                                height: 42 * scale,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12 * scale),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C6EA3),
                                        Color(0xFF1F5E8E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                          0,
                                          0,
                                          0,
                                          0.15,
                                        ),
                                        blurRadius: 12 * scale,
                                        offset: Offset(0, 4 * scale),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(9 * scale),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      child: Lottie.asset(
                                        'assets/icons/trash-animated-icon.json',
                                        controller: _trashController,
                                        onLoaded: (c) =>
                                            _trashController.duration = c.duration,
                                        repeat: false,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          Transform.translate(
                            offset: Offset(0, 4 * scale),
                            child: GestureDetector(
                              onTap: () {
                                if (_crossController.duration != null) {
                                  _crossController.forward(from: 0);
                                }
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 42 * scale,
                                height: 42 * scale,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12 * scale),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C6EA3),
                                        Color(0xFF1F5E8E),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                          0,
                                          0,
                                          0,
                                          0.15,
                                        ),
                                        blurRadius: 12 * scale,
                                        offset: Offset(0, 4 * scale),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(9 * scale),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      child: Lottie.asset(
                                        'assets/icons/cross-remove.json',
                                        controller: _crossController,
                                        onLoaded: (c) =>
                                            _crossController.duration = c.duration,
                                        repeat: false,
                                        fit: BoxFit.contain,
                                      ),
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
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64 * scale,
                              color: Colors.black12,
                            ),
                            SizedBox(height: 16 * scale),
                            Text(
                              'مێژووی تاقیکردنەوە',
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'هێشتا هیچ تاقیکردنەوەیەک نەکردووە',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Peshang',
                                fontSize: 14 * scale,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            16 * scale,
                            16 * scale,
                            24 * scale,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              children: [
                                _HistoryList(
                                  history: _history,
                                  scale: scale,
                                  isSelectionMode: _isSelectionMode,
                                  selectedIds: _selectedIds,
                                  onSelectionChanged: (id, selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedIds.add(id);
                                      } else {
                                        _selectedIds.remove(id);
                                      }
                                    });
                                  },
                                ),
                                if (_isSelectionMode && _selectedIds.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.all(16 * scale),
                                    child: ElevatedButton(
                                      onPressed: _deleteSelected,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF3B30),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16 * scale,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12 * scale),
                                        ),
                                      ),
                                      child: Text(
                                        'سڕینەوەی ${_selectedIds.length} تاقیکردنەوە',
                                        style: TextStyle(
                                          fontFamily: 'Peshang',
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatefulWidget {
  final List<QuizHistoryEntry> history;
  final double scale;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final Function(String, bool) onSelectionChanged;

  const _HistoryList({
    required this.history,
    required this.scale,
    this.isSelectionMode = false,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  final Set<String> _expanded = {};

  String _toKurdishNum(int n) {
    const map = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return n.toString().split('').map((c) => map[c] ?? c).join();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Column(
      children: widget.history
          .asMap()
          .entries
          .map(
            (e) => _buildRow(
              e.value,
              s,
              e.key == widget.history.length - 1,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRow(QuizHistoryEntry e, double s, bool isLast) {
    final pct = e.total == 0 ? 0.0 : e.score / e.total;
    final color = pct >= 0.8
        ? const Color(0xFF34C759)
        : pct >= 0.5
            ? const Color(0xFFFF9500)
            : const Color(0xFFFF3B30);

    final diff = DateTime.now().difference(e.date);
    final String timeLabel;

    if (diff.inMinutes < 1) {
      timeLabel = 'ئێستا';
    } else if (diff.inMinutes < 60) {
      timeLabel = '${_toKurdishNum(diff.inMinutes)} خولەک پێش ئێستا';
    } else if (diff.inHours < 24) {
      timeLabel = '${_toKurdishNum(diff.inHours)} کاتژمێر پێش ئێستا';
    } else {
      timeLabel = '${_toKurdishNum(diff.inDays)} ڕۆژ پێش ئێستا';
    }

    final key = e.id.isEmpty ? '${e.chapterTitle}_${e.date}' : e.id;
    final isExpanded = _expanded.contains(key);
    final hasAnswers = e.answers.isNotEmpty;
    final isSelected = widget.selectedIds.contains(key);

    return Column(
      children: [
        GestureDetector(
          onTap: widget.isSelectionMode
              ? () => widget.onSelectionChanged(key, !isSelected)
              : hasAnswers
                  ? () => setState(() {
                        if (isExpanded) {
                          _expanded.remove(key);
                        } else {
                          _expanded.add(key);
                        }
                      })
                  : null,
          child: Container(
            color: widget.isSelectionMode && isSelected
                ? const Color.fromRGBO(33, 150, 243, 0.1)
                : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10 * s,
                horizontal: 16 * s,
              ),
              child: Row(
                children: [
                  if (widget.isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          widget.onSelectionChanged(key, value ?? false),
                      activeColor: const Color(0xFF1E7BBF),
                    ),
                    SizedBox(width: 8 * s),
                  ],
                  SizedBox(
                    width: 36 * s,
                    height: 36 * s,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 3 * s,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 8 * s,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          e.chapterTitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 10 * s,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * s,
                      vertical: 4 * s,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        color.r.toInt(),
                        color.g.toInt(),
                        color.b.toInt(),
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(8 * s),
                    ),
                    child: Text(
                      '${e.score}/${e.total}',
                      style: TextStyle(
                        fontFamily: 'Prototype',
                        fontSize: 12 * s,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  if (hasAnswers && !widget.isSelectionMode) ...[
                    SizedBox(width: 6 * s),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18 * s,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && hasAnswers && !widget.isSelectionMode)
          Padding(
            padding: EdgeInsets.only(bottom: 10 * s),
            child: Column(
              children: e.answers.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;

                return Padding(
                  padding: EdgeInsets.only(bottom: 8 * s),
                  child: Container(
                    padding: EdgeInsets.all(10 * s),
                    decoration: BoxDecoration(
                      color: a.isCorrect
                          ? const Color.fromRGBO(52, 199, 89, 0.06)
                          : const Color.fromRGBO(255, 59, 48, 0.06),
                      borderRadius: BorderRadius.circular(10 * s),
                      border: Border.all(
                        color: a.isCorrect
                            ? const Color.fromRGBO(52, 199, 89, 0.3)
                            : const Color.fromRGBO(255, 59, 48, 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${_toKurdishNum(i + 1)}. ${a.questionText}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Peshang',
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 6 * s),
                        if (!a.isCorrect) ...[
                          _chip(
                            'هەڵبژاردنت: ${a.options[a.selectedIndex]}',
                            const Color(0xFFFF3B30),
                            s,
                          ),
                          SizedBox(height: 4 * s),
                        ],
                        _chip(
                          'وەڵامی دروست: ${a.options[a.correctIndex]}',
                          const Color(0xFF34C759),
                          s,
                        ),
                        if (a.explanation != null) ...[
                          SizedBox(height: 6 * s),
                          _ExplanationBulb(
                            explanation: a.explanation!,
                            scale: s,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (!isLast || isExpanded)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Color.fromRGBO(0, 0, 0, 0.06),
          ),
      ],
    );
  }

  Widget _chip(String label, Color color, double s) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * s,
          vertical: 3 * s,
        ),
        decoration: BoxDecoration(
          color: Color.fromRGBO(
            color.r.toInt(),
            color.g.toInt(),
            color.b.toInt(),
            0.1,
          ),
          borderRadius: BorderRadius.circular(6 * s),
        ),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Peshang',
            fontSize: 10 * s,
            color: color,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ExplanationBulb extends StatefulWidget {
  final String explanation;
  final double scale;

  const _ExplanationBulb({
    required this.explanation,
    required this.scale,
  });

  @override
  State<_ExplanationBulb> createState() => _ExplanationBulbState();
}

class _ExplanationBulbState extends State<_ExplanationBulb> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * s,
              vertical: 7 * s,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8 * s),
              border: Border.all(
                color: const Color.fromRGBO(255, 204, 0, 0.4),
              ),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16 * s,
                    color: const Color(0xFFB8860B),
                  ),
                ),
                const Spacer(),
                Text(
                  'ڕوونکردنەوە',
                  style: TextStyle(
                    fontFamily: 'Peshang',
                    fontSize: 10 * s,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB8860B),
                  ),
                ),
                SizedBox(width: 6 * s),
                Image.asset(
                  'assets/icons/bulb.png',
                  width: 14 * s,
                  height: 14 * s,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: EdgeInsets.only(top: 4 * s),
            padding: EdgeInsets.all(10 * s),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8 * s),
              border: Border.all(
                color: const Color.fromRGBO(255, 204, 0, 0.3),
              ),
            ),
            child: Text(
              widget.explanation,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Peshang',
                fontSize: 11 * s,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }
}