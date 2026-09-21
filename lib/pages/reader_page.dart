import 'package:flutter/material.dart';
import '../models/ayah.dart';
import '../models/reciter.dart';
import '../services/quran_api.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../theme.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    Key? key,
    required this.surahNumber,
    required this.surahName,
  }) : super(key: key);

  final int surahNumber;
  final String surahName;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  List<Ayah> _ayahs = [];
  bool _loading = true;
  String? _error;
  double _fontSize = 26.0;
  Reciter? _selectedReciter;

  @override
  void initState() {
    super.initState();
    _fontSize = StorageService.getQuranFontSize();

    final reciters = QuranApi.getReciters();
    final prefId = StorageService.getPreferredReciter();
    _selectedReciter = reciters.firstWhere(
      (r) => r.identifier == prefId,
      orElse: () => reciters.first,
    );

    _loadAyahs();
  }

  Future<void> _loadAyahs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // 1) من Cache
    final cached = StorageService.getAyahsCache(widget.surahNumber);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _ayahs = cached;
        _loading = false;
      });
      // احفظ آخر قراءة
      _saveLastRead();
      return;
    }

    // 2) من API
    try {
      final ayahs = await QuranApi.fetchAyahs(widget.surahNumber);
      await StorageService.saveAyahsCache(widget.surahNumber, ayahs);
      if (!mounted) return;
      setState(() {
        _ayahs = ayahs;
        _loading = false;
      });
      _saveLastRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل السورة. تأكد من الاتصال بالإنترنت.\n$e';
        _loading = false;
      });
    }
  }

  void _saveLastRead() {
    if (_ayahs.isEmpty) return;
    StorageService.saveLastRead(
      surahNumber: widget.surahNumber,
      surahName: widget.surahName,
      ayahNumber: 1,
    );
  }

  void _changeFontSize(double newSize) {
    setState(() => _fontSize = newSize);
    StorageService.setQuranFontSize(newSize);
  }

  Future<void> _playAudio() async {
    if (_selectedReciter == null) return;
    final success = await AudioService.playSurah(_selectedReciter!, widget.surahNumber);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل التلاوة. تأكد من وجود تطبيق مشغل.')),
      );
    }
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    final isMarked = StorageService.isBookmarked(widget.surahNumber, ayah.numberInSurah);
    if (isMarked) {
      await StorageService.removeBookmark(widget.surahNumber, ayah.numberInSurah);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إزالة الآية من المحفوظات')),
      );
    } else {
      await StorageService.addBookmark(
        surahNumber: widget.surahNumber,
        surahName: widget.surahName,
        ayahNumber: ayah.numberInSurah,
        ayahText: ayah.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الآية في المحفوظات')),
      );
    }
    setState(() {});
  }

  void _showRecitersDialog() {
    final reciters = QuranApi.getReciters();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر القارئ'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reciters.length,
            itemBuilder: (_, i) {
              final r = reciters[i];
              final isSelected = r.identifier == _selectedReciter?.identifier;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(r.name),
                subtitle: Text(r.englishName),
                onTap: () async {
                  await StorageService.setPreferredReciter(r.identifier);
                  setState(() => _selectedReciter = r);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'اختر القارئ',
            onPressed: _showRecitersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded),
            tooltip: 'تشغيل التلاوة',
            onPressed: _loading ? null : _playAudio,
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'حجم الخط',
            onSelected: _changeFontSize,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 20, child: Text('صغير')),
              PopupMenuItem(value: 26, child: Text('متوسط')),
              PopupMenuItem(value: 32, child: Text('كبير')),
              PopupMenuItem(value: 40, child: Text('كبير جداً')),
            ],
          ),
        ],
      ),
      body: _buildBody(scheme),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: scheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadAyahs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ayahs.isEmpty) {
      return const Center(child: Text('لا توجد آيات'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: <Widget>[
        // رأس السورة
        SoftCard(
          color: scheme.primaryContainer.withOpacity(.55),
          child: Column(
            children: <Widget>[
              Text(
                'سُورَةُ ${widget.surahName}',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_ayahs.length} آية',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // البسملة (ما عدا التوبة)
        if (widget.surahNumber != 9)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize - 4,
                height: 2,
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

        // نص السورة
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _ayahs.map((ayah) {
              final isMarked = StorageService.isBookmarked(
                  widget.surahNumber, ayah.numberInSurah);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 2.2,
                            color: scheme.onSurface,
                            fontFamily: 'sans',
                          ),
                          children: [
                            TextSpan(text: ayah.text),
                            TextSpan(
                              text: ' ۝${_toArabicDigits(ayah.numberInSurah)} ',
                              style: TextStyle(
                                fontSize: _fontSize - 4,
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          iconSize: 20,
                          icon: Icon(
                            isMarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isMarked ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          onPressed: () => _toggleBookmark(ayah),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}