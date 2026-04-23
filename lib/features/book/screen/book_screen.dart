import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../../core/services/book_service.dart';
import '../models/book_note.dart';
import '../models/book_bookmark.dart';
import '../services/book_local_storage.dart';
import '../widgets/book_top_bar.dart';
import '../widgets/sticky_note_widget.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/add_note_sheet.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/textbox_widget.dart';
import '../models/book_drawing.dart';
import '../models/book_textbox.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final BookService _bookService = BookService();
  final BookLocalStorage _localStorage = BookLocalStorage();
  final TransformationController _transformController = TransformationController();

  List<BookChapter> _chapters = [];
  int _selectedChapterIndex = 0;
  bool _isLoadingChapters = true;
  bool _isLoadingPdf = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isBookmarked = false;

  List<BookNote> _notes = [];
  List<BookBookmark> _bookmarks = [];
  List<BookDrawing> _drawings = [];
  List<BookTextBox> _textBoxes = [];
  bool _isNoteEditing = false;
  bool _isDrawingEditing = false;
  bool _isZoomed = false;
  String _activeTool = 'none';
  int _activeColor = 0xFFFFEB3B;
  ShapeType _activeShape = ShapeType.rectangle; // none, highlight, pencil

  // Rendered page images cache: pageNumber -> image bytes
  final Map<int, Uint8List> _pageImages = {};
  PdfDocument? _pdfDocument;
  Size? _pdfPageSize;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  final ScrollController _filmstripController = ScrollController();

  @override
  void dispose() {
    _pdfDocument?.close();
    _transformController.dispose();
    _filmstripController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _bookService.getChapters();
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _isLoadingChapters = false;
      });
      if (chapters.isNotEmpty) _loadChapter(0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingChapters = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadChapter(int index) async {
    if (index >= _chapters.length) return;
    final chapter = _chapters[index];
    final dir = await getApplicationDocumentsDirectory();
    final isCached = await File('${dir.path}/book_chapter_${chapter.order}.pdf').exists();

    setState(() {
      _selectedChapterIndex = index;
      if (!isCached) _isLoadingPdf = true;
    });

    try {
      final path = await _bookService.getPdfPath(chapter);
      final lastPage = await _bookService.getLastPage(chapter.id);
      final notes = await _localStorage.getNotes(chapter.id);
      final bookmarks = await _localStorage.getBookmarks(chapter.id);
      final drawings = await _localStorage.getDrawings(chapter.id);
      final textBoxes = await _localStorage.getTextBoxes(chapter.id);
      final isBookmarked = bookmarks.any((b) => b.page == lastPage);

      // Open PDF document
      await _pdfDocument?.close();
      final doc = await PdfDocument.openFile(path);
      final firstPage = await doc.getPage(1);
      final pageSize = Size(firstPage.width, firstPage.height);
      await firstPage.close();

      if (!mounted) return;
      setState(() {
        _pdfDocument = doc;
        _totalPages = doc.pagesCount;
        _pdfPageSize = pageSize;
        _isLoadingPdf = false;
        _currentPage = lastPage;
        _notes = notes;
        _bookmarks = bookmarks;
        _drawings = drawings;
        _textBoxes = textBoxes;
        _isBookmarked = isBookmarked;
        _pageImages.clear();
        _transformController.value = Matrix4.identity();
      });

      // Pre-render at least 10 surrounding pages
      _preloadPages(lastPage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPdf = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _renderPage(int pageNumber) async {
    if (_pdfDocument == null) return;
    if (_pageImages.containsKey(pageNumber)) return;
    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        backgroundColor: '#ffffff',
      );
      await page.close();
      if (mounted && pageImage != null) {
        setState(() => _pageImages[pageNumber] = pageImage.bytes);
      }
    } catch (_) {}
  }

  void _onPageChanged(int page) {
    final isBookmarked = _bookmarks.any((b) => b.page == page);
    setState(() {
      _currentPage = page;
      _isBookmarked = isBookmarked;
      _transformController.value = Matrix4.identity();
    });
    if (_chapters.isNotEmpty) {
      _bookService.saveLastPage(_chapters[_selectedChapterIndex].id, page);
    }
    // Scroll filmstrip to current page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_filmstripController.hasClients) {
        const itemW = 52.0;
        final offset = ((page - 1) * itemW) - (_filmstripController.position.viewportDimension / 2) + itemW / 2;
        _filmstripController.animateTo(
          offset.clamp(0.0, _filmstripController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    _preloadPages(page);
  }

  void _preloadPages(int page) {
    if (_pdfDocument == null) return;

    final int startPage = (page - 4).clamp(1, _totalPages);
    final int endPage = (startPage + 9).clamp(1, _totalPages);
    final int adjustedStart = (endPage - 9).clamp(1, _totalPages);

    for (var pageNumber = adjustedStart; pageNumber <= endPage; pageNumber++) {
      _renderPage(pageNumber);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_chapters.isEmpty) return;
    final chapter = _chapters[_selectedChapterIndex];
    if (_isBookmarked) {
      final bookmark = _bookmarks.firstWhere((b) => b.page == _currentPage);
      await _localStorage.deleteBookmark(chapter.id, bookmark.id);
    } else {
      final bookmark = BookBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chapterId: chapter.id,
        page: _currentPage,
        label: 'پەڕەی $_currentPage',
        createdAt: DateTime.now(),
      );
      await _localStorage.saveBookmark(bookmark);
    }
    final bookmarks = await _localStorage.getBookmarks(chapter.id);
    final isBookmarked = bookmarks.any((b) => b.page == _currentPage);
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _isBookmarked = isBookmarked;
    });
  }

  void _showAddNoteSheet() {
    if (_chapters.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(
        onSave: (text, color) async {
          final note = BookNote(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chapterId: _chapters[_selectedChapterIndex].id,
            page: _currentPage,
            xPercent: 0.5,
            yPercent: 0.3,
            text: text,
            colorValue: color.toARGB32(),
            createdAt: DateTime.now(),
          );
          await _localStorage.saveNote(note);
          final notes = await _localStorage.getNotes(_chapters[_selectedChapterIndex].id);
          if (mounted) setState(() => _notes = notes);
        },
      ),
    );
  }

  void _showBookmarks() {
    if (_chapters.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookmarksSheet(
        bookmarks: _bookmarks,
        onTap: (page) {
          Navigator.pop(context);
          _onPageChanged(page);
        },
        onDelete: (id) async {
          await _localStorage.deleteBookmark(_chapters[_selectedChapterIndex].id, id);
          final bookmarks = await _localStorage.getBookmarks(_chapters[_selectedChapterIndex].id);
          if (mounted) setState(() => _bookmarks = bookmarks);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Column(
        children: [
          BookTopBar(
            scale: scale,
            chapters: _chapters,
            selectedIndex: _selectedChapterIndex,
            currentPage: _currentPage,
            totalPages: _totalPages,
            isBookmarked: _isBookmarked,
            onChapterSelected: _loadChapter,
            onBookmarkTap: _toggleBookmark,
            onBookmarkListTap: _showBookmarks,
            onAddNoteTap: _showAddNoteSheet,
            activeTool: _activeTool,
            activeColor: _activeColor,
            activeShape: _activeShape,
            onToolSelected: (tool) {
              if (!_isDrawingEditing) setState(() => _activeTool = tool);
            },
            onColorSelected: (color) {
              setState(() => _activeColor = color);
            },
            onShapeSelected: (shape) {
              if (!_isDrawingEditing) setState(() => _activeShape = shape);
            },
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _buildBody()),
                if (_pdfDocument != null && _totalPages > 1)
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: AnimatedSlide(
                      offset: _isZoomed ? const Offset(0, 1) : Offset.zero,
                      duration: const Duration(milliseconds: 250),
                      curve: _isZoomed ? Curves.easeIn : Curves.easeOutCubic,
                      child: _buildFilmstrip(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingChapters) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0080C8)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      );
    }
    if (_isLoadingPdf || _pdfDocument == null || _pdfPageSize == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0080C8)));
    }

    final pageNotes = _notes.where((n) => n.page == _currentPage).toList();
    final imageBytes = _pageImages[_currentPage];

    return LayoutBuilder(builder: (context, constraints) {
      final viewW = constraints.maxWidth;
      final viewH = constraints.maxHeight;
      final pageAspect = _pdfPageSize!.width / _pdfPageSize!.height;
      final viewAspect = viewW / viewH;
      double pageW, pageH;
      if (pageAspect > viewAspect) {
        pageW = viewW;
        pageH = viewW / pageAspect;
      } else {
        pageH = viewH;
        pageW = viewH * pageAspect;
      }

        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 1.0,
          maxScale: 5.0,
          panEnabled: !_isNoteEditing,
          scaleEnabled: !_isNoteEditing,
          onInteractionUpdate: (details) {
            final scale = _transformController.value.getMaxScaleOnAxis();
            final zoomed = scale > 1.05;
            if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
          },
          onInteractionEnd: (details) {
            if (_isNoteEditing) return;
            final scale = _transformController.value.getMaxScaleOnAxis();
            final zoomed = scale > 1.05;
            if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
            if (scale > 1.05) return;
            final velocity = details.velocity.pixelsPerSecond.dx;
            if (velocity < -300 && _currentPage < _totalPages) {
              _onPageChanged(_currentPage + 1);
            } else if (velocity > 300 && _currentPage > 1) {
              _onPageChanged(_currentPage - 1);
            }
          },
          child: SizedBox(
            width: viewW,
            height: viewH,
            child: Center(
              child: SizedBox(
                width: pageW,
                height: pageH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(imageBytes, fit: BoxFit.fill),
                          )
                        : const Center(child: CircularProgressIndicator(
                            color: Color(0xFF0080C8))),
                    // Drawing canvas
                    SizedBox(
                      width: pageW,
                      height: pageH,
                      child: DrawingCanvas(
                        activeTool: _activeTool,
                        colorValue: _activeColor,
                        activeShape: _activeShape,
                        drawings: _drawings.where((d) => d.page == _currentPage).toList(),
                        constraints: BoxConstraints.tight(Size(pageW, pageH)),
                        onDrawingComplete: (drawing) async {
                          if (_chapters.isEmpty) return;
                          final chapter = _chapters[_selectedChapterIndex];
                          final saved = BookDrawing(
                            id: drawing.id,
                            chapterId: chapter.id,
                            page: _currentPage,
                            type: drawing.type,
                            colorValue: drawing.colorValue,
                            opacity: drawing.opacity,
                            x1Percent: drawing.x1Percent,
                            y1Percent: drawing.y1Percent,
                            x2Percent: drawing.x2Percent,
                            y2Percent: drawing.y2Percent,
                            points: drawing.points,
                            shapeType: drawing.shapeType,
                            createdAt: drawing.createdAt,
                          );
                          await _localStorage.saveDrawing(saved);
                          final drawings = await _localStorage.getDrawings(chapter.id);
                          if (mounted) setState(() => _drawings = drawings);
                        },
                        onDrawingDelete: (id) async {
                          if (_chapters.isEmpty) return;
                          final chapter = _chapters[_selectedChapterIndex];
                          await _localStorage.deleteDrawing(chapter.id, id);
                          final drawings = await _localStorage.getDrawings(chapter.id);
                          if (mounted) setState(() => _drawings = drawings);
                        },
                        onEditingChanged: (isEditing) {
                          setState(() => _isDrawingEditing = isEditing);
                        },
                      ),
                    ),
                    ...pageNotes.map((note) {
                      final noteConstraints = BoxConstraints.tight(Size(pageW, pageH));
                      return StickyNoteWidget(
                        key: ValueKey(note.id),
                        note: note,
                        constraints: noteConstraints,
                        onEditingChanged: (editing) =>
                            setState(() => _isNoteEditing = editing),
                        onDelete: () async {
                          await _localStorage.deleteNote(note.chapterId, note.id);
                          final notes = await _localStorage.getNotes(note.chapterId);
                          if (mounted) setState(() => _notes = notes);
                        },
                        onMoved: (newX, newY, size) async {
                          final updated = BookNote(
                            id: note.id, chapterId: note.chapterId,
                            page: note.page, xPercent: newX, yPercent: newY,
                            text: note.text, colorValue: note.colorValue,
                            size: size, createdAt: note.createdAt,
                          );
                          await _localStorage.saveNote(updated);
                          final notes = await _localStorage.getNotes(note.chapterId);
                          if (mounted) setState(() => _notes = notes);
                        },
                      );
                    }),
                    // Text boxes
                    ..._textBoxes.where((t) => t.page == _currentPage).map((tb) {
                      final tbConstraints = BoxConstraints.tight(Size(pageW, pageH));
                      return TextBoxWidget(
                        key: ValueKey(tb.id),
                        textBox: tb,
                        constraints: tbConstraints,
                        onUpdate: (updated) async {
                          if (_chapters.isEmpty) return;
                          await _localStorage.saveTextBox(updated);
                          final tbs = await _localStorage.getTextBoxes(_chapters[_selectedChapterIndex].id);
                          if (mounted) setState(() => _textBoxes = tbs);
                        },
                        onDelete: () async {
                          if (_chapters.isEmpty) return;
                          await _localStorage.deleteTextBox(tb.chapterId, tb.id);
                          final tbs = await _localStorage.getTextBoxes(_chapters[_selectedChapterIndex].id);
                          if (mounted) setState(() => _textBoxes = tbs);
                        },
                      );
                    }),
                    // Textbox placement tap layer
                    ...(_activeTool == 'textbox' ? [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (d) async {
                            if (_chapters.isEmpty) return;
                            final chapter = _chapters[_selectedChapterIndex];
                            final tb = BookTextBox(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              chapterId: chapter.id,
                              page: _currentPage,
                              xPercent: d.localPosition.dx / pageW,
                              yPercent: d.localPosition.dy / pageH,
                              text: 'کلیک بکە بۆ نووسین',
                              textColorValue: 0xFF000000,
                              bgColorValue: 0xFFFFEB3B,
                              createdAt: DateTime.now(),
                            );
                            await _localStorage.saveTextBox(tb);
                            final tbs = await _localStorage.getTextBoxes(chapter.id);
                            if (mounted) setState(() {
                              _textBoxes = tbs;
                              _activeTool = 'none';
                            });
                          },
                        ),
                      ),
                    ] : []),
                  ],
                ),
              ),
            ),
          ),
        );
      });
  }

  List<Widget> _buildNoteIndicators(int pageNum) {
    final pageNotes = _notes.where((n) => n.page == pageNum).toList();
    if (pageNotes.isEmpty) return [];

    // Deduplicate by color, max 3 shown
    final colors = pageNotes.map((n) => n.colorValue).toSet().take(3).toList();

    return List.generate(colors.length, (i) {
      return Positioned(
        bottom: -4,
        right: -4.0 + (i * 14.0),
        child: Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: Color(colors[i]),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: const Icon(Icons.sticky_note_2_rounded, size: 8, color: Colors.white),
        ),
      );
    });
  }

  Widget _buildFilmstrip() {
    const itemW = 56.0;
    const itemH = 80.0;
    const spacing = 8.0;

    return Container(
      height: itemH + 36,
      color: const Color(0xFFF1F1F1),
      child: ListView.builder(
        controller: _filmstripController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _totalPages,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final isSelected = pageNum == _currentPage;
          final imageBytes = _pageImages[pageNum];

          return GestureDetector(
            onTap: () => _onPageChanged(pageNum),
            child: Container(
              margin: const EdgeInsets.only(right: spacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: itemW,
                        height: itemH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0080C8) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF0080C8).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: imageBytes != null
                        ? Image.memory(imageBytes, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Text(
                                '$pageNum',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ),
                          ),
                  ),
                ),
                // Bookmark indicator
                if (_bookmarks.any((b) => b.page == pageNum))
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_rounded, size: 12, color: Color(0xFFFFD700)),
                    ),
                  ),
                // Sticky note indicators
                ..._buildNoteIndicators(pageNum),
              ],
            ),
                const SizedBox(height: 3),
                SizedBox(
                  width: itemW,
                  child: Text(
                    '$pageNum',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? const Color(0xFF0080C8) : Colors.grey.shade500,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
