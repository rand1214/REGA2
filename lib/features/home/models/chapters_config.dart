/// Hardcoded chapter configuration
/// Title, description, color, icon, and video title are all hardcoded
/// Only video_url and video_thumbnail_url come from database
class ChapterConfig {
  final int order;
  final String title;
  final String iconPath;
  final String color;
  final String description;
  final String videoTitle;

  const ChapterConfig({
    required this.order,
    required this.title,
    required this.iconPath,
    required this.color,
    required this.description,
    required this.videoTitle,
  });
}

/// Hardcoded data for all 12 chapters
class ChaptersConfig {
  static const List<ChapterConfig> chapters = [
    ChapterConfig(
      order: 1,
      title: 'پێناسەکان',
      iconPath: 'assets/icons/1.png',
      color: '#B7D63E',
      description: 'ئەم بەشە باسی پێناسە گشتییەکان و زاراوەکانی هاتووچۆ دەکات',
      videoTitle: 'وانەی یەکەم | پێناسەکان',
    ),
    ChapterConfig(
      order: 2,
      title: 'بنەما گشتییەکان',
      iconPath: 'assets/icons/2.png',
      color: '#F15A3C',
      description: 'ئەم بەشە باسی بنەما گشتییەکانی لێخوڕین و یاساکانی سەر ڕێگا دەکات',
      videoTitle: 'وانەی دووەم | بنەما گشتییەکان',
    ),
    ChapterConfig(
      order: 3,
      title: 'یاسای هاتوچۆ',
      iconPath: 'assets/icons/3.png',
      color: '#2FA7DF',
      description: 'ئەم بەشە باسی یاساکانی هاتووچۆ و ڕێساکانی سەر ڕێگا دەکات',
      videoTitle: 'وانەی سێیەم | یاسای هاتوچۆ',
    ),
    ChapterConfig(
      order: 4,
      title: 'هێما و کەرەستەکانی هاتوچۆ',
      iconPath: 'assets/icons/4.png',
      color: '#2F6EBB',
      description: 'ئەم بەشە باسی هێماکانی هاتووچۆ و کەرەستەکانی ڕێگا دەکات',
      videoTitle: 'وانەی چوارەم | هێما و کەرەستەکانی هاتوچۆ',
    ),
    ChapterConfig(
      order: 5,
      title: 'بەشەکانی ئۆتۆمبێل',
      iconPath: 'assets/icons/5.png',
      color: '#F4A640',
      description: 'ئەم بەشە باسی بەشەکانی ئۆتۆمبێل و کارکردنیان دەکات',
      videoTitle: 'وانەی پێنجەم | بەشەکانی ئۆتۆمبێل',
    ),
    ChapterConfig(
      order: 6,
      title: 'خۆ ئامادەکردن بۆ لێخوڕین',
      iconPath: 'assets/icons/6.png',
      color: '#E91E63',
      description: 'ئەم بەشە باسی خۆ ئامادەکردن بۆ لێخوڕین و پشکنینی ئۆتۆمبێل دەکات',
      videoTitle: 'وانەی شەشەم | خۆ ئامادەکردن بۆ لێخوڕین',
    ),
    ChapterConfig(
      order: 7,
      title: 'مانۆرکردن',
      iconPath: 'assets/icons/7.png',
      color: '#FF2C92',
      description: 'ئەم بەشە باسی مانۆرکردن و جوڵەکانی ئۆتۆمبێل دەکات',
      videoTitle: 'وانەی حەوتەم | مانۆرکردن',
    ),
    ChapterConfig(
      order: 8,
      title: 'بارودۆخی سەر ڕێگوبان',
      iconPath: 'assets/icons/8.png',
      color: '#F3C21F',
      description: 'ئەم بەشە باسی بارودۆخی جۆراوجۆری سەر ڕێگاکان دەکات',
      videoTitle: 'وانەی هەشتەم | بارودۆخی سەر ڕێگوبان',
    ),
    ChapterConfig(
      order: 9,
      title: 'هەلسەنگاندنی مەترسییەکان',
      iconPath: 'assets/icons/9.png',
      color: '#7B3FA0',
      description: 'ئەم بەشە باسی هەلسەنگاندنی مەترسییەکان و چۆنیەتی دوورکەوتنەوەیان دەکات',
      videoTitle: 'وانەی نۆیەم | هەلسەنگاندنی مەترسییەکان',
    ),
    ChapterConfig(
      order: 10,
      title: 'تەندروستی شوفێر',
      iconPath: 'assets/icons/10.png',
      color: '#20C6C2',
      description: 'ئەم بەشە باسی تەندروستی شوفێر، کاریگەری ماندووبوون و مادە هۆشبەر دەکات',
      videoTitle: 'وانەی دەیەم | تەندروستی شوفێر',
    ),
    ChapterConfig(
      order: 11,
      title: 'لێخوڕینی ژینگەپارێزانە',
      iconPath: 'assets/icons/11.png',
      color: '#3FB34F',
      description: 'ئەم بەشە باسی شێوازی لێخوڕینی ژینگەپارێز، کەمکردنەوەی سوتەمەنی و پاراستنی هەوا دەکات',
      videoTitle: 'وانەی یازدەیەم | لێخوڕینی ژینگەپارێزانە',
    ),
    ChapterConfig(
      order: 12,
      title: 'فریاگوزاری سەرەتایی',
      iconPath: 'assets/icons/12.png',
      color: '#E53935',
      description: 'ئەم بەشە باسی فریاگوزاری سەرەتایی، یارمەتیدانی بریندار و چارەسەری کاتی ڕووداو دەکات',
      videoTitle: 'وانەی دوازدەیەم | فریاگوزاری سەرەتایی',
    ),
  ];

  /// Get chapter config by order number
  static ChapterConfig? getByOrder(int order) {
    return chapters.where((c) => c.order == order).firstOrNull;
  }
}
