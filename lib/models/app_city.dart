/// Города, которые поддерживает приложение.
///
/// Это фиксированный список, а не значения из БД: добавление города —
/// ручной продуктовый шаг (нужен отдельный реестр ЖК по красной зоне/
/// госгарантии для этого города), а не то, что пользователи создают сами.
/// Канонические значения храним на русском (как и названия районов) —
/// они пишутся напрямую в zhk.city / listings.city, независимо от
/// выбранного языка интерфейса; на экране переводится только их подпись
/// через l10n-ключи ниже.
class AppCity {
  static const almaty = 'Алматы';
  static const astana = 'Астана';
  static const shymkent = 'Шымкент';

  static const List<String> all = [almaty, astana, shymkent];

  /// l10n-ключ для отображаемого названия города.
  static String labelKey(String city) => switch (city) {
        almaty => 'city_almaty',
        astana => 'city_astana',
        shymkent => 'city_shymkent',
        _ => 'city_almaty',
      };
}
