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
      AppLanguage.ru: 'Придумайте пароль',
      AppLanguage.kz: 'Құпия сөз ойлап табыңыз',
      AppLanguage.en: 'Create a password',
    },
    'password_strength_weak': {
      AppLanguage.ru: 'Слабый',
      AppLanguage.kz: 'Әлсіз',
      AppLanguage.en: 'Weak',
    },
    'password_strength_medium': {
      AppLanguage.ru: 'Средний',
      AppLanguage.kz: 'Орташа',
      AppLanguage.en: 'Medium',
    },
    'password_strength_strong': {
      AppLanguage.ru: 'Надёжный',
      AppLanguage.kz: 'Сенімді',
      AppLanguage.en: 'Strong',
    },
    'password_req_length': {
      AppLanguage.ru: '8+ символов',
      AppLanguage.kz: '8+ таңба',
      AppLanguage.en: '8+ characters',
    },
    'password_req_uppercase': {
      AppLanguage.ru: 'Заглавная буква',
      AppLanguage.kz: 'Бас әріп',
      AppLanguage.en: 'Uppercase letter',
    },
    'password_req_digit': {
      AppLanguage.ru: 'Цифра',
      AppLanguage.kz: 'Сан',
      AppLanguage.en: 'A number',
    },
    'password_req_symbol': {
      AppLanguage.ru: 'Спецсимвол',
      AppLanguage.kz: 'Арнайы таңба',
      AppLanguage.en: 'Special character',
    },
    'password_requirements_error': {
      AppLanguage.ru: 'Пароль недостаточно надёжный — выполните все требования ниже',
      AppLanguage.kz: 'Құпия сөз жеткілікті сенімді емес — төмендегі талаптарды орындаңыз',
      AppLanguage.en: 'Password is not strong enough — meet all the requirements below',
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
    'profile_group_account': {
      AppLanguage.ru: 'Аккаунт',
      AppLanguage.kz: 'Аккаунт',
      AppLanguage.en: 'Account',
    },
    'profile_group_app': {
      AppLanguage.ru: 'Приложение',
      AppLanguage.kz: 'Қолданба',
      AppLanguage.en: 'App',
    },

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
    'settings_notifications_group': {
      AppLanguage.ru: 'Уведомления',
      AppLanguage.kz: 'Хабарландырулар',
      AppLanguage.en: 'Notifications',
    },
    'settings_status_notifications_title': {
      AppLanguage.ru: 'Изменение статуса ЖК',
      AppLanguage.kz: 'ЖК мәртебесінің өзгеруі',
      AppLanguage.en: 'Development status changes',
    },
    'settings_status_notifications_body': {
      AppLanguage.ru: 'Сообщим, если статус избранного ЖК изменится',
      AppLanguage.kz: 'Таңдаулы ЖК-ңыздың мәртебесі өзгерсе, хабарлаймыз',
      AppLanguage.en: "We'll let you know if a favorited development changes status",
    },
    'settings_email_notifications_title': {
      AppLanguage.ru: 'Email-уведомления',
      AppLanguage.kz: 'Email-хабарландырулар',
      AppLanguage.en: 'Email notifications',
    },
    'settings_email_notifications_body': {
      AppLanguage.ru: 'Дублировать важные уведомления на почту',
      AppLanguage.kz: 'Маңызды хабарландыруларды поштаға да жіберу',
      AppLanguage.en: 'Also send important notifications by email',
    },

    // Общие
    'divider_or': {AppLanguage.ru: 'или', AppLanguage.kz: 'немесе', AppLanguage.en: 'or'},
    'generic_error': {
      AppLanguage.ru: 'Ошибка: {error}',
      AppLanguage.kz: 'Қате: {error}',
      AppLanguage.en: 'Error: {error}',
    },
    'close': {AppLanguage.ru: 'Закрыть', AppLanguage.kz: 'Жабу', AppLanguage.en: 'Close'},

    // Регистрация / вход — доп. тексты
    'register_heading': {
      AppLanguage.ru: 'Добро пожаловать',
      AppLanguage.kz: 'Қош келдіңіз',
      AppLanguage.en: 'Welcome',
    },
    'register_subtitle': {
      AppLanguage.ru: 'Создайте аккаунт, чтобы сохранять ЖК в избранное и следить за изменением их статуса',
      AppLanguage.kz: 'ЖК-ларды таңдаулыға сақтау және олардың мәртебесінің өзгеруін бақылау үшін аккаунт жасаңыз',
      AppLanguage.en: 'Create an account to save developments to favorites and track their status changes',
    },
    'login_subtitle': {
      AppLanguage.ru: 'Войдите, чтобы сохранять избранное и получать уведомления об изменениях',
      AppLanguage.kz: 'Таңдаулыны сақтау және өзгерістер туралы хабарландыру алу үшін кіріңіз',
      AppLanguage.en: 'Sign in to save favorites and get notified about changes',
    },

    // Онбординг
    'onboarding_title_1': {
      AppLanguage.ru: 'Шаңырақ — дом на карте',
      AppLanguage.kz: 'Шаңырақ — картадағы үй',
      AppLanguage.en: 'Shanyraq — home on the map',
    },
    'onboarding_body_1': {
      AppLanguage.ru: 'Показываем на карте проблемные жилые комплексы и объекты, завершённые под госгарантией — чтобы вы видели риски до сделки.',
      AppLanguage.kz: 'Картада проблемалы тұрғын үй кешендерін және мемлекеттік кепілдікпен аяқталған нысандарды көрсетеміз — сатып алудан бұрын тәуекелдерді көру үшін.',
      AppLanguage.en: 'We show problematic residential complexes and state-guarantee-completed developments on the map — so you can see the risks before you buy.',
    },
    'onboarding_title_2': {
      AppLanguage.ru: 'Красная зона и гарантия',
      AppLanguage.kz: 'Қызыл аймақ және кепілдік',
      AppLanguage.en: 'Red zone and guarantee',
    },
    'onboarding_body_2': {
      AppLanguage.ru: 'Красный маркер — у объекта есть нарушения или проблемы со стройкой. Зелёный — комплекс сдан под госгарантией дольщикам.',
      AppLanguage.kz: 'Қызыл маркер — нысанда бұзушылықтар немесе құрылыс мәселелері бар. Жасыл — кешен үлескерлерге мемлекеттік кепілдікпен тапсырылған.',
      AppLanguage.en: 'Red marker — the development has violations or construction issues. Green — the complex was handed over to shareholders under a state guarantee.',
    },
    'onboarding_title_3': {
      AppLanguage.ru: 'Подробности по подписке',
      AppLanguage.kz: 'Жазылым бойынша толық ақпарат',
      AppLanguage.en: 'Details via subscription',
    },
    'onboarding_body_3': {
      AppLanguage.ru: 'Базовая информация (адрес, застройщик) доступна всем бесплатно. Детали — нарушения, суд, документация — открываются по подписке.',
      AppLanguage.kz: 'Негізгі ақпарат (мекенжай, құрылысшы) барлығына тегін қолжетімді. Толық мәліметтер — бұзушылықтар, сот, құжаттама — жазылым арқылы ашылады.',
      AppLanguage.en: 'Basic info (address, developer) is free for everyone. Details — violations, court, documentation — unlock with a subscription.',
    },
    'onboarding_skip': {AppLanguage.ru: 'Пропустить', AppLanguage.kz: 'Өткізіп жіберу', AppLanguage.en: 'Skip'},
    'onboarding_start': {AppLanguage.ru: 'Начать', AppLanguage.kz: 'Бастау', AppLanguage.en: 'Get started'},
    'onboarding_next': {AppLanguage.ru: 'Далее', AppLanguage.kz: 'Келесі', AppLanguage.en: 'Next'},

    // Профильное меню / About
    'edit_profile_title': {
      AppLanguage.ru: 'Редактировать профиль',
      AppLanguage.kz: 'Профильді өңдеу',
      AppLanguage.en: 'Edit profile',
    },
    'about_title': {
      AppLanguage.ru: 'О приложении',
      AppLanguage.kz: 'Қолданба туралы',
      AppLanguage.en: 'About the app',
    },

    // Карта — тултипы
    'map_notifications_tooltip': {
      AppLanguage.ru: 'Уведомления',
      AppLanguage.kz: 'Хабарландырулар',
      AppLanguage.en: 'Notifications',
    },
    'map_locate_tooltip': {
      AppLanguage.ru: 'Моё местоположение',
      AppLanguage.kz: 'Менің орналасуым',
      AppLanguage.en: 'My location',
    },
    'map_zoom_in_tooltip': {AppLanguage.ru: 'Увеличить', AppLanguage.kz: 'Үлкейту', AppLanguage.en: 'Zoom in'},
    'map_zoom_out_tooltip': {AppLanguage.ru: 'Уменьшить', AppLanguage.kz: 'Кішірейту', AppLanguage.en: 'Zoom out'},

    // Избранное
    'favorites_load_error': {
      AppLanguage.ru: 'Ошибка загрузки избранного: {error}',
      AppLanguage.kz: 'Таңдаулыны жүктеу қатесі: {error}',
      AppLanguage.en: 'Failed to load favorites: {error}',
    },

    // Карточка ЖК — доп.
    'zhk_delete_not_found': {
      AppLanguage.ru: 'Объект не удалён: сервер не нашёл строку (проверьте id/RLS).',
      AppLanguage.kz: 'Нысан жойылмады: сервер жолды таппады (id/RLS тексеріңіз).',
      AppLanguage.en: 'Not deleted: the server could not find the row (check id/RLS).',
    },
    'zhk_delete_error': {
      AppLanguage.ru: 'Ошибка удаления: {error}',
      AppLanguage.kz: 'Жою қатесі: {error}',
      AppLanguage.en: 'Delete failed: {error}',
    },
    'zhk_report_issue_button': {
      AppLanguage.ru: 'Сообщить об ошибке в данных',
      AppLanguage.kz: 'Деректегі қатені хабарлау',
      AppLanguage.en: 'Report a data issue',
    },

    // Уведомления
    'notifications_title': {
      AppLanguage.ru: 'Уведомления',
      AppLanguage.kz: 'Хабарландырулар',
      AppLanguage.en: 'Notifications',
    },
    'notifications_load_error': {
      AppLanguage.ru: 'Не удалось загрузить уведомления: {error}',
      AppLanguage.kz: 'Хабарландыруларды жүктеу мүмкін болмады: {error}',
      AppLanguage.en: 'Failed to load notifications: {error}',
    },
    'notifications_empty_title': {
      AppLanguage.ru: 'Пока всё тихо',
      AppLanguage.kz: 'Әзірге тыныш',
      AppLanguage.en: 'All quiet for now',
    },
    'notifications_empty_body': {
      AppLanguage.ru: 'Как только статус вашего избранного ЖК изменится — сразу сообщим здесь',
      AppLanguage.kz: 'Таңдаулы ЖК-ңыздың мәртебесі өзгергенде — бірден осында хабарлаймыз',
      AppLanguage.en: "As soon as a favorited development changes status, you'll see it here",
    },
    'notif_status_problematic': {
      AppLanguage.ru: 'Красная зона',
      AppLanguage.kz: 'Қызыл аймақ',
      AppLanguage.en: 'Red zone',
    },
    'notif_status_guaranteed': {
      AppLanguage.ru: 'Госгарантия',
      AppLanguage.kz: 'Мемлекеттік кепілдік',
      AppLanguage.en: 'State guarantee',
    },
    'notif_status_unknown': {
      AppLanguage.ru: 'неизвестно',
      AppLanguage.kz: 'белгісіз',
      AppLanguage.en: 'unknown',
    },

    // Подписка — доп.
    'sub_benefit_status_title': {
      AppLanguage.ru: 'Статус риска на карте',
      AppLanguage.kz: 'Картадағы тәуекел мәртебесі',
      AppLanguage.en: 'Risk status on the map',
    },
    'sub_benefit_status_subtitle': {
      AppLanguage.ru: 'Красная зона или госгарантия — сразу видно на маркере',
      AppLanguage.kz: 'Қызыл аймақ немесе мемлекеттік кепілдік — маркерде бірден көрінеді',
      AppLanguage.en: 'Red zone or state guarantee — visible right on the marker',
    },
    'sub_benefit_docs_title': {
      AppLanguage.ru: 'Разрешительная документация',
      AppLanguage.kz: 'Рұқсат беру құжаттамасы',
      AppLanguage.en: 'Permits & documentation',
    },
    'sub_benefit_docs_subtitle': {
      AppLanguage.ru: 'Что оформлено, а что отсутствует у застройщика',
      AppLanguage.kz: 'Құрылысшыда не рәсімделген, не жоқ',
      AppLanguage.en: "What the developer has and hasn't filed",
    },
    'sub_benefit_violations_title': {
      AppLanguage.ru: 'Нарушения и меры',
      AppLanguage.kz: 'Бұзушылықтар мен шаралар',
      AppLanguage.en: 'Violations and measures',
    },
    'sub_benefit_violations_subtitle': {
      AppLanguage.ru: 'Полная история претензий и принятых мер',
      AppLanguage.kz: 'Талаптар мен қабылданған шаралардың толық тарихы',
      AppLanguage.en: 'Full history of claims and measures taken',
    },
    'sub_benefit_court_title': {
      AppLanguage.ru: 'Судебный статус',
      AppLanguage.kz: 'Сот мәртебесі',
      AppLanguage.en: 'Court status',
    },
    'sub_benefit_court_subtitle': {
      AppLanguage.ru: 'Есть ли иски, решения о сносе, исполнительные листы',
      AppLanguage.kz: 'Талап-арыздар, бұзу туралы шешімдер, атқарушылық парақтар бар ма',
      AppLanguage.en: 'Lawsuits, demolition rulings, enforcement orders',
    },
    'sub_benefit_notifications_title': {
      AppLanguage.ru: 'Уведомления',
      AppLanguage.kz: 'Хабарландырулар',
      AppLanguage.en: 'Notifications',
    },
    'sub_benefit_notifications_subtitle': {
      AppLanguage.ru: 'Сообщим, если статус избранного ЖК изменится',
      AppLanguage.kz: 'Таңдаулы ЖК-ңыздың мәртебесі өзгерсе, хабарлаймыз',
      AppLanguage.en: "We'll let you know if a favorited development changes status",
    },
    'subscription_paywall_heading': {
      AppLanguage.ru: 'Полная картина перед покупкой',
      AppLanguage.kz: 'Сатып алу алдында толық көрініс',
      AppLanguage.en: 'The full picture before you buy',
    },
    'subscription_paywall_body': {
      AppLanguage.ru: 'Адрес и застройщик видны всем бесплатно. Подписка открывает то, что реально влияет на решение о покупке.',
      AppLanguage.kz: 'Мекенжай мен құрылысшы барлығына тегін көрінеді. Жазылым сатып алу шешіміне нақты әсер ететін ақпаратты ашады.',
      AppLanguage.en: 'Address and developer are visible to everyone for free. The subscription unlocks what actually affects your buying decision.',
    },
    'subscription_price_value': {
      AppLanguage.ru: '3 000 ₸ / мес',
      AppLanguage.kz: '3 000 ₸ / ай',
      AppLanguage.en: '3,000 ₸ / month',
    },
    'subscription_price_label': {
      AppLanguage.ru: 'Подписка',
      AppLanguage.kz: 'Жазылым',
      AppLanguage.en: 'Subscription',
    },
    'subscription_subscribe_button': {
      AppLanguage.ru: 'Оформить подписку',
      AppLanguage.kz: 'Жазылымды рәсімдеу',
      AppLanguage.en: 'Subscribe',
    },
    'subscription_support_link': {
      AppLanguage.ru: 'Есть вопросы? Написать в поддержку',
      AppLanguage.kz: 'Сұрақтар бар ма? Қолдау қызметіне жазыңыз',
      AppLanguage.en: 'Have questions? Contact support',
    },
    'payment_processing': {
      AppLanguage.ru: 'Обрабатываем платёж...',
      AppLanguage.kz: 'Төлемді өңдеудеміз...',
      AppLanguage.en: 'Processing payment...',
    },
    'payment_success': {
      AppLanguage.ru: 'Оплата прошла успешно',
      AppLanguage.kz: 'Төлем сәтті өтті',
      AppLanguage.en: 'Payment successful',
    },
    'payment_error': {
      AppLanguage.ru: 'Не получилось: {error}',
      AppLanguage.kz: 'Сәтсіз аяқталды: {error}',
      AppLanguage.en: 'Something went wrong: {error}',
    },
    'subscription_choose_payment': {
      AppLanguage.ru: 'Выберите способ оплаты',
      AppLanguage.kz: 'Төлем әдісін таңдаңыз',
      AppLanguage.en: 'Choose a payment method',
    },
    'subscription_pay_card': {
      AppLanguage.ru: 'Оплатить картой',
      AppLanguage.kz: 'Картамен төлеу',
      AppLanguage.en: 'Pay with card',
    },
    'subscription_pay_apple': {
      AppLanguage.ru: 'Apple ID',
      AppLanguage.kz: 'Apple ID',
      AppLanguage.en: 'Apple ID',
    },
    'subscription_card_number_hint': {
      AppLanguage.ru: 'Номер карты',
      AppLanguage.kz: 'Карта нөмірі',
      AppLanguage.en: 'Card number',
    },
    'subscription_pay_button': {
      AppLanguage.ru: 'Оплатить',
      AppLanguage.kz: 'Төлеу',
      AppLanguage.en: 'Pay',
    },
    'subscription_payment_method_label': {
      AppLanguage.ru: 'Способ оплаты',
      AppLanguage.kz: 'Төлем әдісі',
      AppLanguage.en: 'Payment method',
    },
    'subscription_auto_renew_title': {
      AppLanguage.ru: 'Автопродление',
      AppLanguage.kz: 'Автоматты жаңарту',
      AppLanguage.en: 'Auto-renew',
    },
    'subscription_auto_renew_on_body': {
      AppLanguage.ru: 'Спишем {price} автоматически в конце периода',
      AppLanguage.kz: 'Кезең соңында {price} автоматты түрде есептен шығарылады',
      AppLanguage.en: 'We\'ll charge {price} automatically at the end of the period',
    },
    'subscription_auto_renew_off_body': {
      AppLanguage.ru: 'Подписка не будет продлена автоматически',
      AppLanguage.kz: 'Жазылым автоматты түрде жаңартылмайды',
      AppLanguage.en: 'Your subscription will not renew automatically',
    },

    // Google-вход
    'google_continue': {
      AppLanguage.ru: 'Продолжить с Google',
      AppLanguage.kz: 'Google арқылы жалғастыру',
      AppLanguage.en: 'Continue with Google',
    },

    // Редактирование профиля
    'profile_save_success': {AppLanguage.ru: 'Сохранено', AppLanguage.kz: 'Сақталды', AppLanguage.en: 'Saved'},
    'profile_save_error': {
      AppLanguage.ru: 'Ошибка сохранения: {error}',
      AppLanguage.kz: 'Сақтау қатесі: {error}',
      AppLanguage.en: 'Save failed: {error}',
    },
    'profile_photo_upload_error': {
      AppLanguage.ru: 'Ошибка загрузки фото: {error}',
      AppLanguage.kz: 'Фотоны жүктеу қатесі: {error}',
      AppLanguage.en: 'Photo upload failed: {error}',
    },
    'profile_password_too_short': {
      AppLanguage.ru: 'Минимум 6 символов',
      AppLanguage.kz: 'Кемінде 6 таңба',
      AppLanguage.en: 'At least 6 characters',
    },
    'profile_password_changed': {
      AppLanguage.ru: 'Пароль изменён',
      AppLanguage.kz: 'Құпия сөз өзгертілді',
      AppLanguage.en: 'Password changed',
    },
    'profile_delete_confirm_title': {
      AppLanguage.ru: 'Удалить аккаунт?',
      AppLanguage.kz: 'Аккаунтты жою керек пе?',
      AppLanguage.en: 'Delete account?',
    },
    'profile_delete_confirm_body': {
      AppLanguage.ru: 'Аккаунт и всё избранное будут удалены безвозвратно. Это действие нельзя отменить.',
      AppLanguage.kz: 'Аккаунт пен барлық таңдаулылар қайтарылмастай жойылады. Бұл әрекетті болдырмау мүмкін емес.',
      AppLanguage.en: 'The account and all favorites will be permanently deleted. This cannot be undone.',
    },
    'profile_delete_button': {
      AppLanguage.ru: 'Удалить аккаунт',
      AppLanguage.kz: 'Аккаунтты жою',
      AppLanguage.en: 'Delete account',
    },
    'profile_section_name': {AppLanguage.ru: 'Имя', AppLanguage.kz: 'Аты', AppLanguage.en: 'Name'},
    'profile_name_hint': {AppLanguage.ru: 'Ваше имя', AppLanguage.kz: 'Атыңыз', AppLanguage.en: 'Your name'},
    'profile_save_name_button': {
      AppLanguage.ru: 'Сохранить имя',
      AppLanguage.kz: 'Атын сақтау',
      AppLanguage.en: 'Save name',
    },
    'profile_section_password': {AppLanguage.ru: 'Пароль', AppLanguage.kz: 'Құпия сөз', AppLanguage.en: 'Password'},
    'profile_new_password_hint': {
      AppLanguage.ru: 'Новый пароль (мин. 6 символов)',
      AppLanguage.kz: 'Жаңа құпия сөз (кемінде 6 таңба)',
      AppLanguage.en: 'New password (min. 6 characters)',
    },
    'profile_change_password_button': {
      AppLanguage.ru: 'Сменить пароль',
      AppLanguage.kz: 'Құпия сөзді өзгерту',
      AppLanguage.en: 'Change password',
    },
    'profile_edit_name_row': {
      AppLanguage.ru: 'Изменить имя',
      AppLanguage.kz: 'Атын өзгерту',
      AppLanguage.en: 'Change name',
    },
    'profile_change_password_row': {
      AppLanguage.ru: 'Изменить пароль',
      AppLanguage.kz: 'Құпия сөзді өзгерту',
      AppLanguage.en: 'Change password',
    },
    'change_password_old_label': {
      AppLanguage.ru: 'Текущий пароль',
      AppLanguage.kz: 'Ағымдағы құпия сөз',
      AppLanguage.en: 'Current password',
    },
    'change_password_continue_button': {
      AppLanguage.ru: 'Продолжить',
      AppLanguage.kz: 'Жалғастыру',
      AppLanguage.en: 'Continue',
    },
    'change_password_wrong_old': {
      AppLanguage.ru: 'Неверный пароль',
      AppLanguage.kz: 'Құпия сөз дұрыс емес',
      AppLanguage.en: 'Incorrect password',
    },
    'change_password_verified': {
      AppLanguage.ru: 'Пароль верный',
      AppLanguage.kz: 'Құпия сөз дұрыс',
      AppLanguage.en: 'Password correct',
    },
    'change_password_new_label': {
      AppLanguage.ru: 'Новый пароль',
      AppLanguage.kz: 'Жаңа құпия сөз',
      AppLanguage.en: 'New password',
    },
    'change_password_confirm_label': {
      AppLanguage.ru: 'Повторите новый пароль',
      AppLanguage.kz: 'Жаңа құпия сөзді қайталаңыз',
      AppLanguage.en: 'Confirm new password',
    },
    'change_password_mismatch': {
      AppLanguage.ru: 'Пароли не совпадают',
      AppLanguage.kz: 'Құпия сөздер сәйкес келмейді',
      AppLanguage.en: 'Passwords don\'t match',
    },
    'change_password_match': {
      AppLanguage.ru: 'Пароли совпадают',
      AppLanguage.kz: 'Құпия сөздер сәйкес келеді',
      AppLanguage.en: 'Passwords match',
    },
    'change_password_save_button': {
      AppLanguage.ru: 'Сохранить новый пароль',
      AppLanguage.kz: 'Жаңа құпия сөзді сақтау',
      AppLanguage.en: 'Save new password',
    },
    'profile_danger_zone_title': {
      AppLanguage.ru: 'Опасная зона',
      AppLanguage.kz: 'Қауіпті аймақ',
      AppLanguage.en: 'Danger zone',
    },
    'profile_danger_zone_body': {
      AppLanguage.ru: 'Аккаунт и всё избранное будут удалены безвозвратно.',
      AppLanguage.kz: 'Аккаунт пен барлық таңдаулылар қайтарылмастай жойылады.',
      AppLanguage.en: 'The account and all favorites will be permanently deleted.',
    },

    // Сообщить об ошибке (диалог)
    'report_error_empty': {
      AppLanguage.ru: 'Опишите, что именно не так',
      AppLanguage.kz: 'Нақты не дұрыс емес екенін сипаттаңыз',
      AppLanguage.en: 'Describe what is wrong',
    },
    'report_success': {
      AppLanguage.ru: 'Спасибо! Мы получили ваше сообщение.',
      AppLanguage.kz: 'Рахмет! Хабарламаңызды алдық.',
      AppLanguage.en: 'Thanks! We received your message.',
    },
    'report_send_error': {
      AppLanguage.ru: 'Не удалось отправить: {error}',
      AppLanguage.kz: 'Жіберу мүмкін болмады: {error}',
      AppLanguage.en: 'Failed to send: {error}',
    },
    'report_dialog_title': {
      AppLanguage.ru: 'Сообщить об ошибке',
      AppLanguage.kz: 'Қате туралы хабарлау',
      AppLanguage.en: 'Report an issue',
    },
    'report_dialog_body': {
      AppLanguage.ru: 'Опишите, какая информация неверна или устарела.',
      AppLanguage.kz: 'Қай ақпарат дұрыс емес немесе ескіргенін сипаттаңыз.',
      AppLanguage.en: 'Describe which information is incorrect or outdated.',
    },
    'report_hint': {
      AppLanguage.ru: 'Например: этот ЖК уже достроен и сдан...',
      AppLanguage.kz: 'Мысалы: бұл ЖК қазірдің өзінде салынып, тапсырылған...',
      AppLanguage.en: 'E.g.: this development is already built and handed over...',
    },
    'report_send_button': {
      AppLanguage.ru: 'Отправить',
      AppLanguage.kz: 'Жіберу',
      AppLanguage.en: 'Send',
    },

    // О приложении
    'about_version': {
      AppLanguage.ru: 'Версия 0.1.0',
      AppLanguage.kz: 'Нұсқасы 0.1.0',
      AppLanguage.en: 'Version 0.1.0',
    },
    'about_description': {
      AppLanguage.ru: 'Шаңырақ — купольное навершие юрты, символ дома и семьи. Так и это приложение: прежде чем назвать что-то домом, стоит убедиться, что это безопасно. Мы показываем на карте проблемные жилые комплексы Алматы («красная зона») и объекты, завершённые под госгарантией — чтобы вы видели риски заранее, а не после сделки.',
      AppLanguage.kz: 'Шаңырақ — киіз үйдің күмбез тәрізді жоғарғы бөлігі, үй мен отбасының символы. Осы қолданба да солай: бір нәрсені үй деп атамас бұрын, оның қауіпсіз екеніне көз жеткізген жөн. Біз картада Алматының проблемалы тұрғын үй кешендерін («қызыл аймақ») және мемлекеттік кепілдікпен аяқталған нысандарды көрсетеміз — тәуекелдерді мәміледен кейін емес, алдын ала көру үшін.',
      AppLanguage.en: 'Shanyraq is the dome-shaped crown of a yurt — a symbol of home and family. This app follows the same idea: before calling something home, make sure it\'s safe. We show Almaty\'s problematic residential complexes ("red zone") and state-guarantee-completed developments on the map, so you see the risks before the deal, not after.',
    },
    'about_data_source_heading': {
      AppLanguage.ru: 'Источник данных',
      AppLanguage.kz: 'Деректер көзі',
      AppLanguage.en: 'Data source',
    },
    'about_data_source_body': {
      AppLanguage.ru: 'Список проблемных объектов и объектов под госгарантией собран на основе официальных отчётов по долевому строительству Алматы. Данные могут устаревать — при обнаружении неточности напишите нам.',
      AppLanguage.kz: 'Проблемалы нысандар мен мемлекеттік кепілдіктегі нысандар тізімі Алматының үлестік құрылыс бойынша ресми есептері негізінде жиналған. Деректер ескіруі мүмкін — дәлсіздік байқасаңыз, бізге жазыңыз.',
      AppLanguage.en: 'The list of problematic and state-guaranteed developments is compiled from official reports on shared construction in Almaty. Data may become outdated — if you spot an inaccuracy, please let us know.',
    },
    'about_call_support': {
      AppLanguage.ru: 'Позвонить в поддержку',
      AppLanguage.kz: 'Қолдау қызметіне қоңырау шалу',
      AppLanguage.en: 'Call support',
    },
    'about_email_support': {
      AppLanguage.ru: 'Написать в поддержку',
      AppLanguage.kz: 'Қолдау қызметіне жазу',
      AppLanguage.en: 'Email support',
    },
    'about_privacy_policy': {
      AppLanguage.ru: 'Политика конфиденциальности',
      AppLanguage.kz: 'Құпиялылық саясаты',
      AppLanguage.en: 'Privacy policy',
    },
    'about_terms': {
      AppLanguage.ru: 'Пользовательское соглашение',
      AppLanguage.kz: 'Пайдаланушы келісімі',
      AppLanguage.en: 'Terms of service',
    },

    // Пользовательское соглашение
    'terms_s1_title': {
      AppLanguage.ru: '1. О приложении',
      AppLanguage.kz: '1. Қолданба туралы',
      AppLanguage.en: '1. About the app',
    },
    'terms_s1_body': {
      AppLanguage.ru: 'Шаңырақ даёт справочную информацию по ЖК Алматы на основе открытых отчётов. Это не юридическая консультация и не гарантия.',
      AppLanguage.kz: 'Шаңырақ ашық есептер негізінде Алматы ЖК-лары бойынша анықтамалық ақпарат береді. Бұл заңды кеңес немесе кепілдік емес.',
      AppLanguage.en: 'Shanyraq gives reference info on Almaty developments based on public reports. It is not legal advice or a guarantee.',
    },
    'terms_s2_title': {
      AppLanguage.ru: '2. Точность данных',
      AppLanguage.kz: '2. Деректердің дәлдігі',
      AppLanguage.en: '2. Data accuracy',
    },
    'terms_s2_body': {
      AppLanguage.ru: 'Данные могут быть неполными или устаревшими. Перед покупкой проверяйте важные детали в официальных источниках.',
      AppLanguage.kz: 'Деректер толық емес немесе ескірген болуы мүмкін. Сатып алу алдында маңызды мәліметтерді ресми көздерден тексеріңіз.',
      AppLanguage.en: 'Data may be incomplete or outdated. Verify important details in official sources before buying.',
    },
    'terms_s3_title': {AppLanguage.ru: '3. Подписка', AppLanguage.kz: '3. Жазылым', AppLanguage.en: '3. Subscription'},
    'terms_s3_body': {
      AppLanguage.ru: 'Детали по объекту — платно, по подписке. Она продлевается автоматически, отменить можно в любой момент в разделе «Подписка».',
      AppLanguage.kz: 'Нысан бойынша мәліметтер — ақылы, жазылым арқылы. Ол автоматты жаңартылады, кез келген уақытта «Жазылым» бөлімінде тоқтата аласыз.',
      AppLanguage.en: 'Development details are paid, via subscription. It renews automatically; cancel anytime in the Subscription section.',
    },
    'terms_s4_title': {
      AppLanguage.ru: '4. Ответственность',
      AppLanguage.kz: '4. Жауапкершілік',
      AppLanguage.en: '4. Liability',
    },
    'terms_s4_body': {
      AppLanguage.ru: 'Мы не отвечаем за решения, принятые на основе наших данных. Финальную проверку застройщика и объекта вы делаете сами.',
      AppLanguage.kz: 'Біздің деректер негізінде қабылданған шешімдерге жауап бермейміз. Құрылысшы мен нысанды соңғы тексеруді өзіңіз жасайсыз.',
      AppLanguage.en: 'We are not liable for decisions based on our data. You are responsible for the final check of the developer and the property.',
    },
    'terms_s5_title': {
      AppLanguage.ru: '5. Изменения соглашения',
      AppLanguage.kz: '5. Келісімге өзгерістер',
      AppLanguage.en: '5. Changes to the agreement',
    },
    'terms_s5_body': {
      AppLanguage.ru: 'Условия могут меняться. Продолжая пользоваться приложением, вы принимаете новую версию.',
      AppLanguage.kz: 'Шарттар өзгеруі мүмкін. Қолданбаны пайдалануды жалғастырып, жаңа нұсқаны қабылдайсыз.',
      AppLanguage.en: 'Terms may change. Continuing to use the app means you accept the new version.',
    },

    // Политика конфиденциальности
    'privacy_s1_title': {
      AppLanguage.ru: '1. Какие данные мы собираем',
      AppLanguage.kz: '1. Біз қандай деректерді жинаймыз',
      AppLanguage.en: '1. What data we collect',
    },
    'privacy_s1_body': {
      AppLanguage.ru: 'Email, пароль (зашифрован), избранное и статус подписки. Геолокацию используем только локально, с вашего разрешения — никуда не отправляем.',
      AppLanguage.kz: 'Email, құпия сөз (шифрланған), таңдаулылар және жазылым мәртебесі. Геолокацияны тек жергілікті түрде, рұқсатыңызбен қолданамыз — ешқайда жібермейміз.',
      AppLanguage.en: 'Email, password (encrypted), favorites, and subscription status. Location is used only locally, with your permission — never sent anywhere.',
    },
    'privacy_s2_title': {
      AppLanguage.ru: '2. Как мы используем данные',
      AppLanguage.kz: '2. Деректерді қалай пайдаланамыз',
      AppLanguage.en: '2. How we use data',
    },
    'privacy_s2_body': {
      AppLanguage.ru: 'Только для входа, работы избранного и вопросов по подписке. Не продаём и не передаём данные третьим лицам.',
      AppLanguage.kz: 'Тек кіру, таңдаулылар және жазылым мәселелері үшін. Деректерді сатпаймыз және үшінші тұлғаларға бермейміз.',
      AppLanguage.en: 'Only for sign-in, favorites, and subscription matters. We never sell or share your data with third parties.',
    },
    'privacy_s3_title': {
      AppLanguage.ru: '3. Хранение данных',
      AppLanguage.kz: '3. Деректерді сақтау',
      AppLanguage.en: '3. Data storage',
    },
    'privacy_s3_body': {
      AppLanguage.ru: 'Храним на серверах Supabase. Удалить аккаунт и все данные можно в любой момент: Профиль → Редактировать профиль → Удалить аккаунт.',
      AppLanguage.kz: 'Supabase серверлерінде сақтаймыз. Аккаунтты және барлық деректерді кез келген уақытта жоя аласыз: Профиль → Профильді өңдеу → Аккаунтты жою.',
      AppLanguage.en: 'Stored on Supabase servers. Delete your account and all data anytime: Profile → Edit profile → Delete account.',
    },
    'privacy_s4_title': {
      AppLanguage.ru: '4. Ваши права',
      AppLanguage.kz: '4. Сіздің құқықтарыңыз',
      AppLanguage.en: '4. Your rights',
    },
    'privacy_s4_body': {
      AppLanguage.ru: 'Можете запросить, исправить или удалить свои данные в любой момент. Вопросы — на shanyraqsend@gmail.com.',
      AppLanguage.kz: 'Деректеріңізді кез келген уақытта сұрата, түзете немесе жоя аласыз. Сұрақтар — shanyraqsend@gmail.com.',
      AppLanguage.en: 'You can request, correct, or delete your data anytime. Questions — shanyraqsend@gmail.com.',
    },
    'privacy_s5_title': {
      AppLanguage.ru: '5. Изменения политики',
      AppLanguage.kz: '5. Саясатқа өзгерістер',
      AppLanguage.en: '5. Changes to this policy',
    },
    'privacy_s5_body': {
      AppLanguage.ru: 'Политика может обновляться. О важных изменениях сообщим в приложении.',
      AppLanguage.kz: 'Саясат жаңартылуы мүмкін. Маңызды өзгерістер туралы қолданбада хабарлаймыз.',
      AppLanguage.en: 'This policy may change. We\'ll notify you in-app about important updates.',
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
