import 'package:url_launcher/url_launcher.dart';
import '../models/reciter.dart';

/// خدمة التلاوة الصوتية
/// تفتح رابط mp3 في التطبيق الافتراضي (VLC / مشغل الموسيقى)
class AudioService {

  /// تشغيل تلاوة سورة معينة
  /// [reciter] القارئ
  /// [surahNumber] رقم السورة (1-114)
  static Future<bool> playSurah(Reciter reciter, int surahNumber) async {
    final url = reciter.getAudioUrl(surahNumber);
    return _launchUrl(url);
  }

  /// تشغيل تلاوة آية محددة (إن كان المصدر يدعم ذلك)
  /// alquran.cloud يوفر التلاوة على مستوى السورة فقط
  static Future<bool> playAyah(Reciter reciter, int surahNumber) async {
    return playSurah(reciter, surahNumber);
  }

  /// فتح رابط mp3
  static Future<bool> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// التحقق من صحة رابط السورة
  static String getSurahAudioUrl(Reciter reciter, int surahNumber) {
    return reciter.getAudioUrl(surahNumber);
  }
}