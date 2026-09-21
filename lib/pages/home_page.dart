import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/quran_api.dart';
import '../theme.dart';
import 'reader_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.onGoToQuran}) : super(key: key);

  final VoidCallback? onGoToQuran;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  void _loadLastRead() {
    setState(() {
      _lastRead = StorageService.getLastRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: <Widget>[
            // رأس الصفحة
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text('السلام عليكم', style: TextStyle(fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                        'رفيقك مع القرآن',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  backgroundColor: Color(0xFFDCEFE6),
                  child: Icon(Icons.person_outline_rounded, color: Color(0xFF16745B)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // بطاقة "متابعة القراءة"
            _buildContinueCard(scheme),

            const SizedBox(height: 28),

            // اختصارات سريعة
            const SectionHeader(title: 'اختصارات سريعة'),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: QuickAction(
                    icon: Icons.menu_book_rounded,
                    title: 'المصحف',
                    color: scheme.primaryContainer,
                    onTap: () {
                      if (widget.onGoToQuran != null) widget.onGoToQuran!();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickAction(
                    icon: Icons.bookmark_rounded,
                    title: 'المحفوظات',
                    color: scheme.secondaryContainer,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('افتح تبويب المحفوظات من الشريط السفلي')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // آية اليوم
            const SectionHeader(title: 'آية اليوم'),
            const SizedBox(height: 12),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.8,
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('الرعد • ٢٨', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Icon(Icons.share_outlined, size: 20, color: scheme.primary),
                      const SizedBox(width: 16),
                      Icon(Icons.bookmark_border_rounded, size: 20, color: scheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueCard(ColorScheme scheme) {
    if (_lastRead == null) {
      // لا يوجد آخر قراءة
      return SoftCard(
        color: scheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.auto_awesome_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'ابدأ رحلتك',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'لم تبدأ القراءة بعد',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'افتح المصحف وابدأ من سورة الفاتحة',
              style: TextStyle(color: scheme.onPrimaryContainer.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReaderPage(surahNumber: 1, surahName: 'الفاتحة'),
                  ),
                ).then((_) => _loadLastRead());
              },
              child: const Text('ابدأ القراءة'),
            ),
          ],
        ),
      );
    }

    // يوجد آخر قراءة
    final surahNumber = _lastRead!['surahNumber'] as int? ?? 1;
    final surahName = _lastRead!['surahName'] as String? ?? 'الفاتحة';
    final ayahNumber = _lastRead!['ayahNumber'] as int? ?? 1;

    return SoftCard(
      color: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'مواصلة الورد',
                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'سورة $surahName',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الآية $ayahNumber',
            style: TextStyle(color: scheme.onPrimary.withOpacity(.75)),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderPage(
                    surahNumber: surahNumber,
                    surahName: surahName,
                  ),
                ),
              ).then((_) => _loadLastRead());
            },
            child: const Text('متابعة القراءة'),
          ),
        ],
      ),
    );
  }
}