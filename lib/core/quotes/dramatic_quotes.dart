import 'dart:math';

class DramaticQuotes {
  static final _random = Random.secure();

  /// Quotes shown when a player is assassinated at night
  static const List<String> nightKill = [
    'في جنح الظلام... سقط أحدهم',
    'القمر شاهد على جريمة الليلة...',
    'همسة واحدة كانت كافية لإنهاء حياة...',
    'الظلام لا يرحم... والمافيا لا تنسى',
    'ليلة أخرى... وضحية أخرى',
    'صوت خطوات في الظلام... ثم صمت مطبق',
    'لن يرى نور الصباح...',
    'الخيانة لها طعم الدم في هذه المدينة',
    'رصاصة واحدة في الظلام غيّرت كل شيء...',
    'النوم الأبدي يبدأ الآن...',
  ];

  /// Quotes shown when a player is voted out during the day
  static const List<String> dayElimination = [
    'العدالة تأخذ مجراها...',
    'صوت الأغلبية لا يُرَد',
    'الشعب قرر مصيرك اليوم',
    'المحكمة أصدرت حكمها النهائي',
    'لا مكان للمشتبه بهم في هذه المدينة',
    'أصابع الاتهام لا تكذب... أحياناً',
    'الحقيقة ستُكشف الآن...',
    'هل أقصيتم البريء أم المجرم؟',
    'القاضي نطق... والجمهور ينتظر',
    'لحظة الحقيقة حانت...',
  ];

  /// Quotes for mafia victory
  static const List<String> mafiaWin = [
    'الظلام انتصر... المافيا تحكم المدينة',
    'سقطت المدينة في قبضة المافيا',
    'الجريمة المنظمة لا تُهزَم',
    'المافيا: ١ - المدينة: ٠',
    'في النهاية... الأقوياء هم من يبقون',
  ];

  /// Quotes for citizens victory
  static const List<String> citizensWin = [
    'النور انتصر على الظلام!',
    'العدالة سادت... المدينة في أمان',
    'الشعب المتحد لا يُهزَم',
    'سقط آخر رجال المافيا...',
    'المدينة تتنفس الحرية من جديد!',
  ];

  /// Dramatic one-liners for suspense moments
  static const List<String> suspense = [
    '...',
    'انتظروا...',
    'الحقيقة صادمة...',
    'لن تصدقوا ما حدث...',
    'مفاجأة غير متوقعة!',
  ];

  static String getRandomNightKill() => nightKill[_random.nextInt(nightKill.length)];
  static String getRandomDayElimination() => dayElimination[_random.nextInt(dayElimination.length)];
  static String getRandomMafiaWin() => mafiaWin[_random.nextInt(mafiaWin.length)];
  static String getRandomCitizensWin() => citizensWin[_random.nextInt(citizensWin.length)];
  static String getRandomSuspense() => suspense[_random.nextInt(suspense.length)];
}
