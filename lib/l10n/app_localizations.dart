import 'package:flutter/material.dart';

/// Lightweight, zero-dependency localization for OpenAsk.
/// Supports English, Urdu, Arabic (RTL), Hindi, Spanish, French, and Portuguese.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ur'), // Urdu (RTL)
    Locale('ar'), // Arabic (RTL)
    Locale('hi'), // Hindi
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('pt'), // Portuguese
  ];

  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ar' || locale.languageCode == 'ur';
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'OpenAsk',
      'home': 'Home',
      'discover': 'Discover',
      'ask': 'Ask',
      'alerts': 'Alerts',
      'profile': 'Profile',
      'recent': 'Recent',
      'trending': 'Trending',
      'following': 'Following',
      'search_hint': 'Search questions, topics, or tags...',
      'ask_question': 'Ask a Question',
      'post': 'Post',
      'cancel': 'Cancel',
      'save': 'Save',
      'saved': 'Saved',
      'answers': 'Answers',
      'views': 'Views',
      'solved': 'Solved',
      'anonymous': 'Anonymous',
      'post_anonymously': 'Post anonymously',
      'helpful_solution': 'Helpful Solution',
      'mark_helpful': 'Mark as Helpful',
      'write_answer': 'Write a helpful answer...',
      'settings': 'Settings',
      'language': 'Language',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'notifications': 'Notifications',
      'no_questions': 'No questions found',
      'retry': 'Try Again',
    },
    'ur': {
      'app_title': 'اوپن آسک',
      'home': 'ہوم',
      'discover': 'دریافت',
      'ask': 'پوچھیں',
      'alerts': 'اطلاعات',
      'profile': 'پروفائل',
      'recent': 'حالیہ',
      'trending': 'مقبول',
      'following': 'پیروی کردہ',
      'search_hint': 'سوالات، موضوعات یا ٹیگز تلاش کریں...',
      'ask_question': 'سوال پوچھیں',
      'post': 'شائع کریں',
      'cancel': 'منسوخ',
      'save': 'محفوظ کریں',
      'saved': 'محفوظ شدہ',
      'answers': 'جوابات',
      'views': 'مشاہدات',
      'solved': 'حل شدہ',
      'anonymous': 'گمنام',
      'post_anonymously': 'گمنام طور پر شائع کریں',
      'helpful_solution': 'مفید حل',
      'mark_helpful': 'بطور مفید منتخب کریں',
      'write_answer': 'ایک مفید جواب لکھیں...',
      'settings': 'ترتیبات',
      'language': 'زبان',
      'sign_in': 'لاگ ان کریں',
      'sign_out': 'لاگ آؤٹ',
      'notifications': 'نوٹیفیکیشنز',
      'no_questions': 'کوئی سوال نہیں ملا',
      'retry': 'دوبارہ کوشش کریں',
    },
    'ar': {
      'app_title': 'أوبن آسك',
      'home': 'الرئيسية',
      'discover': 'استكشف',
      'ask': 'اسأل',
      'alerts': 'الإشعارات',
      'profile': 'الملف الشخصي',
      'recent': 'الأحدث',
      'trending': 'الشائع',
      'following': 'المتابعة',
      'search_hint': 'ابحث عن الأسئلة، المواضيع أو الوسوم...',
      'ask_question': 'طرح سؤال',
      'post': 'نشر',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'saved': 'المحفوظات',
      'answers': 'إجابات',
      'views': 'مشاهدات',
      'solved': 'تم الحل',
      'anonymous': 'مجهول',
      'post_anonymously': 'النشر بهوية مجهولة',
      'helpful_solution': 'حل مفيد',
      'mark_helpful': 'تحديد كحل مفيد',
      'write_answer': 'اكتب إجابة مفيدة...',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'sign_in': 'تسجيل الدخول',
      'sign_out': 'تسجيل الخروج',
      'notifications': 'الإشعارات',
      'no_questions': 'لم يتم العثور على أسئلة',
      'retry': 'إعادة المحاولة',
    },
    'hi': {
      'app_title': 'ओपनआस्क',
      'home': 'होम',
      'discover': 'खोजें',
      'ask': 'पूछें',
      'alerts': 'सूचनाएं',
      'profile': 'प्रोफ़ाइल',
      'recent': 'हालिया',
      'trending': 'ट्रेंडिंग',
      'following': 'फॉलो किए गए',
      'search_hint': 'प्रश्न, विषय या टैग खोजें...',
      'ask_question': 'प्रश्न पूछें',
      'post': 'पोस्ट करें',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'saved': 'सहेजे गए',
      'answers': 'उत्तर',
      'views': 'देखे गए',
      'solved': 'हल किया गया',
      'anonymous': 'गुमनाम',
      'post_anonymously': 'गुमनाम रूप से पोस्ट करें',
      'helpful_solution': 'मददगार समाधान',
      'mark_helpful': 'मददगार चिह्नित करें',
      'write_answer': 'एक उपयोगी उत्तर लिखें...',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'sign_in': 'साइन इन करें',
      'sign_out': 'साइन आउट करें',
      'notifications': 'सूचनाएं',
      'no_questions': 'कोई प्रश्न नहीं मिला',
      'retry': 'पुनः प्रयास करें',
    },
    'es': {
      'app_title': 'OpenAsk',
      'home': 'Inicio',
      'discover': 'Descubrir',
      'ask': 'Preguntar',
      'alerts': 'Alertas',
      'profile': 'Perfil',
      'recent': 'Reciente',
      'trending': 'Tendencias',
      'following': 'Siguiendo',
      'search_hint': 'Buscar preguntas, temas o etiquetas...',
      'ask_question': 'Hacer una pregunta',
      'post': 'Publicar',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'saved': 'Guardados',
      'answers': 'Respuestas',
      'views': 'Vistas',
      'solved': 'Resuelto',
      'anonymous': 'Anónimo',
      'post_anonymously': 'Publicar de forma anónima',
      'helpful_solution': 'Solución útil',
      'mark_helpful': 'Marcar como útil',
      'write_answer': 'Escribe una respuesta útil...',
      'settings': 'Configuración',
      'language': 'Idioma',
      'sign_in': 'Iniciar sesión',
      'sign_out': 'Cerrar sesión',
      'notifications': 'Notificaciones',
      'no_questions': 'No se encontraron preguntas',
      'retry': 'Reintentar',
    },
    'fr': {
      'app_title': 'OpenAsk',
      'home': 'Accueil',
      'discover': 'Découvrir',
      'ask': 'Poser',
      'alerts': 'Alertes',
      'profile': 'Profil',
      'recent': 'Récent',
      'trending': 'Tendances',
      'following': 'Abonnements',
      'search_hint': 'Rechercher des questions, thèmes ou tags...',
      'ask_question': 'Poser une question',
      'post': 'Publier',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'saved': 'Enregistrés',
      'answers': 'Réponses',
      'views': 'Vues',
      'solved': 'Résolu',
      'anonymous': 'Anonyme',
      'post_anonymously': 'Publier anonymement',
      'helpful_solution': 'Solution utile',
      'mark_helpful': 'Marquer comme utile',
      'write_answer': 'Écrire une réponse utile...',
      'settings': 'Paramètres',
      'language': 'Langue',
      'sign_in': 'Se connecter',
      'sign_out': 'Se déconnecter',
      'notifications': 'Notifications',
      'no_questions': 'Aucune question trouvée',
      'retry': 'Réessayer',
    },
    'pt': {
      'app_title': 'OpenAsk',
      'home': 'Início',
      'discover': 'Explorar',
      'ask': 'Perguntar',
      'alerts': 'Alertas',
      'profile': 'Perfil',
      'recent': 'Recentes',
      'trending': 'Em alta',
      'following': 'Seguindo',
      'search_hint': 'Buscar perguntas, tópicos ou tags...',
      'ask_question': 'Fazer uma pergunta',
      'post': 'Publicar',
      'cancel': 'Cancelar',
      'save': 'Salvar',
      'saved': 'Salvos',
      'answers': 'Respostas',
      'views': 'Visualizações',
      'solved': 'Resolvido',
      'anonymous': 'Anônimo',
      'post_anonymously': 'Publicar anonimamente',
      'helpful_solution': 'Solução útil',
      'mark_helpful': 'Marcar como útil',
      'write_answer': 'Escreva uma resposta útil...',
      'settings': 'Configurações',
      'language': 'Idioma',
      'sign_in': 'Entrar',
      'sign_out': 'Sair',
      'notifications': 'Notificações',
      'no_questions': 'Nenhuma pergunta encontrada',
      'retry': 'Tentar novamente',
    },
  };

  String translate(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ur', 'ar', 'hi', 'es', 'fr', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
