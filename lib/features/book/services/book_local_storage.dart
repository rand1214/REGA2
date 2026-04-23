import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/book_note.dart';
import '../models/book_bookmark.dart';
import '../models/book_drawing.dart';
import '../models/book_textbox.dart';

class BookLocalStorage {
  static final BookLocalStorage _instance = BookLocalStorage._internal();
  factory BookLocalStorage() => _instance;
  BookLocalStorage._internal();

  final _storage = const FlutterSecureStorage();

  // ── Notes ──────────────────────────────────────────────
  Future<List<BookNote>> getNotes(String chapterId) async {
    final raw = await _storage.read(key: 'notes_$chapterId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => BookNote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNote(BookNote note) async {
    final notes = await getNotes(note.chapterId);
    notes.removeWhere((n) => n.id == note.id);
    notes.add(note);
    await _storage.write(
      key: 'notes_${note.chapterId}',
      value: jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> deleteNote(String chapterId, String noteId) async {
    final notes = await getNotes(chapterId);
    notes.removeWhere((n) => n.id == noteId);
    await _storage.write(
      key: 'notes_$chapterId',
      value: jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  // ── Bookmarks ──────────────────────────────────────────
  Future<List<BookBookmark>> getBookmarks(String chapterId) async {
    final raw = await _storage.read(key: 'bookmarks_$chapterId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => BookBookmark.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBookmark(BookBookmark bookmark) async {
    final bookmarks = await getBookmarks(bookmark.chapterId);
    bookmarks.removeWhere((b) => b.id == bookmark.id);
    bookmarks.add(bookmark);
    await _storage.write(
      key: 'bookmarks_${bookmark.chapterId}',
      value: jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> deleteBookmark(String chapterId, String bookmarkId) async {
    final bookmarks = await getBookmarks(chapterId);
    bookmarks.removeWhere((b) => b.id == bookmarkId);
    await _storage.write(
      key: 'bookmarks_$chapterId',
      value: jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<bool> isPageBookmarked(String chapterId, int page) async {
    final bookmarks = await getBookmarks(chapterId);
    return bookmarks.any((b) => b.page == page);
  }

  // ── Drawings ──────────────────────────────────────────
  Future<List<BookDrawing>> getDrawings(String chapterId) async {
    final raw = await _storage.read(key: 'drawings_$chapterId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => BookDrawing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveDrawing(BookDrawing drawing) async {
    final drawings = await getDrawings(drawing.chapterId);
    drawings.removeWhere((d) => d.id == drawing.id);
    drawings.add(drawing);
    await _storage.write(
      key: 'drawings_${drawing.chapterId}',
      value: jsonEncode(drawings.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> deleteDrawing(String chapterId, String drawingId) async {
    final drawings = await getDrawings(chapterId);
    drawings.removeWhere((d) => d.id == drawingId);
    await _storage.write(
      key: 'drawings_$chapterId',
      value: jsonEncode(drawings.map((d) => d.toJson()).toList()),
    );
  }

  // ── Text Boxes ─────────────────────────────────────────
  Future<List<BookTextBox>> getTextBoxes(String chapterId) async {
    final raw = await _storage.read(key: 'textboxes_$chapterId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => BookTextBox.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTextBox(BookTextBox tb) async {
    final list = await getTextBoxes(tb.chapterId);
    list.removeWhere((t) => t.id == tb.id);
    list.add(tb);
    await _storage.write(
      key: 'textboxes_${tb.chapterId}',
      value: jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> deleteTextBox(String chapterId, String id) async {
    final list = await getTextBoxes(chapterId);
    list.removeWhere((t) => t.id == id);
    await _storage.write(
      key: 'textboxes_$chapterId',
      value: jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }
}