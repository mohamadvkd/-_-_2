import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'reader_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({Key? key}) : super(key: key);

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<Map<String, dynamic>> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = StorageService.getBookmarks();
    });
  }

  Future<void> _removeBookmark(int surahNumber, int ayahNumber) async {
    await StorageService.removeBookmark(surahNumber, ayahNumber);
    _loadBookmarks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إزالة الآية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المحفوظات',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'حذف الكل',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: _bookmarks.isEmpty ? _buildEmpty(scheme) : _buildList(scheme),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع المحفوظات'),
        content: const Text('هل أنت متأكد من حذف جميع الآيات المحفوظة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.clearBookmarks();
      _loadBookmarks();
    }
  }

  Widget _buildEmpty(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            const Text(
              'ستظهر آياتك المحفوظة هنا',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ آية أثناء القراءة بالضغط على أيقونة الحفظ',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ColorScheme scheme) {
    return RefreshIndicator(
      onRefresh: () async => _loadBookmarks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _bookmarks.length,
        itemBuilder: (context, index) {
          final b = _bookmarks[index];
          final surahNumber = b['surahNumber'] as int? ?? 1;
          final surahName = b['surahName'] as String? ?? '';
          final ayahNumber = b['ayahNumber'] as int? ?? 1;
          final ayahText = b['ayahText'] as String? ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$surahName • $ayahNumber',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 20,
                        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                        onPressed: () => _removeBookmark(surahNumber, ayahNumber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ayahText,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.9,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReaderPage(
                              surahNumber: surahNumber,
                              surahName: surahName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text('فتح السورة'),
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