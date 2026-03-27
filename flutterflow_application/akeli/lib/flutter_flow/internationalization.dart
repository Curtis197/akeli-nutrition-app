import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['fr', 'en', 'ar'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? frText = '',
    String? enText = '',
    String? arText = '',
  }) =>
      [frText, enText, arText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // HomePage
  {
    'd9cj8ct8': {
      'fr': 'Mettre à jour son poids',
      'ar': 'قم بتحديث وزنك',
      'en': 'Update your weight',
    },
    'h5sscsov': {
      'fr': 'Votre poids n\'est pas encore enregistré',
      'ar': 'لم يتم تسجيل وزنك بعد',
      'en': 'Your weight has not yet been recorded',
    },
    '13jea5qn': {
      'fr': 'Veuillez entrer vos paramètres',
      'ar': 'يرجى إدخال إعداداتك',
      'en': 'Please enter your settings',
    },
    'z1wbuu3i': {
      'fr': 'Commencer',
      'ar': 'للبدء',
      'en': 'To start',
    },
    '090sjsix': {
      'fr': 'Demandes',
      'ar': 'الطلبات',
      'en': 'Requests',
    },
    'bzuxe2gd': {
      'fr': 'Accepter',
      'ar': 'يقبل',
      'en': 'Accept',
    },
    'pgoayffi': {
      'fr': 'Vous n\'avez pas de repas plannifé aujourd\'hui.',
      'ar': 'ليس لديك أي وجبات مخططة لليوم.',
      'en': 'You have no meals planned for today.',
    },
    '7odrd5k3': {
      'fr': 'Voulez vous generer vos repas ?',
      'ar': 'هل ترغب في إعداد وجباتك بنفسك؟',
      'en': 'Do you want to generate your own meals?',
    },
    'g510diwv': {
      'fr': 'Générer mes repas',
      'ar': 'حضّر لي وجباتي',
      'en': 'Generate my meals',
    },
    '1bpa93ps': {
      'fr': 'Mes Repas du jours',
      'ar': 'وجباتي لهذا اليوم',
      'en': 'My Meals for Today',
    },
    'p2x3581d': {
      'fr': 'Liste de Course',
      'ar': 'قائمة التسوق',
      'en': 'Shopping List',
    },
    'pq5wsnty': {
      'fr': 'Voir toute la liste de coures',
      'ar': 'اطلع على القائمة الكاملة للسباقات',
      'en': 'See the full list of races',
    },
    's430144o': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    'cb0t2ua4': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    'ntl5oze7': {
      'fr': 'Déjà acheté',
      'ar': 'تم الشراء بالفعل',
      'en': 'Already bought',
    },
    'qaa19unc': {
      'fr': 'Reste à acheter',
      'ar': 'لم يتم الشراء بعد',
      'en': 'Still to buy',
    },
    'u2de4dv1': {
      'fr': 'Nombre d\'ingredient total',
      'ar': 'إجمالي عدد المكونات',
      'en': 'Total number of ingredients',
    },
    'bbuvb1dz': {
      'fr': 'Nombre d\'ingredient acheté',
      'ar': 'عدد المكونات المشتراة',
      'en': 'Number of ingredients purchased',
    },
    'dlvw8uyh': {
      'fr': 'Nombre d\'ingredient restant',
      'ar': 'عدد المكونات المتبقية',
      'en': 'Number of ingredients remaining',
    },
    'hzuuni1y': {
      'fr': 'Recettes recomandées',
      'ar': 'وصفات مُوصى بها',
      'en': 'Recommended recipes',
    },
    'v5u29a74': {
      'fr': 'Toutes les nouvelles recettes selectionnées pour vous',
      'ar': 'جميع الوصفات الجديدة المختارة خصيصاً لك',
      'en': 'All the new recipes selected for you',
    },
    '1xbzfxkr': {
      'fr': 'Partager vos recettes',
      'ar': 'شاركوا وصفاتكم',
      'en': 'Share your recipes',
    },
    '851wd1em': {
      'fr':
          'Vous avez des recettes qui pourrait bénéficier à d\'autres utiisateurs ? Cliquez sue le bouton ci-dessous ',
      'ar': 'هل لديك وصفات قد تفيد المستخدمين الآخرين؟ انقر على الزر أدناه.',
      'en':
          'Do you have recipes that could benefit other users? Click the button below.',
    },
    'f4hz2ksx': {
      'fr': 'Partager',
      'ar': 'يشارك',
      'en': 'Share',
    },
    '6jd45i9i': {
      'fr': 'Votre essai s\'est terminé. ',
      'ar': 'انتهت فترة محاكمتك.',
      'en': 'Your trial has ended.',
    },
    'zvnqqf2o': {
      'fr':
          'Veuillez mettre à jour votre profil de paiement pour continuer à utiliser ',
      'ar': 'يرجى تحديث ملف تعريف الدفع الخاص بك لمواصلة الاستخدام',
      'en': 'Please update your payment profile to continue using',
    },
    'k0e6gsw6': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Meal_Planner
  {
    'cl04x2vr': {
      'fr': 'Vos repas de la semaine',
      'ar': 'وجباتك لهذا الأسبوع',
      'en': 'Your meals for the week',
    },
    '5rldmbu0': {
      'fr': 'Voir mon plan diététique ',
      'ar': 'اطلع على خطة نظامي الغذائي',
      'en': 'See my diet plan',
    },
    'dceon80q': {
      'fr': 'Voir ma liste de course',
      'ar': 'اطلع على قائمة مشترياتي',
      'en': 'View my shopping list',
    },
    '68o033sa': {
      'fr': 'Ajouter une collation',
      'ar': 'أضف وجبة خفيفة',
      'en': 'Add a snack',
    },
    '475dc1mz': {
      'fr': 'Personnel',
      'ar': 'طاقم عمل',
      'en': 'Staff',
    },
    '3ms7q03k': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'hnihuquf': {
      'fr': 'Ajouter',
      'ar': 'يضيف',
      'en': 'Add',
    },
    '0hgx9my2': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'v34b5esi': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    '99cs2zvh': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    '0shhlh3t': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'b8ey029b': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'ngfqyk55': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    '07ejxbri': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'c6becdc8': {
      'fr': 'Voulez vous régénerer un plan ? ',
      'ar': 'هل تريد إعادة إنشاء خطة؟',
      'en': 'Do you want to regenerate a plan?',
    },
    'xuxcfl56': {
      'fr': 'Remplacez automatiquement les repas de votre plans ',
      'ar': 'استبدل الوجبات في خطتك تلقائيًا',
      'en': 'Automatically replace the meals in your plan',
    },
    'xtlhesge': {
      'fr': 'Regénérer',
      'ar': 'تجديد',
      'en': 'Regenerate',
    },
    'ki43302h': {
      'fr': 'Voulez voulez générer un plan de repas ? ',
      'ar': 'هل ترغب في إنشاء خطة وجبات؟',
      'en': 'Do you want to generate a meal plan?',
    },
    'hyfxi0sp': {
      'fr': 'Vos paramètre ne sont pas établis !',
      'ar': 'لم يتم ضبط إعداداتك!',
      'en': 'Your settings are not configured!',
    },
    'ot1igr1j': {
      'fr': 'Mettez à jour vos paramètre pour générer un plan.',
      'ar': 'قم بتحديث إعداداتك لإنشاء خطة.',
      'en': 'Update your settings to generate a plan.',
    },
    'zkyvc39s': {
      'fr': 'Mettre à jour ',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'ytin50xy': {
      'fr': 'Générez automatiquement vos repas de la semaine',
      'ar': 'قم بإنشاء وجباتك الأسبوعية تلقائيًا',
      'en': 'Automatically generate your weekly meals',
    },
    'yguvlsq9': {
      'fr': 'Générer',
      'ar': 'يولد',
      'en': 'Generate',
    },
    'lk60gdyq': {
      'fr': 'Votre plan n\'a pu être édité',
      'ar': 'لا يمكن تعديل خطتك',
      'en': 'Your plan could not be edited',
    },
    's5jhnbhj': {
      'fr': 'Si le problème persiste veuillez contacter nos services  .',
      'ar': 'إذا استمرت المشكلة، يرجى الاتصال بخدماتنا.',
      'en': 'If the problem persists, please contact our services.',
    },
    'choq4fx3': {
      'fr': 'Editer mon plan',
      'ar': 'تعديل خطتي',
      'en': 'Edit my plan',
    },
    'nmz0tedf': {
      'fr': 'Voir mon plan diététique ',
      'ar': 'اطلع على خطة نظامي الغذائي',
      'en': 'See my diet plan',
    },
    'lqhnjlb0': {
      'fr': 'Voir ma liste de course',
      'ar': 'اطلع على قائمة مشترياتي',
      'en': 'View my shopping list',
    },
    'tjuf76cn': {
      'fr': 'Ajouter une collation',
      'ar': 'أضف وجبة خفيفة',
      'en': 'Add a snack',
    },
    'r5wpapsq': {
      'fr': 'Personnel',
      'ar': 'طاقم عمل',
      'en': 'Staff',
    },
    '69n2sm50': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'gs7j53xh': {
      'fr': 'Ajouter',
      'ar': 'يضيف',
      'en': 'Add',
    },
    'uajeedv1': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'z2bvhb57': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'yl3juwow': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'p18m3vw8': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'nzfyg2m3': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'qw96xem7': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'xj1ezyo1': {
      'fr': 'Vous avez mangé tous les repas du jour',
      'ar': 'لقد تناولت جميع وجبات اليوم',
      'en': 'You ate all the meals for the day',
    },
    'c4pak5qd': {
      'fr': 'Voulez voulez générer un plan de repas ? ',
      'ar': 'هل ترغب في إنشاء خطة وجبات؟',
      'en': 'Do you want to generate a meal plan?',
    },
    'nd9jh8yp': {
      'fr':
          'Vous pouvez metrre à niveau votre abonnement afin de générer automatiquement vos repas de la semaine',
      'ar': 'يمكنك ترقية اشتراكك لتوليد وجباتك الأسبوعية تلقائيًا.',
      'en':
          'You can upgrade your subscription to automatically generate your weekly meals.',
    },
    'mum3vxjk': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'khe5tqol': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // MealDetail
  {
    'xztahgvw': {
      'fr': 'Vous avez consommé ce repas',
      'ar': 'لقد تناولت هذه الوجبة',
      'en': 'You have eaten this meal',
    },
    'zufe42bh': {
      'fr': 'h',
      'ar': 'ح',
      'en': 'h',
    },
    'abes477u': {
      'fr': 'min',
      'ar': 'مين',
      'en': 'min',
    },
    'cw9pb640': {
      'fr': 'Difficulté',
      'ar': 'صعوبة',
      'en': 'Difficulty',
    },
    'ooldw4qn': {
      'fr': 'Description',
      'ar': 'وصف',
      'en': 'Description',
    },
    'dlqsckpx': {
      'fr': 'Ingredients',
      'ar': 'مكونات',
      'en': 'Ingredients',
    },
    'cb2ewnic': {
      'fr': 'Etapes',
      'ar': 'خطوات',
      'en': 'Steps',
    },
    '8yz5uwlk': {
      'fr': 'Voulez-vous choisir une autre recette ?',
      'ar': 'هل ترغب في اختيار وصفة أخرى؟',
      'en': 'Would you like to choose another recipe?',
    },
    'le5ypw39': {
      'fr': 'Choisir',
      'ar': 'يختار',
      'en': 'Choose',
    },
    '6ttlc5wn': {
      'fr': 'Voulez choisir un repas personalisé ?',
      'ar': 'هل ترغب في اختيار وجبة مخصصة؟',
      'en': 'Would you like to choose a personalized meal?',
    },
    'hupvzg0m': {
      'fr': 'Personaliser',
      'ar': 'تخصيص',
      'en': 'Customize',
    },
    'imshmlea': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // ProfileSetting
  {
    'g0c4f2v3': {
      'fr': 'Se Deconnecter',
      'ar': 'تسجيل الخروج',
      'en': 'Log out',
    },
    'm83njzwr': {
      'fr': 'Option d\'abonnement',
      'ar': 'خيار الاشتراك',
      'en': 'Subscription option',
    },
    'dnseq8fj': {
      'fr': 'Information',
      'ar': 'معلومة',
      'en': 'Information',
    },
    '10ubwcec': {
      'fr': 'Parrainage',
      'ar': 'الرعاية',
      'en': 'Sponsorship',
    },
    '7h6natcp': {
      'fr': 'Edition du Profil',
      'ar': 'تعديل الملف الشخصي',
      'en': 'Profile Editing',
    },
    'o0oz5uuq': {
      'fr': 'Notifications',
      'ar': 'إشعارات',
      'en': 'Notifications',
    },
    'mernkkee': {
      'fr': 'Contact',
      'ar': 'اتصال',
      'en': 'Contact',
    },
    'm25zlylo': {
      'fr': 'Politique de Confidentialité',
      'ar': 'سياسة الخصوصية',
      'en': 'Privacy Policy',
    },
    '30oulzh2': {
      'fr': 'Condition générale d\'utilisation',
      'ar': 'الشروط العامة للاستخدام',
      'en': 'General terms of use',
    },
    'tci4py0d': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Notifications
  {
    'osw35r3x': {
      'fr': 'Notifications',
      'ar': 'إشعارات',
      'en': 'Notifications',
    },
    '8carg0m6': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // forgottenPassword
  {
    'na93frh5': {
      'fr': 'Back',
      'ar': 'خلف',
      'en': 'Back',
    },
    'btxdsq9t': {
      'fr': 'Forgot Password',
      'ar': 'هل نسيت كلمة السر',
      'en': 'Forgot Password',
    },
    'rpo75qrc': {
      'fr':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
      'ar':
          'سنرسل إليك بريدًا إلكترونيًا يحتوي على رابط لإعادة تعيين كلمة المرور الخاصة بك، يرجى إدخال البريد الإلكتروني المرتبط بحسابك أدناه.',
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
    },
    'vophzi6o': {
      'fr': 'Your email address...',
      'ar': 'عنوان بريدك  الإلكتروني...',
      'en': 'Your email address...',
    },
    'xmuh2ddf': {
      'fr': 'Enter your email...',
      'ar': 'أدخل بريدك الإلكتروني...',
      'en': 'Enter your email...',
    },
    '12zpbpgm': {
      'fr': 'Send Link',
      'ar': 'إرسال الرابط',
      'en': 'Send Link',
    },
    'uuad069h': {
      'fr': 'Back',
      'ar': 'خلف',
      'en': 'Back',
    },
    '8mkxueed': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Community
  {
    'uyyah338': {
      'fr': 'Conversation',
      'ar': 'محادثة',
      'en': 'Conversation',
    },
    'lvxyi5t9': {
      'fr': 'Chercher une conversation',
      'ar': 'أبحث عن محادثة',
      'en': 'Looking for a conversation',
    },
    'g0fg8k1m': {
      'fr': 'Demandes',
      'ar': 'الطلبات',
      'en': 'Requests',
    },
    'q06dyd9i': {
      'fr': 'Groupe',
      'ar': 'فرقة',
      'en': 'Band',
    },
    '4pi1cf09': {
      'fr': 'Chercher un groupe',
      'ar': 'ابحث عن مجموعة',
      'en': 'Search for a group',
    },
    '48gj8r1i': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    'zjezrq4w': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    'ciajqmj0': {
      'fr': 'Participant',
      'ar': 'المشارك',
      'en': 'Participant',
    },
    '7i518550': {
      'fr': 'Créer un groupe',
      'ar': 'إنشاء مجموعة',
      'en': 'Create a group',
    },
    '0hy8o68j': {
      'fr': 'Veuillez mettre à jour votre abonnement pour accéder au chat.',
      'ar': 'يرجى تحديث اشتراكك للوصول إلى الدردشة.',
      'en': 'Please update your subscription to access the chat.',
    },
    'cb3r2a11': {
      'fr': 'Metrre à jour',
      'ar': 'تحديث',
      'en': 'Update',
    },
    '0znnfdeb': {
      'fr': 'Discussion',
      'ar': 'مناقشة',
      'en': 'Discussion',
    },
    'c3lqecgy': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // chatPage
  {
    'i0f3xtwh': {
      'fr': '\n',
      'ar': '',
      'en': '',
    },
    'ht6v6b5x': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // group_page
  {
    'f9vtvdvu': {
      'fr': 'Description',
      'ar': 'وصف',
      'en': 'Description',
    },
    'oi59hdwy': {
      'fr': 'Demande envoyé',
      'ar': 'تم إرسال الطلب',
      'en': 'Request sent',
    },
    '0yank55w': {
      'fr': 'Annuler demande',
      'ar': 'إلغاء الطلب',
      'en': 'Cancel request',
    },
    '5d0vz9zc': {
      'fr': 'Rejoindre',
      'ar': 'ينضم',
      'en': 'Join',
    },
    'aqka5xzr': {
      'fr': 'Demandes',
      'ar': 'الطلبات',
      'en': 'Requests',
    },
    'ix51tm8n': {
      'fr': 'Participant',
      'ar': 'المشارك',
      'en': 'Participant',
    },
    'bzr8z9q5': {
      'fr': 'Admin',
      'ar': 'مسؤل',
      'en': 'Admin',
    },
    'p4mng5ff': {
      'fr': 'Quitter le groupe',
      'ar': 'غادر المجموعة',
      'en': 'Leave the group',
    },
    'f8fa1u6i': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // inscriptionpage
  {
    'nhzkn4h7': {
      'fr': 'Choisir sa langue',
      'ar': '',
      'en': '',
    },
    'tl91iaxi': {
      'fr': 'Search...',
      'ar': '',
      'en': '',
    },
    'e7xvju6p': {
      'fr': 'Option 1',
      'ar': '',
      'en': '',
    },
    'gtbriuer': {
      'fr': 'Option 2',
      'ar': '',
      'en': '',
    },
    'dpa4zllj': {
      'fr': 'Option 3',
      'ar': '',
      'en': '',
    },
    'lar6zazd': {
      'fr': 'Valider',
      'ar': '',
      'en': '',
    },
    'he7ipnb2': {
      'fr': ' AKELI',
      'ar': '',
      'en': '',
    },
    '82rmyn24': {
      'fr': 'Bienvenue dans votre application de nutrition africaine ',
      'ar': '',
      'en': '',
    },
    'o2eap095': {
      'fr': 'Avant de commencer, veuillez accepter nos conditions:',
      'ar': '',
      'en': '',
    },
    'e9g0ymec': {
      'fr': '📋 Consentement requis',
      'ar': '',
      'en': '',
    },
    '37cvgzql': {
      'fr': 'Données collectées',
      'ar': '',
      'en': '',
    },
    'jf869lk5': {
      'fr': '• Poids, taille, âge, objectifs',
      'ar': '',
      'en': '',
    },
    'cthaywn3': {
      'fr': '• Allergies et préférences',
      'ar': '',
      'en': '',
    },
    'aj4kd91h': {
      'fr': '• Historique de consommation',
      'ar': '',
      'en': '',
    },
    'tv59p1q8': {
      'fr': 'Vos droits',
      'ar': '',
      'en': '',
    },
    'yb1rfdcg': {
      'fr':
          'Accès, rectification, suppression de vos données à tout moment  dans Paramètres > Mes données ',
      'ar': '',
      'en': '',
    },
    '1g5ta959': {
      'fr': 'J\'accepte les conditions générales d\'utilisation (CGU)',
      'ar': '',
      'en': '',
    },
    'uv08ly5b': {
      'fr': 'Lire les CGU',
      'ar': '',
      'en': '',
    },
    'gyvm1pxf': {
      'fr':
          'J\'accepte la collecte de mes  données personnelles et de santé selon la Politique de  Confidentialité',
      'ar': '',
      'en': '',
    },
    'aei2e0rf': {
      'fr': 'Lire la politique de confidentialité',
      'ar': '',
      'en': '',
    },
    'vqlp29q3': {
      'fr': 'Confirmer',
      'ar': '',
      'en': '',
    },
    '5vmxd9ck': {
      'fr': 'Confirmer',
      'ar': '',
      'en': '',
    },
    '2kokfwtu': {
      'fr': 'Passer',
      'ar': 'يمر',
      'en': 'Pass',
    },
    'yn3kmsli': {
      'fr': 'Créons votre profil personnalisé',
      'ar': 'لنقم بإنشاء ملفك الشخصي',
      'en': 'Let\'s create your personalized profile',
    },
    '2j0orwa2': {
      'fr': 'Comment vous appelez-vous ?',
      'ar': 'ما اسمك؟',
      'en': 'What is your name?',
    },
    'oi0zaztk': {
      'fr': 'Quel âge avez-vous ? ',
      'ar': 'كم عمرك ؟',
      'en': 'How old are you ?',
    },
    '8xfdlvsv': {
      'fr': '(16-99 ans)',
      'ar': '(من 16 إلى 99 سنة)',
      'en': '(16-99 years old)',
    },
    '7ha933k8': {
      'fr': 'Quel âge avez-vous ? ',
      'ar': 'كم عمرك ؟',
      'en': 'How old are you ?',
    },
    'bry2kbgk': {
      'fr': 'Veuillez entrer un âge valide',
      'ar': 'يرجى إدخال عمر صحيح',
      'en': 'Please enter a valid age',
    },
    'z7wpameg': {
      'fr': 'Quel est votre sexe ?',
      'ar': 'ما هو جنسك؟',
      'en': 'What is your gender?',
    },
    '8icfuwog': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'xkdahfci': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    '5kn5xffh': {
      'fr': 'Masculin',
      'ar': 'ذكر',
      'en': 'Male',
    },
    '9wrvbcdn': {
      'fr': 'Femnin',
      'ar': 'أنثى',
      'en': 'Female',
    },
    'luzojo48': {
      'fr': 'Quel est votre poids actuel ?',
      'ar': 'ما هو وزنك الحالي؟',
      'en': 'What is your current weight?',
    },
    'db0y6r3x': {
      'fr': '( 12-300 kg)',
      'ar': '(12-300 كجم)',
      'en': '(12-300 kg)',
    },
    't4rut9ia': {
      'fr': 'Quel est votre poids actuel',
      'ar': 'ما هو وزنك الحالي؟',
      'en': 'What is your current weight?',
    },
    'amxodlqc': {
      'fr': 'Veuillez entrer un poids valide',
      'ar': 'يرجى إدخال وزن صحيح',
      'en': 'Please enter a valid weight',
    },
    '6ipn26ia': {
      'fr': 'Quel est votre taille ? ',
      'ar': 'ما هو طولك؟',
      'en': 'What is your height?',
    },
    'e8gk8v8m': {
      'fr': '(100-250 cm)',
      'ar': '(100-250 سم)',
      'en': '(100-250 cm)',
    },
    'g1mdght1': {
      'fr': 'Quel est votre taille',
      'ar': 'ما هو طولك؟',
      'en': 'What is your height?',
    },
    '3ibg0z94': {
      'fr': 'Veuillez une taille valide',
      'ar': 'يرجى تحديد مقاس مناسب.',
      'en': 'Please specify a valid size.',
    },
    'ezo51qo9': {
      'fr': 'Pratiquez vous une activité physique ?',
      'ar': 'هل تمارس أي نشاط بدني؟',
      'en': 'Do you engage in any physical activity?',
    },
    'kev7tao7': {
      'fr': 'Aucune (travail de bureau, peu de mouvement)',
      'ar': 'لا شيء (عمل مكتبي، حركة قليلة)',
      'en': 'None (office work, little movement)',
    },
    'ws3zyecb': {
      'fr': 'Légère (marche occasionnelle, 1-2x/semaine)',
      'ar': 'نشاط خفيف (مشي عرضي، مرة أو مرتين في الأسبوع)',
      'en': 'Light (occasional walking, 1-2 times/week)',
    },
    '9x0huzhw': {
      'fr': 'Moderé  (sport 3-4x/semaine)',
      'ar': 'معتدل (ممارسة الرياضة 3-4 مرات في الأسبوع)',
      'en': 'Moderate (sport 3-4 times/week)',
    },
    'v5ge8pwz': {
      'fr': 'Intensive  (sport quotidien, travail physique)',
      'ar': 'مكثف (رياضة يومية، عمل بدني)',
      'en': 'Intensive (daily sport, physical work)',
    },
    'cz1kocok': {
      'fr': 'Suivant',
      'ar': 'التالي',
      'en': 'Following',
    },
    '5fjc2t5b': {
      'fr': 'Passer',
      'ar': 'يمر',
      'en': 'Pass',
    },
    'i7vj4j8e': {
      'fr': 'Quels sont vos objectifs ?',
      'ar': 'ما هي أهدافك؟',
      'en': 'What are your objectives?',
    },
    'n965837p': {
      'fr': 'Le poids que vous voulez atteindre ?',
      'ar': 'ما هو الوزن الذي ترغب في الوصول إليه؟',
      'en': 'What weight do you want to reach?',
    },
    '9x2n0vse': {
      'fr': 'En combien de mois voulez vous atteindre votre objectif ?',
      'ar': 'في كم شهر تريد أن تحقق هدفك؟',
      'en': 'In how many months do you want to reach your goal?',
    },
    'qin5f6z4': {
      'fr': ' kg  par semaine',
      'ar': 'كيلوغرام أسبوعياً',
      'en': 'kg per week',
    },
    'vmlldh15': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'cvmenm08': {
      'fr': 'Quelles sont vos motivations ?',
      'ar': 'ما هي دوافعك؟',
      'en': 'What are your motivations?',
    },
    'kh24xh1h': {
      'fr': ' (Optionnel) ',
      'ar': '(خياري)',
      'en': '(Optional)',
    },
    'ajfpu9yk': {
      'fr': 'Quelles sont vos motivations ?',
      'ar': 'ما هي دوافعك؟',
      'en': 'What are your motivations?',
    },
    '686mlvxg': {
      'fr': 'Précédent',
      'ar': 'سابق',
      'en': 'Previous',
    },
    'i308jltg': {
      'fr': 'Suivant',
      'ar': 'التالي',
      'en': 'Following',
    },
    'zyxons5o': {
      'fr': 'Passer',
      'ar': '',
      'en': '',
    },
    'mvw5e17x': {
      'fr': 'Quelles sont vos preferences ?',
      'ar': '',
      'en': '',
    },
    'qp8i9vps': {
      'fr': 'Avez vous un régime particulier ?',
      'ar': '',
      'en': '',
    },
    'ewbnrij5': {
      'fr': 'Sans Porc',
      'ar': '',
      'en': '',
    },
    '2aqpygwy': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'vspogzfj': {
      'fr': 'SansViande',
      'ar': '',
      'en': '',
    },
    'ez7kxpma': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'yfx5lwkv': {
      'fr': 'Avez vous des allergies ?',
      'ar': '',
      'en': '',
    },
    'a7zvtqgk': {
      'fr': 'Entrez vos Allergies',
      'ar': '',
      'en': '',
    },
    'dgmo4htl': {
      'fr': 'Quelles est votre gastronomie préferé ?',
      'ar': '',
      'en': '',
    },
    'btso71n4': {
      'fr': 'Afrique du Nord',
      'ar': '',
      'en': '',
    },
    'bymmch4d': {
      'fr': 'Afrique de l\'Ouest',
      'ar': '',
      'en': '',
    },
    '5r5gp5wa': {
      'fr': 'Afrique Centrale',
      'ar': '',
      'en': '',
    },
    '0vvdxe8x': {
      'fr': 'Afrique de l\'Est',
      'ar': '',
      'en': '',
    },
    '8io4xemf': {
      'fr': 'Afrique du Sud ',
      'ar': '',
      'en': '',
    },
    '8e53rskx': {
      'fr': 'Carraïbes',
      'ar': '',
      'en': '',
    },
    'b6fgyti1': {
      'fr': 'Européenne',
      'ar': '',
      'en': '',
    },
    'r0v4oquy': {
      'fr': 'Optez vous pour un régime particulier ?',
      'ar': '',
      'en': '',
    },
    'hm5cilcu': {
      'fr': 'TextField',
      'ar': '',
      'en': '',
    },
    '73rtf2n1': {
      'fr': 'Précédent',
      'ar': '',
      'en': '',
    },
    'o2chqod0': {
      'fr': 'Confirmer',
      'ar': '',
      'en': '',
    },
    '5u14030o': {
      'fr': 'Récapitulatif',
      'ar': 'ملخص',
      'en': 'Summary',
    },
    'rh0jtp8h': {
      'fr':
          'Voici un résumé de votre personnalisé, basé sur vos objectifs et préférences.',
      'ar': 'إليك ملخص لخطة شخصية خاصة بك، بناءً على أهدافك وتفضيلاتك.',
      'en':
          'Here is a summary of your personalized plan, based on your goals and preferences.',
    },
    'h4w38k1n': {
      'fr': ' ',
      'ar': '',
      'en': '',
    },
    'kqubw5f2': {
      'fr': 'ans, ',
      'ar': 'سنين،',
      'en': 'years,',
    },
    '4we3oqo1': {
      'fr': 'cm, ',
      'ar': 'سم،',
      'en': 'cm,',
    },
    'ivpanw9w': {
      'fr': 'kg',
      'ar': 'كيلوغرام',
      'en': 'kg',
    },
    'kym10lr3': {
      'fr': 'Objectif de perte de poids',
      'ar': 'هدف إنقاص الوزن',
      'en': 'Weight loss goal',
    },
    '0x9p44v5': {
      'fr': 'Objectif de perte de poids',
      'ar': 'هدف إنقاص الوزن',
      'en': 'Weight loss goal',
    },
    'yhjd16r2': {
      'fr': 'Région préférée',
      'ar': 'المنطقة المفضلة',
      'en': 'Favorite region',
    },
    'ejc5qzei': {
      'fr': 'Régime particulier :',
      'ar': 'نظام خاص:',
      'en': 'Special regime:',
    },
    'gbbnyv1y': {
      'fr': 'Allergies',
      'ar': 'الحساسية',
      'en': 'Allergies',
    },
    'gl4nlqsa': {
      'fr': 'Aucune allergie',
      'ar': 'لا يسبب الحساسية',
      'en': 'No allergies',
    },
    'und7m0ec': {
      'fr': 'Niveau d\'activité',
      'ar': 'مستوى النشاط',
      'en': 'Activity level',
    },
    '1rvhy7a9': {
      'fr': 'Prévision journalière',
      'ar': 'التوقعات اليومية',
      'en': 'Daily forecast',
    },
    '89d4qqe5': {
      'fr': 'Petit-déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    'ahjo6kfn': {
      'fr': 'Déjeuner',
      'ar': 'غداء',
      'en': 'Lunch',
    },
    '7onvvs8d': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    'c29dvlvb': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    'vv44xci2': {
      'fr': 'Objectif diétetique',
      'ar': 'الهدف الغذائي',
      'en': 'Dietary objective',
    },
    'jcjo3hkk': {
      'fr': 'Résltat attendu',
      'ar': 'النتيجة المتوقعة',
      'en': 'Expected result',
    },
    '6qnewive': {
      'fr': 'par semaine',
      'ar': 'أسبوعياً',
      'en': 'per week',
    },
    'qk6sw0gx': {
      'fr': 'vers votre \nobjectif',
      'ar': 'نحو هدفك\n',
      'en': 'towards your\ngoal',
    },
    'gyrm93dp': {
      'fr': 'Génerer mes repas',
      'ar': 'حضّر لي وجباتي',
      'en': 'Generate my meals',
    },
    '2e3jtk2m': {
      'fr': 'Choisir mes repas',
      'ar': 'اختر وجباتي',
      'en': 'Choose my meals',
    },
    'amdb79wo': {
      'fr': 'Prédédent',
      'ar': 'سابق',
      'en': 'Previous',
    },
    'ou7lrnh4': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // CreateEditProfil
  {
    'misuydz4': {
      'fr': 'Ajouter une image',
      'ar': 'أضف صورة',
      'en': 'Add an image',
    },
    'pef23ihl': {
      'fr': 'Compte public',
      'ar': 'الحساب العام',
      'en': 'Public account',
    },
    '3dn8tgu4': {
      'fr':
          'Les autres utilisateeur pourront découvrir vos activités et intêrets',
      'ar': 'سيتمكن المستخدمون الآخرون من اكتشاف أنشطتك واهتماماتك.',
      'en':
          'Other users will be able to discover your activities and interests.',
    },
    'rmbc2021': {
      'fr': 'Changer de langue',
      'ar': '',
      'en': '',
    },
    'f23clzxu': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '3jtoyrcu': {
      'fr': 'Search...',
      'ar': '',
      'en': '',
    },
    'fxpfazcs': {
      'fr': 'Option 1',
      'ar': '',
      'en': '',
    },
    '0822uymb': {
      'fr': 'Option 2',
      'ar': '',
      'en': '',
    },
    'ywoyys7p': {
      'fr': 'Option 3',
      'ar': '',
      'en': '',
    },
    'xkt56bqi': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
    'iadrnyw6': {
      'fr': 'Créer / Mettre à jour mon profil',
      'ar': 'إنشاء / تحديث ملفي الشخصي',
      'en': 'Create / Update my profile',
    },
  },
  // EditInfo
  {
    '0nub1fzs': {
      'fr': 'Modifier vos informations',
      'ar': 'قم بتعديل معلوماتك',
      'en': 'Edit your information',
    },
    'iehln0m4': {
      'fr': 'Vos paramètre',
      'ar': 'إعداداتك',
      'en': 'Your settings',
    },
    'couux0mt': {
      'fr': 'Votre Âge',
      'ar': 'عمرك',
      'en': 'Your age',
    },
    'noixpe8m': {
      'fr': 'Votre poids',
      'ar': 'وزنك',
      'en': 'Your weight',
    },
    'wc2srh20': {
      'fr': 'Votre taile',
      'ar': 'نوعك',
      'en': 'Your size',
    },
    'waez8trg': {
      'fr': 'Votre sexe',
      'ar': 'جنسك',
      'en': 'Your sex',
    },
    'tkhpg57o': {
      'fr': 'Quel est votre sexe ?',
      'ar': 'ما هو جنسك؟',
      'en': 'What is your gender?',
    },
    '0lspioxx': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    'zk7t3fx4': {
      'fr': 'Masculin',
      'ar': 'ذكر',
      'en': 'Male',
    },
    'cs2ldnss': {
      'fr': 'Feminin',
      'ar': 'أنثى',
      'en': 'Female',
    },
    'kl4n7ywt': {
      'fr': 'Quel est votre sexe ?',
      'ar': 'ما هو جنسك؟',
      'en': 'What is your gender?',
    },
    '03g1s25q': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    'jzpawh2w': {
      'fr': 'Masculin',
      'ar': 'ذكر',
      'en': 'Male',
    },
    'ud66f5p7': {
      'fr': 'Feminin',
      'ar': 'أنثى',
      'en': 'Female',
    },
    't5qc6nkv': {
      'fr': 'Votre activité',
      'ar': 'نشاطك',
      'en': 'Your activity',
    },
    '78h8vdpz': {
      'fr': 'Quelle est votre niveau d\'activité ?',
      'ar': 'ما هو مستوى نشاطك؟',
      'en': 'What is your activity level?',
    },
    'axxjugjh': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    'kdx4xn61': {
      'fr': 'Faible',
      'ar': 'ضعيف',
      'en': 'Weak',
    },
    '7do46t8z': {
      'fr': 'Moderé',
      'ar': 'معتدل',
      'en': 'Moderate',
    },
    '63ao1gst': {
      'fr': 'Elevé',
      'ar': 'تلميذ',
      'en': 'Pupil',
    },
    'ulam7zoo': {
      'fr': 'Quelle est votre niveau d\'activité ?',
      'ar': 'ما هو مستوى نشاطك؟',
      'en': 'What is your activity level?',
    },
    'iq51bled': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    'bjwtrglp': {
      'fr': 'Faible',
      'ar': 'ضعيف',
      'en': 'Weak',
    },
    '1parq5ox': {
      'fr': 'Moderé',
      'ar': 'معتدل',
      'en': 'Moderate',
    },
    '0g0iri6x': {
      'fr': 'Elevé',
      'ar': 'تلميذ',
      'en': 'Pupil',
    },
    '5tyzamjm': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    '1qhdrd6x': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'p4qjl98r': {
      'fr': 'Préférences alimentaire',
      'ar': 'تفضيلات الطعام',
      'en': 'Food preferences',
    },
    '8lv5lu8j': {
      'fr': 'Régime',
      'ar': 'نظام عذائي',
      'en': 'Diet',
    },
    'ythun1y1': {
      'fr': 'Sans Viande',
      'ar': 'خالٍ من اللحوم',
      'en': 'Meat-Free',
    },
    'uhsv38ch': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'derhi30t': {
      'fr': 'Sans Porc',
      'ar': 'خالٍ من لحم الخنزير',
      'en': 'Pork-Free',
    },
    '4k82fzsm': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '7bs8lcvb': {
      'fr': 'Allergie',
      'ar': 'حساسية',
      'en': 'Allergy',
    },
    'wa0qtmok': {
      'fr': 'Ajouter une allergie',
      'ar': 'أضف حساسية',
      'en': 'Add an allergy',
    },
    'c5j5vybi': {
      'fr': 'Autres Allergies',
      'ar': 'أنواع الحساسية الأخرى',
      'en': 'Other Allergies',
    },
    '5imae4ru': {
      'fr': 'Région favorite',
      'ar': 'المنطقة المفضلة',
      'en': 'Favorite region',
    },
    '4m55f60x': {
      'fr': 'Afrique du nord',
      'ar': 'شمال أفريقيا',
      'en': 'North Africa',
    },
    'iz1sgvxc': {
      'fr': 'Afrique de l\'ouest',
      'ar': 'غرب أفريقيا',
      'en': 'West Africa',
    },
    'w4ih59zy': {
      'fr': 'Afrique de l\'est',
      'ar': 'شرق أفريقيا',
      'en': 'East Africa',
    },
    'qfeubxzj': {
      'fr': 'Afrique centrale',
      'ar': 'وسط أفريقيا',
      'en': 'Central Africa',
    },
    'xg8zkvy0': {
      'fr': 'Afrique du sud',
      'ar': 'جنوب أفريقيا',
      'en': 'South Africa',
    },
    'soq654ah': {
      'fr': 'Carraïbes',
      'ar': 'منطقة البحر الكاريبي',
      'en': 'Caribbean',
    },
    'wucepnci': {
      'fr': 'Occidentale',
      'ar': 'الغربي',
      'en': 'Western',
    },
    'e3pf1lek': {
      'fr': 'Autres',
      'ar': 'آحرون',
      'en': 'Others',
    },
    'yi00vg5j': {
      'fr': 'Regime particulier',
      'ar': 'نظام خاص',
      'en': 'Special regime',
    },
    '1qzuwb4q': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    '32rm9j8n': {
      'fr': 'Vos Objectifs',
      'ar': 'أهدافك',
      'en': 'Your Objectives',
    },
    'qwetd1jm': {
      'fr': 'Votre objectif de poids',
      'ar': 'هدفك في الوزن',
      'en': 'Your weight goal',
    },
    '2qdz3dis': {
      'fr': 'Temps de Régime',
      'ar': 'وقت الحمية',
      'en': 'Diet Time',
    },
    'afyjip4q': {
      'fr': 'en mois ',
      'ar': 'في غضون أشهر',
      'en': 'in months',
    },
    'dq6500vq': {
      'fr': 'Vos Objectifs',
      'ar': 'أهدافك',
      'en': 'Your Objectives',
    },
    'a54lhc47': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'fqp0xa4o': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'jfujxarf': {
      'fr': 'Votre plan',
      'ar': 'خطتك',
      'en': 'Your plan',
    },
    't4axudq6': {
      'fr':
          'Vous pouvez personnaliser votre plan calorique ou laisser l\'intelligence artificiel le calculer pour vous.',
      'ar':
          'يمكنك تخصيص خطة السعرات الحرارية الخاصة بك أو ترك الذكاء الاصطناعي يحسبها لك.',
      'en':
          'You can customize your calorie plan or let artificial intelligence calculate it for you.',
    },
    'dqseh8xo': {
      'fr': 'Vos calorie de la journéee',
      'ar': 'كمية السعرات الحرارية التي تتناولها يومياً',
      'en': 'Your daily calorie intake',
    },
    'ngm49cco': {
      'fr': 'Vos calorie du petit-déjeuner',
      'ar': 'سعراتك الحرارية في وجبة الإفطار',
      'en': 'Your breakfast calories',
    },
    '3cdofq0f': {
      'fr': 'Vos calorie du déjenuer',
      'ar': 'سعرات حرارية وجبة الغداء',
      'en': 'Your lunch calories',
    },
    'e5bpov0e': {
      'fr': 'Vos calorie du dîner',
      'ar': 'سعرات حرارية في وجبة العشاء',
      'en': 'Your dinner calories',
    },
    'di5zt0mo': {
      'fr': 'Vos calorie de la collation',
      'ar': 'سعراتك الحرارية في الوجبات الخفيفة',
      'en': 'Your snack calories',
    },
    'jzifkgfs': {
      'fr': 'Calorie prevue pour la journée',
      'ar': 'السعرات الحرارية المخططة لليوم',
      'en': 'Calories planned for the day',
    },
    '4pfupvos': {
      'fr': 'Total des calories de vos repas ',
      'ar': 'إجمالي السعرات الحرارية من وجباتك',
      'en': 'Total calories from your meals',
    },
    'd0454uz4': {
      'fr': 'Veuillez accorder les calories de votre journée:',
      'ar': 'يرجى تعديل كمية السعرات الحرارية التي تتناولها يومياً:',
      'en': 'Please adjust your daily calorie intake:',
    },
    'eav4ua34': {
      'fr':
          'le total des calorie de la journée doit être égale au calorie de la journée',
      'ar': 'يجب أن يساوي إجمالي السعرات الحرارية اليومية سعرات اليوم',
      'en': 'the total calories for the day must equal the calories of the day',
    },
    '5hfpn4hp': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    'd5abiyun': {
      'fr': 'Voulez vous générer un plan ?',
      'ar': 'هل ترغب في إنشاء خطة؟',
      'en': 'Do you want to generate a plan?',
    },
    'rszmdag7': {
      'fr': 'Générer',
      'ar': 'يولد',
      'en': 'Generate',
    },
  },
  // paymentSubscription
  {
    'o5bnz4hn': {
      'fr': 'Option d\'abonnement',
      'ar': 'خيار الاشتراك',
      'en': 'Subscription option',
    },
    'smquus6i': {
      'fr': 'Votre abonnement',
      'ar': 'اشتراكك',
      'en': 'Your subscription',
    },
    '5kvh9cs2': {
      'fr':
          'Vous bénéficiez d’un accès complet à tous nos contenus et services premium. Merci pour votre confiance !',
      'ar':
          'لديك حق الوصول الكامل إلى جميع محتوياتنا وخدماتنا المميزة. شكرًا لثقتكم!',
      'en':
          'You have full access to all our premium content and services. Thank you for your trust!',
    },
    'dmdbsqc0': {
      'fr': 'Supprimer mon compte',
      'ar': 'حذف حسابي',
      'en': 'Delete my account',
    },
    'xx5tsina': {
      'fr': 'Toutes vos données seront supprimeé et ne pourront être retrouvé.',
      'ar': 'سيتم حذف جميع بياناتك ولن يكون من الممكن استعادتها.',
      'en': 'All your data will be deleted and cannot be recovered.',
    },
    '52cvr7v2': {
      'fr': 'Annuler l\'abonnement',
      'ar': 'إلغاء الاشتراك',
      'en': 'Cancel subscription',
    },
    'b9uvp85d': {
      'fr':
          'Vous perdrez immédiatement l’accès à tous les contenus et fonctionnalités réservés aux abonnés.',
      'ar':
          'ستفقد فوراً إمكانية الوصول إلى جميع المحتويات والميزات المخصصة للمشتركين فقط.',
      'en':
          'You will immediately lose access to all subscriber-only content and features.',
    },
    'wsf1ss4a': {
      'fr': 'Annuler l\'abonnement',
      'ar': 'إلغاء الاشتراك',
      'en': 'Cancel subscription',
    },
    '73c19947': {
      'fr':
          'Vous perdrez immédiatement l’accès à tous les contenus et fonctionnalités réservés aux abonnés.',
      'ar':
          'ستفقد فوراً إمكانية الوصول إلى جميع المحتويات والميزات المخصصة للمشتركين فقط.',
      'en':
          'You will immediately lose access to all subscriber-only content and features.',
    },
    'xoxsooqi': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
    'hhe2rtty': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // support
  {
    'u0b5uoar': {
      'fr': 'Votre nom',
      'ar': 'اسمك',
      'en': 'Your name',
    },
    'aemifa3d': {
      'fr': 'Votre mail',
      'ar': 'بريدك الإلكتروني',
      'en': 'Your email',
    },
    'cn899t8h': {
      'fr': 'Faîtes nous part de votre question ',
      'ar': 'أخبرنا بسؤالك',
      'en': 'Tell us your question',
    },
    'hgq4tzlu': {
      'fr': 'Upload Screenshot',
      'ar': 'تحميل لقطة شاشة',
      'en': 'Upload Screenshot',
    },
    'oov4lhi2': {
      'fr': 'Envoyer',
      'ar': 'يرسل',
      'en': 'Send',
    },
    '4edtrxvh': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // userprofile
  {
    '4wmuze30': {
      'fr': 'Ajouter',
      'ar': 'يضيف',
      'en': 'Add',
    },
    'eo755sgt': {
      'fr': 'Ecrire',
      'ar': 'للكتابة',
      'en': 'To write',
    },
    'w887piq3': {
      'fr': 'Quitter la Conversation',
      'ar': 'اترك المحادثة',
      'en': 'Leave the Conversation',
    },
    '9zw207if': {
      'fr': 'demande envoyée',
      'ar': 'تم إرسال الطلب',
      'en': 'request sent',
    },
    'aem654dd': {
      'fr': 'Annuler',
      'ar': 'يلغي',
      'en': 'Cancel',
    },
    'tmvua8mq': {
      'fr': 'Ce compte est privé',
      'ar': 'هذا الحساب خاص.',
      'en': 'This account is private.',
    },
    'ilngfzyn': {
      'fr': 'Favoris',
      'ar': 'المفضلة',
      'en': 'Favorites',
    },
    'lwxq1ua9': {
      'fr': 'Groupe',
      'ar': 'فرقة',
      'en': 'Band',
    },
    'o4xoiw2j': {
      'fr': 'Commentaire',
      'ar': 'تعليق',
      'en': 'Comment',
    },
    'ym1mq0m8': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // dash
  {
    'jvg405lu': {
      'fr': 'Journalier',
      'ar': 'يوميًا',
      'en': 'Daily',
    },
    'q1x2kxr6': {
      'fr': ' Hebdomadaire',
      'ar': 'أسبوعي',
      'en': 'Weekly',
    },
    'r7qsxl1a': {
      'fr': 'Recapitulatif',
      'ar': 'ملخص',
      'en': 'Summary',
    },
    'exz0qysm': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // ShoppingList
  {
    'q99p94rw': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    'iqpr359j': {
      'fr': 'Tous',
      'ar': 'الجميع',
      'en': 'All',
    },
    '1tp8i2rp': {
      'fr': 'Déjà acheté',
      'ar': 'تم الشراء بالفعل',
      'en': 'Already bought',
    },
    'ypqzad28': {
      'fr': 'Reste à acheter',
      'ar': 'لم يتم الشراء بعد',
      'en': 'Still to buy',
    },
    'qvp74ehc': {
      'fr': 'Nombre d\'ingredient total',
      'ar': 'إجمالي عدد المكونات',
      'en': 'Total number of ingredients',
    },
    'lk9n5hwd': {
      'fr': 'Nombre d\'ingredient acheté',
      'ar': 'عدد المكونات المشتراة',
      'en': 'Number of ingredients purchased',
    },
    'f5leufvi': {
      'fr': 'Nombre d\'ingredient restant',
      'ar': 'عدد المكونات المتبقية',
      'en': 'Number of ingredients remaining',
    },
    '3w014cf2': {
      'fr': 'Liste de Course',
      'ar': 'قائمة التسوق',
      'en': 'Shopping List',
    },
    'mlyo5gzp': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // test
  {
    'icxodkgv': {
      'fr': 'Page Title',
      'ar': 'عنوان الصفحة',
      'en': 'Page Title',
    },
    'x1ymw2ud': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // dietPlan
  {
    'v6cci5ze': {
      'fr': 'Récapitulatif',
      'ar': 'ملخص',
      'en': 'Summary',
    },
    'b67u5109': {
      'fr':
          'Voici un résumé de votre personnalisé, basé sur vos objectifs et préférences.',
      'ar': 'إليك ملخص لخطة شخصية خاصة بك، بناءً على أهدافك وتفضيلاتك.',
      'en':
          'Here is a summary of your personalized plan, based on your goals and preferences.',
    },
    'ko58oap6': {
      'fr': 'Objectif de perte de poids',
      'ar': 'هدف إنقاص الوزن',
      'en': 'Weight loss goal',
    },
    'rto5006s': {
      'fr': 'Objectif diétetique',
      'ar': 'الهدف الغذائي',
      'en': 'Dietary objective',
    },
    'dzayg8mq': {
      'fr': 'Régime particulier :',
      'ar': 'نظام خاص:',
      'en': 'Special regime:',
    },
    'anlzmj2v': {
      'fr': 'Allergies',
      'ar': 'الحساسية',
      'en': 'Allergies',
    },
    'jq9t5ndo': {
      'fr': 'Aucune allergie',
      'ar': 'لا يسبب الحساسية',
      'en': 'No allergies',
    },
    'zhepuala': {
      'fr': 'Niveau d\'activité',
      'ar': 'مستوى النشاط',
      'en': 'Activity level',
    },
    'zpwm0q24': {
      'fr': 'Prévision journalière',
      'ar': 'التوقعات اليومية',
      'en': 'Daily forecast',
    },
    '78f09xbs': {
      'fr': 'Petit-déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    'wgptt1rd': {
      'fr': 'Déjeuner',
      'ar': 'غداء',
      'en': 'Lunch',
    },
    'jccem7jy': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    't5jpesjs': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    'mp9hoesm': {
      'fr': 'Résltat attendu',
      'ar': 'النتيجة المتوقعة',
      'en': 'Expected result',
    },
    'oq5m18pw': {
      'fr': 'par semaine',
      'ar': 'أسبوعياً',
      'en': 'per week',
    },
    'cnbill11': {
      'fr': 'vers votre \nobjectif',
      'ar': 'نحو هدفك\n',
      'en': 'towards your\ngoal',
    },
    '9g6ph9eo': {
      'fr': 'Génerer mon plan de  repas',
      'ar': 'قم بإنشاء خطة وجباتي',
      'en': 'Generate my meal plan',
    },
    'm1227lgq': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // referral
  {
    'ca63whto': {
      'fr': 'Créer un code de parrainage',
      'ar': 'إنشاء رمز إحالة',
      'en': 'Create a referral code',
    },
    'mty1edb6': {
      'fr':
          'L\'applicatino vous a plu ?  Vous voulez la partager ?  créer un code parrainage pour bénéficier des avantages liés aux partages',
      'ar':
          'هل أعجبك التطبيق؟ هل ترغب بمشاركته؟ أنشئ رمز إحالة للاستفادة من مزايا المشاركة.',
      'en':
          'Did you like the app? Want to share it? Create a referral code to benefit from sharing advantages.',
    },
    'dzqqwrg8': {
      'fr': 'Entrez votre nom',
      'ar': 'أدخل اسمك',
      'en': 'Enter your name',
    },
    'q2x7st7v': {
      'fr': 'Créer',
      'ar': 'يخلق',
      'en': 'Create',
    },
    'lyedb6n8': {
      'fr': 'Vous avez déja un code de parrainage ?',
      'ar': 'هل لديك رمز إحالة بالفعل؟',
      'en': 'Do you already have a referral code?',
    },
    'vnr9qhy2': {
      'fr': 'Entrez votre code',
      'ar': 'أدخل رمزك',
      'en': 'Enter your code',
    },
    'klu6cdpm': {
      'fr': 'Créer',
      'ar': 'يخلق',
      'en': 'Create',
    },
    'bp9kpf56': {
      'fr': 'Votre code de parrainage est le ',
      'ar': 'رمز الإحالة الخاص بك هو',
      'en': 'Your referral code is',
    },
    '9o0x0r7m': {
      'fr': 'Vous avez gagné ',
      'ar': 'لقد فزت',
      'en': 'You have won',
    },
    'evemua31': {
      'fr': 'Voulez vous identifier un parrain ?',
      'ar': 'هل ترغب في تحديد راعٍ؟',
      'en': 'Do you want to identify a sponsor?',
    },
    '21i75spw': {
      'fr': 'entrer le code de parrainage',
      'ar': 'أدخل رمز الإحالة',
      'en': 'Enter the referral code',
    },
    'qd2tayxg': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
    '248z7a6i': {
      'fr': 'Voulez vous changer de  parrain ?',
      'ar': 'هل ترغب في تغيير راعيك؟',
      'en': 'Do you want to change your sponsor?',
    },
    'bnncw6bd': {
      'fr': 'Ce code ne correspondà aucun parrain',
      'ar': 'هذا الرمز لا يرتبط بأي جهة راعية.',
      'en': 'This code does not correspond to any sponsor.',
    },
    'wf3snlm1': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // recipeResearchingList
  {
    'zncpa31e': {
      'fr': 'Rechercher votre recette',
      'ar': 'ابحث عن وصفتك',
      'en': 'Search for your recipe',
    },
    '2que1tta': {
      'fr': 'Recette',
      'ar': 'وصفة',
      'en': 'Recipe',
    },
    'b6bc1njn': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Notification_Setting
  {
    '2dr84bha': {
      'fr': 'Paratmètre de notification ',
      'ar': 'إعدادات الإشعارات',
      'en': 'Notification settings',
    },
    '23mertyi': {
      'fr': 'Push Notifications',
      'ar': 'الإشعارات الفورية',
      'en': 'Push Notifications',
    },
    '5eb40619': {
      'fr': 'Recevez vos notifications sur votre mobile',
      'ar': 'استقبل إشعاراتك على هاتفك المحمول',
      'en': 'Receive your notifications on your mobile',
    },
    'kee8p2he': {
      'fr': 'Chat Notifications',
      'ar': 'إشعارات الدردشة',
      'en': 'Chat Notifications',
    },
    '579idtgx': {
      'fr': 'Recevez les notifications de vos conversations',
      'ar': 'تلقَّ إشعارات بمحادثاتك',
      'en': 'Receive notifications for your conversations',
    },
    'z4xbx0b6': {
      'fr': 'Notification de Repas',
      'ar': 'إشعار الوجبات',
      'en': 'Meal Notification',
    },
    'l6gqumke': {
      'fr': 'Recevez les notifications de tous vos repas',
      'ar': 'تلقَّ إشعارات بجميع وجباتك',
      'en': 'Receive notifications for all your meals',
    },
    'ypm3wedc': {
      'fr': 'Notification de demande de conversation',
      'ar': 'إشعار طلب المحادثة',
      'en': 'Conversation request notification',
    },
    'w8bm04lx': {
      'fr':
          'Recevez vos notifications lorsqu\'un utilisateur souhaite discuter avec vous',
      'ar': 'تلقي إشعارات عندما يرغب أحد المستخدمين في الدردشة معك.',
      'en': 'Receive notifications when a user wants to chat with you.',
    },
    'nwp7nwfq': {
      'fr': 'Mettre à jour',
      'ar': 'للتحديث',
      'en': 'To update',
    },
    's86cn0a6': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // CGU
  {
    'hnd35u9j': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // RGPD
  {
    'p2bcdyai': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Condition
  {
    'xz5midn2': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    '7nhg71fl': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'lwza64gn': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    '4dsm8kxg': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'yjoqehr0': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'tguzh7ws': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'zmy7vjbq': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'm9kqwkqe': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'bmsnjz9n': {
      'fr': 'Hello World',
      'ar': 'مرحبا بالعالم',
      'en': 'Hello World',
    },
    'ootsd12p': {
      'fr': 'Button',
      'ar': 'زر',
      'en': 'Button',
    },
    '7qht4hds': {
      'fr': 'Button',
      'ar': 'زر',
      'en': 'Button',
    },
    'i3uzkxbw': {
      'fr': 'Page Title',
      'ar': 'عنوان الصفحة',
      'en': 'Page Title',
    },
    'oip72rh2': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // receipe_detail
  {
    '8kuo35db': {
      'fr': 'h',
      'ar': 'ح',
      'en': 'h',
    },
    'kc3u8q32': {
      'fr': 'min',
      'ar': 'مين',
      'en': 'min',
    },
    'grw4hb0g': {
      'fr': 'Difficulté',
      'ar': 'صعوبة',
      'en': 'Difficulty',
    },
    '85nnxxmo': {
      'fr': 'Petit-déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    '368nper7': {
      'fr': 'Déjeuner',
      'ar': 'غداء',
      'en': 'Lunch',
    },
    'f9exhd2b': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    'nkizrty4': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    '9l4evdaw': {
      'fr': 'Ajouter au calendrier',
      'ar': 'أضف إلى التقويم',
      'en': 'Add to calendar',
    },
    'fwz7jpsi': {
      'fr': 'Voir tous les avis',
      'ar': 'اطلع على جميع التقييمات',
      'en': 'See all reviews',
    },
    '2sc3ywz3': {
      'fr': 'Description',
      'ar': 'وصف',
      'en': 'Description',
    },
    'git9d3jy': {
      'fr': 'Ingredients',
      'ar': 'مكونات',
      'en': 'Ingredients',
    },
    'c5ad5xfg': {
      'fr': 'Etapes',
      'ar': 'خطوات',
      'en': 'Steps',
    },
    'ud73isfa': {
      'fr': 'Commentaire de la recette',
      'ar': 'تعليق على الوصفة',
      'en': 'Recipe comment',
    },
    'eppnyqqv': {
      'fr': 'Voir tous les commentaires',
      'ar': 'اطلع على جميع التعليقات',
      'en': 'See all comments',
    },
    '1cxvii8v': {
      'fr': 'Commenter',
      'ar': 'تعليق',
      'en': 'Comment',
    },
    'wcrumphv': {
      'fr': 'Ajouter au calendrier',
      'ar': 'أضف إلى التقويم',
      'en': 'Add to calendar',
    },
    'pxk07cw8': {
      'fr': 'créée par',
      'ar': 'تم إنشاؤه بواسطة',
      'en': 'created by',
    },
    '6bsluprv': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // Authentification
  {
    'n9yhwtqs': {
      'fr': 'AKELI',
      'ar': 'أكيلي',
      'en': 'AKELI',
    },
    '9moz4hxv': {
      'fr': 'Bienvenue sur Akeli',
      'ar': 'أهلا بكم في أكلي',
      'en': 'Welcome to Akeli',
    },
    'ow35nth5': {
      'fr': 'S\'inscrire',
      'ar': 'يسجل',
      'en': 'Register',
    },
    '30c8kwdg': {
      'fr': 'Se créer un compte',
      'ar': 'إنشاء حساب',
      'en': 'Create an account',
    },
    'gaerlz6u': {
      'fr':
          'Commencez avec Afrohealth inscrivez votre mail et votre mot de passe',
      'ar':
          'ابدأ استخدام Afrohealth عن طريق تسجيل بريدك الإلكتروني وكلمة المرور.',
      'en':
          'Get started with Afrohealth by registering your email and password.',
    },
    'zsuydexr': {
      'fr': 'Email',
      'ar': 'بريد إلكتروني',
      'en': 'E-mail',
    },
    'wp06asg8': {
      'fr': 'Mot de Passe',
      'ar': 'كلمة المرور',
      'en': 'Password',
    },
    'uokrome7': {
      'fr': 'Confirmer le mot de Passe',
      'ar': 'تأكيد كلمة المرور',
      'en': 'Confirm Password',
    },
    'rddvznp9': {
      'fr': 'Commencer',
      'ar': 'للبدء',
      'en': 'To start',
    },
    'zaqzr44o': {
      'fr': 'Se connecter',
      'ar': 'تسجيل الدخول',
      'en': 'Log in',
    },
    'm99dq9a9': {
      'fr': 'Heureux de vous revoir ! ',
      'ar': 'سعدت برؤيتك مجدداً!',
      'en': 'Glad to see you again!',
    },
    'ltadmuer': {
      'fr': 'Remplissez les information ci dessous pour acceder à votre compte',
      'ar': 'املأ المعلومات أدناه للوصول إلى حسابك',
      'en': 'Fill in the information below to access your account',
    },
    'k6mqo3sm': {
      'fr': 'Email',
      'ar': 'بريد إلكتروني',
      'en': 'E-mail',
    },
    '4xagb2vq': {
      'fr': 'Mot de pase',
      'ar': 'كلمة المرور',
      'en': 'Password',
    },
    'ww6d7vbh': {
      'fr': 'Se connecter',
      'ar': 'تسجيل الدخول',
      'en': 'Log in',
    },
    'auk2ir2x': {
      'fr': 'Mot de passe oublié ?',
      'ar': 'نسيت كلمة السر؟',
      'en': 'Forgot your password?',
    },
    'jxjg75q1': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // creator_profil
  {
    'dwzsludu': {
      'fr': 'Ajouter',
      'ar': 'يضيف',
      'en': 'Add',
    },
    't4xbmby1': {
      'fr': 'Ecrire',
      'ar': 'للكتابة',
      'en': 'To write',
    },
    '8znb9xtj': {
      'fr': 'Quitter la Conversation',
      'ar': 'اترك المحادثة',
      'en': 'Leave the Conversation',
    },
    'p933ymhj': {
      'fr': 'demande envoyée',
      'ar': 'تم إرسال الطلب',
      'en': 'request sent',
    },
    'e1dtgzj5': {
      'fr': 'Annuler',
      'ar': 'يلغي',
      'en': 'Cancel',
    },
    'vbfcu7ul': {
      'fr': 'Devenir fan',
      'ar': '',
      'en': '',
    },
    'ktlypgna': {
      'fr': 'Arrêter d\'être fan',
      'ar': '',
      'en': '',
    },
    'vh841g0i': {
      'fr': 'Recettes créées',
      'ar': 'المفضلة',
      'en': 'Favorites',
    },
    'ry9m29ut': {
      'fr': 'Groupe',
      'ar': 'فرقة',
      'en': 'Band',
    },
    'ml0wml6i': {
      'fr': 'Home',
      'ar': 'بيت',
      'en': 'Home',
    },
  },
  // WeightGraph
  {
    'na8hlggd': {
      'fr': 'Suivi du poids',
      'ar': 'تتبع الوزن',
      'en': 'Weight tracking',
    },
    'orjw4qyj': {
      'fr': 'Suivi de calorie',
      'ar': 'تتبع السعرات الحرارية',
      'en': 'Calorie tracking',
    },
  },
  // WeeklyProrgression
  {
    '35dzzy9o': {
      'fr': 'Calorie Hebdomadaire',
      'ar': 'السعرات الحرارية الأسبوعية',
      'en': 'Weekly Calories',
    },
  },
  // RecipeCard
  {
    'pbygxjxj': {
      'fr': '',
      'ar': '',
      'en': '',
    },
  },
  // comment_thread
  {
    'h2s0jdcf': {
      'fr': 'Comments',
      'ar': 'تعليقات',
      'en': 'Comments',
    },
  },
  // comment
  {
    'l4y9h9lb': {
      'fr': 'J\'aime',
      'ar': 'أحب',
      'en': 'I like',
    },
  },
  // addNewMeal
  {
    '0q2ehaqp': {
      'fr': 'Ajouter un repas au calendrier',
      'ar': 'أضف وجبة إلى التقويم',
      'en': 'Add a meal to the calendar',
    },
    'wm1vxvig': {
      'fr': 'Pour ce repas',
      'ar': 'لهذه الوجبة',
      'en': 'For this meal',
    },
    'i4uuxywb': {
      'fr': 'Modifier',
      'ar': 'لتعديل',
      'en': 'To modify',
    },
    '5i1fbrb6': {
      'fr': 'Pour un autre repas',
      'ar': 'لوجبة أخرى',
      'en': 'For another meal',
    },
    'yhq0ll6a': {
      'fr': 'Selectionner le type de repas',
      'ar': 'اختر نوع الوجبة',
      'en': 'Select the type of meal',
    },
    'dz9of5w3': {
      'fr': 'Search for an item...',
      'ar': 'ابحث عن عنصر...',
      'en': 'Search for an item...',
    },
    '8nexdmm4': {
      'fr': 'Petit-Déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    '647mfxo3': {
      'fr': 'Déjeuner',
      'ar': 'غداء',
      'en': 'Lunch',
    },
    '5irnl4va': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    'mnt1scsz': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    '65nj6akg': {
      'fr': 'Selectionner le jour du repas',
      'ar': 'اختر يوم الوجبة',
      'en': 'Select the day of the meal',
    },
    'weudt2tc': {
      'fr': 'Search for an item...',
      'ar': 'ابحث عن عنصر...',
      'en': 'Search for an item...',
    },
    'zon2xeru': {
      'fr': 'Lundi',
      'ar': 'الاثنين',
      'en': 'Monday',
    },
    'k1kkyv0s': {
      'fr': 'Mardi',
      'ar': 'يوم الثلاثاء',
      'en': 'Tuesday',
    },
    'fyqnfqqw': {
      'fr': 'Mercredi',
      'ar': 'الأربعاء',
      'en': 'Wednesday',
    },
    '5jb30544': {
      'fr': 'Jeudi',
      'ar': 'يوم الخميس',
      'en': 'THURSDAY',
    },
    'hops39aq': {
      'fr': 'Vendredi',
      'ar': 'جمعة',
      'en': 'Friday',
    },
    'y4e5nsaq': {
      'fr': 'Samedi',
      'ar': 'السبت',
      'en': 'SATURDAY',
    },
    'm81cdmwc': {
      'fr': 'Dimanche',
      'ar': 'الأحد',
      'en': 'Sunday',
    },
    '2ey4dlyv': {
      'fr': 'Valider',
      'ar': 'للتحقق',
      'en': 'To validate',
    },
  },
  // addMeal
  {
    '6n1e7cqn': {
      'fr': 'Dites nous ce que vous avez manger',
      'ar': 'أخبرنا ماذا أكلت',
      'en': 'Tell us what you ate',
    },
    'pq4rcykr': {
      'fr': 'Choisissez le jour',
      'ar': 'اختر اليوم',
      'en': 'Choose the day',
    },
    'ew5efjz7': {
      'fr': 'Search...',
      'ar': 'يبحث...',
      'en': 'Search...',
    },
    'rn8u7l0w': {
      'fr': 'Lundi',
      'ar': 'الاثنين',
      'en': 'Monday',
    },
    '4p4v2q72': {
      'fr': 'Mardi',
      'ar': 'يوم الثلاثاء',
      'en': 'Tuesday',
    },
    'le170mhw': {
      'fr': 'Mercredi',
      'ar': 'الأربعاء',
      'en': 'Wednesday',
    },
    'k5akgqvl': {
      'fr': 'Jeudi',
      'ar': 'يوم الخميس',
      'en': 'THURSDAY',
    },
    'r590ixfc': {
      'fr': 'Vendredi',
      'ar': 'جمعة',
      'en': 'Friday',
    },
    '1vt10hp7': {
      'fr': 'Samedi',
      'ar': 'السبت',
      'en': 'SATURDAY',
    },
    'rr7ersgx': {
      'fr': 'Dimanche',
      'ar': 'الأحد',
      'en': 'Sunday',
    },
    'pttwysxu': {
      'fr':
          'Pour avoir une meilleur estimation, décrivez votre repas le plus précisément possible.',
      'ar': 'للحصول على تقدير أفضل، صف وجبتك بأكبر قدر ممكن من الدقة.',
      'en':
          'To get a better estimate, describe your meal as precisely as possible.',
    },
    'v7gvf7rj': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // ai_chat
  {
    '3iia6rbs': {
      'fr': 'Moi',
      'ar': 'أنا',
      'en': 'Me',
    },
    'bxh5kwb8': {
      'fr': 'Assistant',
      'ar': 'مساعد',
      'en': 'Assistant',
    },
    'oo04a55j': {
      'fr': 'Votre assistant traite votre demande',
      'ar': 'يقوم مساعدك بمعالجة طلبك.',
      'en': 'Your assistant is processing your request.',
    },
  },
  // chat
  {
    '1be3s9co': {
      'fr': 'Moi',
      'ar': 'أنا',
      'en': 'Me',
    },
  },
  // ai_thread
  {
    'xrgsrj8p': {
      'fr': 'Poser une question',
      'ar': 'اطرح سؤالاً',
      'en': 'Ask a question',
    },
  },
  // group_creation
  {
    'gkv3bliq': {
      'fr': 'Créer un groupe de discussion',
      'ar': 'أنشئ مجموعة نقاش',
      'en': 'Create a discussion group',
    },
    'ro1wsbzh': {
      'fr': 'Nom du groupe',
      'ar': 'اسم المجموعة',
      'en': 'Group name',
    },
    'pv3f3ed9': {
      'fr': 'Description',
      'ar': 'وصف',
      'en': 'Description',
    },
    'pus8t8jk': {
      'fr': 'Description',
      'ar': 'وصف',
      'en': 'Description',
    },
    '3t1hunto': {
      'fr': 'Inserer un image',
      'ar': 'أدرج صورة',
      'en': 'Insert an image',
    },
    'lypytdug': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // add_comment
  {
    'ro2tza8n': {
      'fr': 'Noter vette recette',
      'ar': 'دوّن هذه الوصفة',
      'en': 'Note this recipe',
    },
    'un0bxrxa': {
      'fr': 'Mettre à jour votre avis',
      'ar': 'قم بتحديث تقييمك',
      'en': 'Update your review',
    },
    'p45emnzg': {
      'fr': 'Ajouter un commentaire',
      'ar': 'أضف تعليقًا',
      'en': 'Add a comment',
    },
    'hr8po884': {
      'fr': 'Partager',
      'ar': 'يشارك',
      'en': 'Share',
    },
    '0wxy6vgm': {
      'fr': 'Annuler',
      'ar': 'يلغي',
      'en': 'Cancel',
    },
  },
  // deleteGroup
  {
    'rq0hwdl2': {
      'fr': 'Voulez supprimer ce groupe ?',
      'ar': 'هل تريد حذف هذه المجموعة؟',
      'en': 'Do you want to delete this group?',
    },
    'b5udiufs': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // EditGroup
  {
    'zs7spafp': {
      'fr': 'Modifier les informations du groupe',
      'ar': 'تعديل معلومات المجموعة',
      'en': 'Edit group information',
    },
    'dwrf0wb3': {
      'fr': 'Modifier l\'image du groupe',
      'ar': 'قم بتغيير صورة المجموعة',
      'en': 'Change the group image',
    },
    'uyfywfle': {
      'fr': 'Modifier la description du groupe',
      'ar': 'قم بتعديل وصف المجموعة',
      'en': 'Edit the group description',
    },
    'yugvwsm0': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // DailyProgression
  {
    '00gghudg': {
      'fr': 'Calorie Journalière',
      'ar': 'السعرات الحرارية اليومية',
      'en': 'Daily Calories',
    },
  },
  // dailyRecap
  {
    'td2wczl5': {
      'fr': 'Calories',
      'ar': 'سعرات حرارية',
      'en': 'Calories',
    },
    'wdxy35vu': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '7vy61yet': {
      'fr': 'Protéines',
      'ar': 'البروتينات',
      'en': 'Proteins',
    },
    'vb4u8v8x': {
      'fr': 'Glucides',
      'ar': 'الكربوهيدرات',
      'en': 'Carbohydrates',
    },
    'ao3gfjnc': {
      'fr': 'Lipides',
      'ar': 'الدهون',
      'en': 'Lipids',
    },
    'bwie0wpd': {
      'fr': 'Inventaire des Repas',
      'ar': 'قائمة جرد الوجبات',
      'en': 'Meal Inventory',
    },
    'vbpgt57i': {
      'fr': 'Repas Plannifiés',
      'ar': 'الوجبات المخططة',
      'en': 'Planned Meals',
    },
    'vydpqu3p': {
      'fr': 'Repas Consommés',
      'ar': 'الوجبات المستهلكة',
      'en': 'Meals Consumed',
    },
  },
  // dailyRecapCopy
  {
    'pzx2zaax': {
      'fr': 'Calories',
      'ar': 'سعرات حرارية',
      'en': 'Calories',
    },
    'emsz3m9r': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '3ebcb5h6': {
      'fr': 'Protéine',
      'ar': 'بروتين',
      'en': 'Protein',
    },
    'xyt9mpo8': {
      'fr': 'Glucides',
      'ar': 'الكربوهيدرات',
      'en': 'Carbohydrates',
    },
    'tvtrwpvg': {
      'fr': 'Lipides',
      'ar': 'الدهون',
      'en': 'Lipids',
    },
    's6kgr9dh': {
      'fr': 'Invengtaire des repas',
      'ar': 'مخترع الوجبات',
      'en': 'Invenger of meals',
    },
    'anw3tz1u': {
      'fr': 'Repas plannifiés',
      'ar': 'وجبات مُخططة',
      'en': 'Planned meals',
    },
    'f4u3we7a': {
      'fr': '3',
      'ar': '3',
      'en': '3',
    },
    'yh6735ks': {
      'fr': 'Repas Consommés',
      'ar': 'الوجبات المستهلكة',
      'en': 'Meals Consumed',
    },
    'hlgpe1uj': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
  },
  // weeklyrecap
  {
    'i0okryhz': {
      'fr': 'Calories',
      'ar': 'سعرات حرارية',
      'en': 'Calories',
    },
    'idfsp3iz': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'ldpev96j': {
      'fr': 'Protein',
      'ar': 'بروتين',
      'en': 'Protein',
    },
    'vnn3s823': {
      'fr': 'Carbs',
      'ar': 'الكربوهيدرات',
      'en': 'Carbs',
    },
    'd31agzig': {
      'fr': 'Fat',
      'ar': 'سمين',
      'en': 'Fat',
    },
  },
  // dec
  {
    'n1ut21ud': {
      'fr': 'Min. Calorie',
      'ar': 'الحد الأدنى من السعرات الحرارية',
      'en': 'Minimum Calories',
    },
    'o7rt8tzn': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'p478q3ne': {
      'fr': 'Max. Calorie',
      'ar': 'الحد الأقصى للسعرات الحرارية',
      'en': 'Max. Calories',
    },
    '0eisqq1n': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'zivza4he': {
      'fr': 'Type',
      'ar': 'عطوف',
      'en': 'Kind',
    },
    'akdp4zve': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    '1lbxhq9r': {
      'fr': 'Sans Porc',
      'ar': 'خالٍ من لحم الخنزير',
      'en': 'Pork-Free',
    },
  },
  // weeklyInt
  {
    'dh7vr5f3': {
      'fr': 'Recapitulatif des repas',
      'ar': 'ملخص الوجبة',
      'en': 'Meal summary',
    },
    'xe44yaws': {
      'fr': 'Jour',
      'ar': 'يوم',
      'en': 'Day',
    },
    'o1swcwvh': {
      'fr': 'Lundi',
      'ar': 'الاثنين',
      'en': 'Monday',
    },
    'qasu99ge': {
      'fr': 'Mardi',
      'ar': 'يوم الثلاثاء',
      'en': 'Tuesday',
    },
    'l6xpf4q0': {
      'fr': 'Mercredi',
      'ar': 'الأربعاء',
      'en': 'Wednesday',
    },
    '93mutzfs': {
      'fr': 'Jeudi',
      'ar': 'يوم الخميس',
      'en': 'THURSDAY',
    },
    'ntujzje1': {
      'fr': 'Vendredi',
      'ar': 'جمعة',
      'en': 'Friday',
    },
    '1ww16a7q': {
      'fr': 'Samedi',
      'ar': 'السبت',
      'en': 'SATURDAY',
    },
    '16joj9ny': {
      'fr': 'Dimanche',
      'ar': 'الأحد',
      'en': 'Sunday',
    },
    '6n336du7': {
      'fr': 'plannifé',
      'ar': 'مخطط',
      'en': 'planned',
    },
    'ln2pt50b': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'ogb1cm9k': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'yjbmehfc': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'ywqif7d2': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'jov1bztv': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    '576j7hoe': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    '42yl2a31': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'mok6sxsf': {
      'fr': 'consommé',
      'ar': 'يستهلك',
      'en': 'consumes',
    },
    'g56gr985': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    '2lrgdf09': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    '6iez4nt2': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'cnl31dco': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'tgphz45y': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'ifryxqj9': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
    'affrvdjt': {
      'fr': '0',
      'ar': '0',
      'en': '0',
    },
  },
  // weeklyrecapCopy
  {
    'mt5fs1ze': {
      'fr': 'Calories',
      'ar': 'سعرات حرارية',
      'en': 'Calories',
    },
    'g1hrb7dv': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'g4cu448u': {
      'fr': 'Protéine',
      'ar': 'بروتين',
      'en': 'Protein',
    },
    '12rn7yat': {
      'fr': 'Glucides',
      'ar': 'الكربوهيدرات',
      'en': 'Carbohydrates',
    },
    'vxb4gk2l': {
      'fr': 'Lipides',
      'ar': 'الدهون',
      'en': 'Lipids',
    },
  },
  // conversationMessage
  {
    'oi2my8f7': {
      'fr': 'Ajouter',
      'ar': 'يضيف',
      'en': 'Add',
    },
    '93hblve8': {
      'fr': 'Ecrire',
      'ar': 'للكتابة',
      'en': 'To write',
    },
  },
  // weeklyIntCopy
  {
    'znjl2br9': {
      'fr': 'Recapitulatif des repas',
      'ar': 'ملخص الوجبة',
      'en': 'Meal summary',
    },
    'blab8chq': {
      'fr': 'Jour',
      'ar': 'يوم',
      'en': 'Day',
    },
    'ml4tr9uo': {
      'fr': 'plannifé',
      'ar': 'مخطط',
      'en': 'planned',
    },
    '66xgger2': {
      'fr': 'consommé',
      'ar': 'يستهلك',
      'en': 'consumes',
    },
  },
  // similarReceipe
  {
    'mcxjkote': {
      'fr': 'Recette similaire',
      'ar': 'وصفة مماثلة',
      'en': 'Similar recipe',
    },
    'x3xlh7ts': {
      'fr': 'Option 1',
      'ar': 'الخيار 1',
      'en': 'Option 1',
    },
    'prmhw2qs': {
      'fr': 'Option 2',
      'ar': 'الخيار الثاني',
      'en': 'Option 2',
    },
    'wdmwg84v': {
      'fr': 'Option 3',
      'ar': 'الخيار 3',
      'en': 'Option 3',
    },
  },
  // addSnack
  {
    'pcxqq97s': {
      'fr': 'Quelle collation avez vous pris ? ',
      'ar': 'ما هي الوجبة الخفيفة التي تناولتها؟',
      'en': 'What snack did you have?',
    },
    'xd36t2wv': {
      'fr': 'Selectionner le jour du repas',
      'ar': 'اختر يوم الوجبة',
      'en': 'Select the day of the meal',
    },
    '3hoyhhcu': {
      'fr': 'Search for an item...',
      'ar': 'ابحث عن عنصر...',
      'en': 'Search for an item...',
    },
    'tr0vvvbd': {
      'fr': 'Lundi',
      'ar': 'الاثنين',
      'en': 'Monday',
    },
    'ng3berj7': {
      'fr': 'Mardi',
      'ar': 'يوم الثلاثاء',
      'en': 'Tuesday',
    },
    'pco2ng6j': {
      'fr': 'Mercredi',
      'ar': 'الأربعاء',
      'en': 'Wednesday',
    },
    'a75r6nke': {
      'fr': 'Jeudi',
      'ar': 'يوم الخميس',
      'en': 'THURSDAY',
    },
    'oycf1gk2': {
      'fr': 'Vendredi',
      'ar': 'جمعة',
      'en': 'Friday',
    },
    'gwvmwbuk': {
      'fr': 'Samedi',
      'ar': 'السبت',
      'en': 'SATURDAY',
    },
    'i7tcmbzl': {
      'fr': 'Dimanche',
      'ar': 'الأحد',
      'en': 'Sunday',
    },
    '4x6uamjt': {
      'fr': 'Décrivez votre collation le plus précisément possible.',
      'ar': 'صف وجبتك الخفيفة بأكبر قدر ممكن من الدقة.',
      'en': 'Describe your snack as precisely as possible.',
    },
    'swd6e5bq': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // errorComp
  {
    '8awx5h2q': {
      'fr': 'Error',
      'ar': 'خطأ',
      'en': 'Error',
    },
  },
  // dailyRecapvView
  {
    'pwu961mk': {
      'fr': 'Lundi 01 septembre',
      'ar': 'الاثنين، 1 سبتمبر',
      'en': 'Monday, September 1st',
    },
    'rqbg7ru9': {
      'fr': 'Calories',
      'ar': 'سعرات حرارية',
      'en': 'Calories',
    },
    'n709t9ep': {
      'fr': '400 kcal  / 3000 kcal',
      'ar': '400 سعر حراري / 3000 سعر حراري',
      'en': '400 kcal / 3000 kcal',
    },
    '6jxomk3e': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'esmnarjl': {
      'fr': 'Protéine',
      'ar': 'بروتين',
      'en': 'Protein',
    },
    '3xoj4kzr': {
      'fr': 'Glucides',
      'ar': 'الكربوهيدرات',
      'en': 'Carbohydrates',
    },
    'igm54de1': {
      'fr': 'Lipides',
      'ar': 'الدهون',
      'en': 'Lipids',
    },
    'yppg6sg2': {
      'fr': 'Invengtaire des repas',
      'ar': 'مخترع الوجبات',
      'en': 'Invenger of meals',
    },
    '3mni6yxh': {
      'fr': 'Repas plannifiés',
      'ar': 'وجبات مُخططة',
      'en': 'Planned meals',
    },
    'etevp2f8': {
      'fr': '3',
      'ar': '3',
      'en': '3',
    },
    '17yl1b3q': {
      'fr': 'Repas Consommés',
      'ar': 'الوجبات المستهلكة',
      'en': 'Meals Consumed',
    },
    'ejw5xple': {
      'fr': '1',
      'ar': '1',
      'en': '1',
    },
  },
  // recipe_filters
  {
    'f2vyyuvx': {
      'fr': 'Calorie',
      'ar': 'سعرات حرارية',
      'en': 'Calorie',
    },
    '6ceeyr6t': {
      'fr': 'calorie min.',
      'ar': 'الحد الأدنى من السعرات الحرارية',
      'en': 'minimum calorie',
    },
    'jql5tapw': {
      'fr': 'calorie max.',
      'ar': 'الحد الأقصى للسعرات الحرارية',
      'en': 'max calorie',
    },
    'awoy679p': {
      'fr': 'Sans Porc',
      'ar': 'خالٍ من لحم الخنزير',
      'en': 'Pork-Free',
    },
    '3mid58he': {
      'fr': 'Type de Repas',
      'ar': 'نوع الوجبة',
      'en': 'Meal Type',
    },
    'tpmj760o': {
      'fr': 'Petit-Déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    'v19zll9j': {
      'fr': 'Déjuener',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    'wspevgzz': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    'wt9wuxj6': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    'dxhkj962': {
      'fr': 'Difficulté',
      'ar': 'صعوبة',
      'en': 'Difficulty',
    },
    'zlu0zf1s': {
      'fr': 'Facile',
      'ar': 'سهل',
      'en': 'Easy',
    },
    'qn1hrs39': {
      'fr': 'Modéré',
      'ar': 'معتدل',
      'en': 'Moderate',
    },
    'jx8kio5s': {
      'fr': 'Difficile',
      'ar': 'صعب',
      'en': 'Difficult',
    },
    'xbyu6dec': {
      'fr': 'Région Culinaire',
      'ar': 'منطقة الطهي',
      'en': 'Culinary Region',
    },
    '0ve7usj0': {
      'fr': 'Option 1',
      'ar': 'الخيار 1',
      'en': 'Option 1',
    },
    'joif78hj': {
      'fr': 'Option 2',
      'ar': 'الخيار الثاني',
      'en': 'Option 2',
    },
    'q2o2zcl0': {
      'fr': 'Option 3',
      'ar': 'الخيار 3',
      'en': 'Option 3',
    },
    '21cda8e5': {
      'fr': 'Temps de préparation',
      'ar': 'وقت التحضير',
      'en': 'Preparation time',
    },
    '0myb12la': {
      'fr': 'h',
      'ar': 'ح',
      'en': 'h',
    },
    'ppxzq2fz': {
      'fr': 'min ',
      'ar': 'مين',
      'en': 'min',
    },
    're50vt5y': {
      'fr': 'Button',
      'ar': 'زر',
      'en': 'Button',
    },
  },
  // TypeAndOr
  {
    '97h5r305': {
      'fr': 'ET',
      'ar': 'و',
      'en': 'AND',
    },
    'uy9u9bjc': {
      'fr': 'OU',
      'ar': 'أو',
      'en': 'OR',
    },
    '6j95vnrm': {
      'fr': 'ET',
      'ar': 'و',
      'en': 'AND',
    },
    'pu865j5h': {
      'fr': 'OU',
      'ar': 'أو',
      'en': 'OR',
    },
  },
  // TagAndOr
  {
    'ymvujyaz': {
      'fr': 'ET',
      'ar': 'و',
      'en': 'AND',
    },
    'n6rzoxn1': {
      'fr': 'OU',
      'ar': 'أو',
      'en': 'OR',
    },
    '2h7sza7b': {
      'fr': 'ET',
      'ar': 'و',
      'en': 'AND',
    },
    'zorl14ub': {
      'fr': 'OU',
      'ar': 'أو',
      'en': 'OR',
    },
  },
  // orederingSelector
  {
    'gdb9uvlk': {
      'fr': 'Les plus aimées',
      'ar': 'الأكثر حباً',
      'en': 'The most loved',
    },
    '1b8ad1zo': {
      'fr': 'Les plus commentées',
      'ar': 'الأكثر تعليقًا',
      'en': 'The most commented on',
    },
    'c3wdjms8': {
      'fr': 'Les plus consomées',
      'ar': 'الأكثر استهلاكاً',
      'en': 'The most consumed',
    },
    'phmtmqye': {
      'fr': 'Les plus aimées',
      'ar': 'الأكثر حباً',
      'en': 'The most loved',
    },
    'nrx9pbf2': {
      'fr': 'Les plus commentées',
      'ar': 'الأكثر تعليقًا',
      'en': 'The most commented on',
    },
    '3hfvnhg1': {
      'fr': 'Les plus consomées',
      'ar': 'الأكثر استهلاكاً',
      'en': 'The most consumed',
    },
    'u7ihq4ji': {
      'fr': 'Les plus aimées',
      'ar': 'الأكثر حباً',
      'en': 'The most loved',
    },
    'uq73ac7d': {
      'fr': 'Les plus commentées',
      'ar': 'الأكثر تعليقًا',
      'en': 'The most commented on',
    },
    'bwqm26i2': {
      'fr': 'Les plus consomées',
      'ar': 'الأكثر استهلاكاً',
      'en': 'The most consumed',
    },
    'l4lvetgn': {
      'fr': 'Les plus aimées',
      'ar': 'الأكثر حباً',
      'en': 'The most loved',
    },
    'h9upxskk': {
      'fr': 'Les plus commentées',
      'ar': 'الأكثر تعليقًا',
      'en': 'The most commented on',
    },
    'oif3bq15': {
      'fr': 'Les plus consomées',
      'ar': 'الأكثر استهلاكاً',
      'en': 'The most consumed',
    },
  },
  // RecipeCardJSONCopy
  {
    '4sxujsvr': {
      'fr': ' kcal',
      'ar': 'سعرات حرارية',
      'en': 'kcal',
    },
    'r5edujhj': {
      'fr': ' || ',
      'ar': '||',
      'en': '||',
    },
    '1qlxqfck': {
      'fr': ' h ',
      'ar': 'ح',
      'en': 'h',
    },
    '7ve6xmmk': {
      'fr': ' min',
      'ar': 'مين',
      'en': 'min',
    },
    'bhip5886': {
      'fr': '',
      'ar': '',
      'en': '',
    },
  },
  // recipe_filtersCopy
  {
    'cfsr2iy0': {
      'fr': 'Calorie',
      'ar': 'سعرات حرارية',
      'en': 'Calorie',
    },
    '65x6pxwa': {
      'fr': 'calorie min.',
      'ar': 'الحد الأدنى من السعرات الحرارية',
      'en': 'minimum calorie',
    },
    '0shsh5kp': {
      'fr': 'calorie max.',
      'ar': 'الحد الأقصى للسعرات الحرارية',
      'en': 'max calorie',
    },
    'o0xh9qto': {
      'fr': 'Sans Porc',
      'ar': 'خالٍ من لحم الخنزير',
      'en': 'Pork-Free',
    },
    '5lj3nj8w': {
      'fr': 'Type de Repas',
      'ar': 'نوع الوجبة',
      'en': 'Meal Type',
    },
    'wrdbt1zs': {
      'fr': 'Petit-Déjeuner',
      'ar': 'إفطار',
      'en': 'Breakfast',
    },
    'rrukj81q': {
      'fr': 'Déjeuner',
      'ar': 'غداء',
      'en': 'Lunch',
    },
    'grbybyer': {
      'fr': 'Dîner',
      'ar': 'عشاء',
      'en': 'Dinner',
    },
    'e5ae1dzl': {
      'fr': 'Collation',
      'ar': 'وجبة خفيفة',
      'en': 'Snack',
    },
    '7qf5wnkq': {
      'fr': 'Difficulté',
      'ar': 'صعوبة',
      'en': 'Difficulty',
    },
    'b6emlt3v': {
      'fr': 'Facile',
      'ar': 'سهل',
      'en': 'Easy',
    },
    'czc03edg': {
      'fr': 'Modérée',
      'ar': 'معتدل',
      'en': 'Moderate',
    },
    '1b7gjt9f': {
      'fr': 'Difficile',
      'ar': 'صعب',
      'en': 'Difficult',
    },
    'o26ziycg': {
      'fr': 'Région Culinaire',
      'ar': 'منطقة الطهي',
      'en': 'Culinary Region',
    },
    '5kxq8w14': {
      'fr': 'Option 1',
      'ar': 'الخيار 1',
      'en': 'Option 1',
    },
    'gp2n9cmo': {
      'fr': 'Option 2',
      'ar': 'الخيار الثاني',
      'en': 'Option 2',
    },
    'q8shpkmp': {
      'fr': 'Option 3',
      'ar': 'الخيار 3',
      'en': 'Option 3',
    },
    'w1sjbt4e': {
      'fr': 'Temps de préparation',
      'ar': 'وقت التحضير',
      'en': 'Preparation time',
    },
    'n2afe4j0': {
      'fr': 'h',
      'ar': 'ح',
      'en': 'h',
    },
    't19oqjfe': {
      'fr': 'min ',
      'ar': 'مين',
      'en': 'min',
    },
    'b6eese9z': {
      'fr': 'Rechercher',
      'ar': 'للبحث',
      'en': 'To research',
    },
  },
  // dietPlanError
  {
    'pu98yrfc': {
      'fr': 'Erreur',
      'ar': 'خطأ',
      'en': 'Error',
    },
    'yoxuhv50': {
      'fr':
          'Votre plan n\'a pu être généré car il manque certaines informations. \nVoulez vous continuer?',
      'ar': 'لم يتم إنشاء خطتك بسبب نقص بعض المعلومات.\n\nهل ترغب في المتابعة؟',
      'en':
          'Your plan could not be generated because some information is missing.\nDo you want to continue?',
    },
    'wqeezyzy': {
      'fr': 'Si le problème persiste, veuillez contacter nos services.',
      'ar': 'إذا استمرت المشكلة، يرجى الاتصال بخدماتنا.',
      'en': 'If the problem persists, please contact our services.',
    },
    '0ws38h8b': {
      'fr': 'Annuler',
      'ar': 'يلغي',
      'en': 'Cancel',
    },
    'llynxl4v': {
      'fr': 'Confirmer',
      'ar': 'يتأكد',
      'en': 'Confirm',
    },
  },
  // meal_plan_error
  {
    'knqixpgm': {
      'fr': 'Nous n\'avons pu généré vos repas',
      'ar': 'لم نتمكن من إعداد وجباتك',
      'en': 'We were unable to generate your meals',
    },
    'tm39suqw': {
      'fr': 'Si le problème persiste, veuillez contacter nos servoces.',
      'ar': 'إذا استمرت المشكلة، يرجى الاتصال بخدماتنا.',
      'en': 'If the problem persists, please contact our services.',
    },
    'ogpmlvt7': {
      'fr': 'Voulez-vous continuer ?',
      'ar': 'هل تريد المتابعة؟',
      'en': 'Do you want to continue?',
    },
    'zr6sg48e': {
      'fr': 'Annuler',
      'ar': 'يلغي',
      'en': 'Cancel',
    },
    'mcnga4du': {
      'fr': 'Continuer',
      'ar': 'يكمل',
      'en': 'Continue',
    },
  },
  // chatCopy2
  {
    'b765czcl': {
      'fr': 'Moi',
      'ar': 'أنا',
      'en': 'Me',
    },
  },
  // ai_chatCopy
  {
    '0xkr1dxf': {
      'fr': 'Moi',
      'ar': 'أنا',
      'en': 'Me',
    },
    '5sbfteb8': {
      'fr': 'Assistant',
      'ar': 'مساعد',
      'en': 'Assistant',
    },
    'gtv59ibh': {
      'fr': 'Votre assistant traite votre demande',
      'ar': 'يقوم مساعدك بمعالجة طلبك.',
      'en': 'Your assistant is processing your request.',
    },
  },
  // Miscellaneous
  {
    'zrraup4o': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '88d89qpz': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'd9jr5dgj': {
      'fr':
          'Akeli a besoin de votre autorisation pour sauvegarder vos photos de repas dans votre galerie.',
      'ar': 'يحتاج أكيلي إلى إذنك لحفظ صور وجباتك في معرض الصور الخاص بك.',
      'en':
          'Akeli needs your permission to save your meal photos to your gallery.',
    },
    '6dqy6f62': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'y05msa0z': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'lwx35cy7': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '58lhjhpv': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '57ttn2g8': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '1gkn2rk5': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'ylwduxdk': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'sz97m727': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '7p4z3juo': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'ej0x42tj': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'fk2snws8': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '71l52gsp': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '1b8kurae': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'bhy43rbn': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'vg4zhxse': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'ymoowiz2': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '1d8rhy7y': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'jgedalpe': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'phrkuvlz': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '5j2643vs': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'i465gms0': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '3dsb3e1z': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '3xl9314a': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    '4yh7dfum': {
      'fr': '',
      'ar': '',
      'en': '',
    },
    'fmzqgm81': {
      'fr': '',
      'ar': '',
      'en': '',
    },
  },
].reduce((a, b) => a..addAll(b));
