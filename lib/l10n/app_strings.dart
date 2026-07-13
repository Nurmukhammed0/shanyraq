import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';

/// Лёгкая своя система переводов (без flutter_localizations/arb) —
/// достаточно для набора экранов этого приложения. Ключи собраны в
/// одном словаре, чтобы было легко добавлять новые строки.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  String t(String key, [Map<String, String>? params]) {
    var value = _dict[key]?[language] ?? _dict[key]?[AppLanguage.ru] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  static const Map<String, Map<AppLanguage, String>> _dict = {
    // Навигация
    'nav_map': {AppLanguage.ru: 'Карта', AppLanguage.kz: 'Карта', AppLanguage.en: 'Map'},
    'nav_favorites': {
      AppLanguage.ru: 'Избранное',
      AppLanguage.kz: 'Таңдаулылар',
      AppLanguage.en: 'Favorites',
    },
    'nav_profile': {AppLanguage.ru: 'Профиль', AppLanguage.kz: 'Профиль', AppLanguage.en: 'Profile'},

    // Общее
    'app_title': {
      AppLanguage.ru: 'Шаңырақ',
      AppLanguage.kz: 'Шаңырақ',
      AppLanguage.en: 'Shanyraq',
    },
    'cancel': {AppLanguage.ru: 'Отмена', AppLanguage.kz: 'Болдырмау', AppLanguage.en: 'Cancel'},
    'delete': {AppLanguage.ru: 'Удалить', AppLanguage.kz: 'Жою', AppLanguage.en: 'Delete'},
    'save': {AppLanguage.ru: 'Сохранить', AppLanguage.kz: 'Сақтау', AppLanguage.en: 'Save'},
    'more_details': {
      AppLanguage.ru: 'Подробнее',
      AppLanguage.kz: 'Толығырақ',
      AppLanguage.en: 'Details',
    },

    // Карта
    'map_filters_close': {
      AppLanguage.ru: 'Закрыть фильтры',
      AppLanguage.kz: 'Сүзгілерді жабу',
      AppLanguage.en: 'Close filters',
    },
    'map_filters_open': {
      AppLanguage.ru: 'Фильтры',
      AppLanguage.kz: 'Сүзгілер',
      AppLanguage.en: 'Filters',
    },
    'map_long_press_hint': {
      AppLanguage.ru: 'Долгое нажатие на карту — добавить ЖК',
      AppLanguage.kz: 'Картаны басып тұру — ЖК қосу',
      AppLanguage.en: 'Long-press the map to add a complex',
    },
    'map_missing_coords': {
      AppLanguage.ru: '{n} объектов без координат — нужно геокодирование адресов.',
      AppLanguage.kz: '{n} нысанда координат жоқ — мекенжайларды геокодтау керек.',
      AppLanguage.en: '{n} objects without coordinates — addresses need geocoding.',
    },
    'map_location_services_disabled': {
      AppLanguage.ru: 'Включите службы геолокации в настройках устройства.',
      AppLanguage.kz: 'Құрылғы баптауларында геолокация қызметін қосыңыз.',
      AppLanguage.en: 'Enable location services in your device settings.',
    },
    'map_location_permission_denied': {
      AppLanguage.ru: 'Доступ к геолокации запрещён.',
      AppLanguage.kz: 'Геолокацияға рұқсат берілмеген.',
      AppLanguage.en: 'Location access denied.',
    },
    'map_location_unavailable': {
      AppLanguage.ru: 'Не удалось определить местоположение.',
      AppLanguage.kz: 'Орналасқан жерді анықтау мүмкін болмады.',
      AppLanguage.en: 'Could not determine your location.',
    },
    'filter_all': {AppLanguage.ru: 'Все', AppLanguage.kz: 'Барлығы', AppLanguage.en: 'All'},
    'filter_problematic': {
      AppLanguage.ru: 'Красная зона',
      AppLanguage.kz: 'Қызыл аймақ',
      AppLanguage.en: 'Red zone',
    },
    'filter_guaranteed': {
      AppLanguage.ru: 'Гарантия',
      AppLanguage.kz: 'Кепілдік',
      AppLanguage.en: 'Guaranteed',
    },
    'filter_locked': {
      AppLanguage.ru: 'Фильтр по статусу риска — по подписке',
      AppLanguage.kz: 'Тәуекел мәртебесі бойынша сүзгі — жазылым бойынша',
      AppLanguage.en: 'Risk status filter — subscription only',
    },
    'filter_district_hint': {AppLanguage.ru: 'Район', AppLanguage.kz: 'Аудан', AppLanguage.en: 'District'},
    'filter_district_all': {
      AppLanguage.ru: 'Все районы',
      AppLanguage.kz: 'Барлық аудандар',
      AppLanguage.en: 'All districts',
    },
    'search_hint': {
      AppLanguage.ru: 'Поиск по названию или адресу',
      AppLanguage.kz: 'Атауы немесе мекенжайы бойынша іздеу',
      AppLanguage.en: 'Search by name or address',
    },

    // Избранное
    'favorites_empty_title': {
      AppLanguage.ru: 'Здесь пока пусто',
      AppLanguage.kz: 'Мұнда әзірге бос',
      AppLanguage.en: 'Nothing saved yet',
    },
    'favorites_empty_body': {
      AppLanguage.ru: 'Присматриваете ЖК? Нажмите ♡ на карточке объекта — соберём всё '
          'важное для вас в одном месте.',
      AppLanguage.kz: 'ЖК қарап жүрсіз бе? Нысан карточкасында ♡ басыңыз — сізге маңыздысын '
          'бір жерге жинаймыз.',
      AppLanguage.en: 'Scoping out complexes? Tap ♡ on any object card — we\'ll keep '
          'everything you care about in one place.',
    },
    'status_red_zone_short': {
      AppLanguage.ru: 'Красная зона',
      AppLanguage.kz: 'Қызыл аймақ',
      AppLanguage.en: 'Red zone',
    },
    'status_guaranteed_short': {
      AppLanguage.ru: 'Госгарантия',
      AppLanguage.kz: 'Мемкепілдік',
      AppLanguage.en: 'State guarantee',
    },
    'status_locked_short': {
      AppLanguage.ru: 'Статус — по подписке',
      AppLanguage.kz: 'Мәртебе — жазылым бойынша',
      AppLanguage.en: 'Status — subscription only',
    },

    // Вход/регистрация
    'login_title': {AppLanguage.ru: 'Вход', AppLanguage.kz: 'Кіру', AppLanguage.en: 'Sign in'},
    'register_title': {
      AppLanguage.ru: 'Регистрация',
      AppLanguage.kz: 'Тіркелу',
      AppLanguage.en: 'Sign up',
    },
    'email_label': {AppLanguage.ru: 'Email', AppLanguage.kz: 'Email', AppLanguage.en: 'Email'},
    'password_label': {
      AppLanguage.ru: 'Пароль',
      AppLanguage.kz: 'Құпия сөз',
      AppLanguage.en: 'Password',
    },
    'password_min_label': {
      AppLanguage.ru: 'Пароль (мин. 6 символов)',
      AppLanguage.kz: 'Құпия сөз (кемінде 6 таңба)',
      AppLanguage.en: 'Password (min. 6 characters)',
    },
    'login_submit': {AppLanguage.ru: 'Войти', AppLanguage.kz: 'Кіру', AppLanguage.en: 'Sign in'},
    'login_no_account': {
      AppLanguage.ru: 'Нет аккаунта? Зарегистрироваться',
      AppLanguage.kz: 'Аккаунтыңыз жоқ па? Тіркелу',
      AppLanguage.en: "Don't have an account? Sign up",
    },
    'register_submit': {
      AppLanguage.ru: 'Зарегистрироваться',
      AppLanguage.kz: 'Тіркелу',
      AppLanguage.en: 'Sign up',
    },
    'register_success': {
      AppLanguage.ru: 'Готово! Проверьте почту для подтверждения (если включено в Supabase), затем войдите.',
      AppLanguage.kz: 'Дайын! Растау үшін поштаңызды тексеріңіз (Supabase-те қосылған болса), содан кейін кіріңіз.',
      AppLanguage.en: 'Done! Check your email to confirm (if enabled in Supabase), then sign in.',
    },

    // Карточка ЖК
    'zhk_edit_tooltip': {
      AppLanguage.ru: 'Редактировать (админ)',
      AppLanguage.kz: 'Өңдеу (админ)',
      AppLanguage.en: 'Edit (admin)',
    },
    'zhk_delete_tooltip': {
      AppLanguage.ru: 'Удалить (админ)',
      AppLanguage.kz: 'Жою (админ)',
      AppLanguage.en: 'Delete (admin)',
    },
    'zhk_delete_confirm_title': {
      AppLanguage.ru: 'Удалить объект?',
      AppLanguage.kz: 'Нысанды жою керек пе?',
      AppLanguage.en: 'Delete this object?',
    },
    'zhk_delete_confirm_body': {
      AppLanguage.ru: '«{name}» пропадёт из списка, но админ сможет восстановить его из корзины.',
      AppLanguage.kz: '«{name}» тізімнен жоғалады, бірақ әкімші оны себеттен қалпына келтіре алады.',
      AppLanguage.en: '"{name}" will disappear from the list, but an admin can restore it from the trash.',
    },
    'zhk_district': {AppLanguage.ru: 'Район', AppLanguage.kz: 'Аудан', AppLanguage.en: 'District'},
    'zhk_address': {AppLanguage.ru: 'Адрес', AppLanguage.kz: 'Мекенжай', AppLanguage.en: 'Address'},
    'zhk_developer': {
      AppLanguage.ru: 'Застройщик',
      AppLanguage.kz: 'Құрылысшы',
      AppLanguage.en: 'Developer',
    },
    'zhk_documentation': {
      AppLanguage.ru: 'Разрешительная документация',
      AppLanguage.kz: 'Рұқсат беру құжаттамасы',
      AppLanguage.en: 'Permits & documentation',
    },
    'zhk_tech_status': {
      AppLanguage.ru: 'Техническое состояние',
      AppLanguage.kz: 'Техникалық жағдайы',
      AppLanguage.en: 'Technical status',
    },
    'zhk_violations': {
      AppLanguage.ru: 'Нарушения',
      AppLanguage.kz: 'Бұзушылықтар',
      AppLanguage.en: 'Violations',
    },
    'zhk_measures': {
      AppLanguage.ru: 'Принятые меры',
      AppLanguage.kz: 'Қабылданған шаралар',
      AppLanguage.en: 'Measures taken',
    },
    'zhk_court': {
      AppLanguage.ru: 'Судебный статус',
      AppLanguage.kz: 'Сот мәртебесі',
      AppLanguage.en: 'Court status',
    },
    'zhk_construction_built': {
      AppLanguage.ru: 'Построен',
      AppLanguage.kz: 'Салынды',
      AppLanguage.en: 'Built',
    },
    'zhk_construction_in_progress': {
      AppLanguage.ru: 'Строится',
      AppLanguage.kz: 'Салынып жатыр',
      AppLanguage.en: 'Under construction',
    },
    'zhk_year_built': {
      AppLanguage.ru: 'Сдан в {year} году',
      AppLanguage.kz: '{year} жылы тапсырылды',
      AppLanguage.en: 'Completed in {year}',
    },
    'zhk_year_expected': {
      AppLanguage.ru: 'Ожидаемая сдача — {year} год',
      AppLanguage.kz: 'Тапсыру мерзімі — {year} жыл',
      AppLanguage.en: 'Expected completion — {year}',
    },
    'zhk_status_problematic': {
      AppLanguage.ru: 'Проблемный / красная зона',
      AppLanguage.kz: 'Проблемалы / қызыл аймақ',
      AppLanguage.en: 'Problematic / red zone',
    },
    'zhk_status_guaranteed': {
      AppLanguage.ru: 'Завершён под госгарантией',
      AppLanguage.kz: 'Мемлекеттік кепілдікпен аяқталды',
      AppLanguage.en: 'Completed under state guarantee',
    },
    'zhk_status_locked': {
      AppLanguage.ru: 'Статус риска — по подписке',
      AppLanguage.kz: 'Тәуекел мәртебесі — жазылым бойынша',
      AppLanguage.en: 'Risk status — subscription only',
    },
    'paywall_title': {
      AppLanguage.ru: 'Детали доступны по подписке',
      AppLanguage.kz: 'Толық ақпарат жазылым бойынша қолжетімді',
      AppLanguage.en: 'Details available with subscription',
    },
    'paywall_body': {
      AppLanguage.ru: 'Статус риска, разрешительная документация, техническое состояние, '
          'нарушения, принятые меры и судебный статус открываются по подписке.',
      AppLanguage.kz: 'Тәуекел мәртебесі, рұқсат беру құжаттамасы, техникалық жағдайы, '
          'бұзушылықтар, қабылданған шаралар және сот мәртебесі жазылым бойынша ашылады.',
      AppLanguage.en: 'Risk status, permits, technical status, violations, measures taken '
          'and court status unlock with a subscription.',
    },
    'subscribe_button': {
      AppLanguage.ru: 'Оформить подписку',
      AppLanguage.kz: 'Жазылымға рәсімдеу',
      AppLanguage.en: 'Subscribe',
    },

    // Подписка
    'subscription_title': {
      AppLanguage.ru: 'Подписка',
      AppLanguage.kz: 'Жазылым',
      AppLanguage.en: 'Subscription',
    },
    'subscription_active_title': {
      AppLanguage.ru: 'Подписка активна',
      AppLanguage.kz: 'Жазылым белсенді',
      AppLanguage.en: 'Subscription active',
    },
    'subscription_active_body': {
      AppLanguage.ru: 'Вам доступны все детали по объектам.',
      AppLanguage.kz: 'Сізге нысандар бойынша барлық ақпарат қолжетімді.',
      AppLanguage.en: 'All object details are available to you.',
    },
    'subscription_inactive_title': {
      AppLanguage.ru: 'Подписка ещё в разработке',
      AppLanguage.kz: 'Жазылым әлі әзірленуде',
      AppLanguage.en: 'Subscription is still in development',
    },
    'subscription_inactive_body': {
      AppLanguage.ru: 'Онлайн-оплата пока не подключена. Чтобы получить доступ к деталям '
          'объектов, свяжитесь с администратором приложения.',
      AppLanguage.kz: 'Онлайн төлем әлі қосылмаған. Нысандар туралы толық ақпарат алу үшін '
          'қосымша әкімшісіне хабарласыңыз.',
      AppLanguage.en: 'Online payment is not connected yet. Contact the app administrator '
          'to get access to object details.',
    },
    'subscription_email_label': {
      AppLanguage.ru: 'Ваш email для активации: {email}',
      AppLanguage.kz: 'Белсендіру үшін email: {email}',
      AppLanguage.en: 'Your email for activation: {email}',
    },

    // Профиль
    'profile_no_subscription': {
      AppLanguage.ru: 'Без подписки',
      AppLanguage.kz: 'Жазылымсыз',
      AppLanguage.en: 'No subscription',
    },
    'profile_subscription_tile': {
      AppLanguage.ru: 'Подписка',
      AppLanguage.kz: 'Жазылым',
      AppLanguage.en: 'Subscription',
    },
    'profile_settings_tile': {
      AppLanguage.ru: 'Настройки',
      AppLanguage.kz: 'Баптаулар',
      AppLanguage.en: 'Settings',
    },
    'profile_admin_tile': {
      AppLanguage.ru: 'Админка',
      AppLanguage.kz: 'Әкімшілік',
      AppLanguage.en: 'Admin panel',
    },
    'profile_signed_in_fallback': {
      AppLanguage.ru: 'Вы вошли',
      AppLanguage.kz: 'Сіз кірдіңіз',
      AppLanguage.en: 'Signed in',
    },
    'profile_logout': {AppLanguage.ru: 'Выйти', AppLanguage.kz: 'Шығу', AppLanguage.en: 'Log out'},

    // Настройки
    'settings_title': {
      AppLanguage.ru: 'Настройки',
      AppLanguage.kz: 'Баптаулар',
      AppLanguage.en: 'Settings',
    },
    'settings_theme': {
      AppLanguage.ru: 'Тема оформления',
      AppLanguage.kz: 'Безендіру тақырыбы',
      AppLanguage.en: 'Appearance',
    },
    'theme_light': {
      AppLanguage.ru: 'Светлая',
      AppLanguage.kz: 'Ашық',
      AppLanguage.en: 'Light',
    },
    'theme_dark': {
      AppLanguage.ru: 'Тёмная',
      AppLanguage.kz: 'Күңгірт',
      AppLanguage.en: 'Dark',
    },
    'theme_system': {
      AppLanguage.ru: 'Системная',
      AppLanguage.kz: 'Жүйелік',
      AppLanguage.en: 'System',
    },
    'settings_language': {
      AppLanguage.ru: 'Язык',
      AppLanguage.kz: 'Тіл',
      AppLanguage.en: 'Language',
    },
  };
}

extension AppLocalization on BuildContext {
  /// Короткий доступ к переводу: context.tr('key').
  String tr(String key, [Map<String, String>? params]) {
    final language = Provider.of<SettingsService>(this, listen: true).language;
    return AppStrings(language).t(key, params);
  }
}
