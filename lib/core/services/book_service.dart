import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookChapter {
  final String id;
  final String title;
  final int order;
  final String pdfUrl;
  final String pdfVersion;

  const BookChapter({
    required this.id,
    required this.title,
    required this.order,
    required this.pdfUrl,
    required this.pdfVersion,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      pdfUrl: json['pdf_url'] as String,
      pdfVersion: json['pdf_version']?.toString() ?? '1',
    );
  }
}

class BookService {
  static final BookService _instance = BookService._internal();
  factory BookService() => _instance;
  BookService._internal();

  final _storage = const FlutterSecureStorage();
  final _supabase = Supabase.instance.client;

  Future<List<BookChapter>> getChapters() async {
    debugPrint('BookService: fetching chapters...');
    final response = await _supabase
        .from('book_chapters')
        .select()
        .order('order', ascending: true);
    debugPrint('BookService: got ${(response as List).length} chapters');
    return (response as List)
        .map((e) => BookChapter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getPdfPath(BookChapter chapter) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/book_chapter_${chapter.order}.pdf';
    final file = File(filePath);

    final cachedVersion = await _storage.read(key: 'pdf_version_${chapter.id}');

    if (await file.exists() && cachedVersion == chapter.pdfVersion) {
      debugPrint('BookService: loading from cache: $filePath');
      return filePath;
    }

    debugPrint('BookService: downloading PDF for chapter ${chapter.order}');

    // Try signed URL first (private bucket), fallback to direct URL
    String downloadUrl = chapter.pdfUrl;
    try {
      // Extract path from the pdf_url if it's a storage path like "books/chapter1.pdf"
      // or generate signed URL if it's stored as just the file path
      if (!chapter.pdfUrl.startsWith('http')) {
        final signedUrl = await _supabase.storage
            .from('book')
            .createSignedUrl(chapter.pdfUrl, 3600);
        downloadUrl = signedUrl;
      }
    } catch (e) {
      debugPrint('BookService: signed URL failed, using direct: $e');
    }

    final response = await http.get(Uri.parse(downloadUrl))
        .timeout(const Duration(seconds: 60));
    debugPrint('BookService: download status ${response.statusCode}, bytes: ${response.bodyBytes.length}');

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      await file.writeAsBytes(response.bodyBytes);
      await _storage.write(key: 'pdf_version_${chapter.id}', value: chapter.pdfVersion);
    } else {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }

    return filePath;
  }

  Future<int> getLastPage(String chapterId) async {
    final val = await _storage.read(key: 'last_page_$chapterId');
    return int.tryParse(val ?? '1') ?? 1;
  }

  Future<void> saveLastPage(String chapterId, int page) async {
    await _storage.write(key: 'last_page_$chapterId', value: page.toString());
  }
}
