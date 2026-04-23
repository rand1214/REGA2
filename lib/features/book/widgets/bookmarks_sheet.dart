import 'package:flutter/material.dart';
import '../models/book_bookmark.dart';

class BookmarksSheet extends StatelessWidget {
  final List<BookBookmark> bookmarks;
  final Function(int page) onTap;
  final Function(String id) onDelete;

  const BookmarksSheet({
    super.key,
    required this.bookmarks,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.8, 1.5);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20 * scale)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Text(
                'بووکمارکەکان',
                style: TextStyle(
                  fontFamily: 'Peshang',
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            if (bookmarks.isEmpty)
              Padding(
                padding: EdgeInsets.all(32 * scale),
                child: Text(
                  'هیچ بووکمارکێک نییە',
                  style: TextStyle(fontFamily: 'Peshang', fontSize: 14 * scale, color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final b = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark_rounded, color: Color(0xFF0080C8)),
                      title: Text(
                        b.label,
                        style: TextStyle(fontFamily: 'Peshang', fontSize: 13 * scale),
                      ),
                      subtitle: Text(
                        'پەڕەی ${b.page}',
                        style: TextStyle(fontFamily: 'Peshang', fontSize: 11 * scale, color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => onDelete(b.id),
                      ),
                      onTap: () => onTap(b.page),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
