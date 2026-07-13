# ЖК Алматы — карта проблемных и надёжных объектов

## Что уже готово
- Данные: `assets/almaty_zhk_data.json` — 28 проблемных ЖК + 10 завершённых
  под госгарантией (пока БЕЗ координат lat/lng — нужно геокодирование).
- Карта на flutter_map (OpenStreetMap) — не зависит от Google.
- Фильтр по статусу (все / красная зона / гарантия) и по району.
- Логин / регистрация через Supabase Auth (email + пароль).
- Избранное: сохраняется в таблице `favorites` в Supabase, привязано к
  пользователю через Row Level Security.
- Экран деталей ЖК со всей информацией из документов.

## Что нужно сделать перед запуском

### 1. Создать проект Supabase
1. https://supabase.com -> New Project (либо разверните self-hosted:
   https://supabase.com/docs/guides/self-hosting — так не будете зависеть
   от бесплатного тира supabase.com).
2. В SQL Editor выполните `supabase/schema.sql` из этого проекта.
3. В Settings -> API скопируйте `Project URL` и `anon public key`.
4. Вставьте их в `lib/main.dart` (`supabaseUrl`, `supabaseAnonKey`).
5. В Authentication -> Providers убедитесь, что Email включён.
   Можно отключить "Confirm email", чтобы регистрация работала сразу
   без письма (удобно для разработки).

### 2. Залить данные ЖК в Supabase
Пока это можно сделать вручную через Table Editor -> Import (JSON/CSV),
либо написать скрипт на Python/JS, который читает
`assets/almaty_zhk_data.json` и вставляет строки в таблицу `zhk` через
Supabase REST API. Могу подготовить такой скрипт отдельно.

### 3. Геокодирование адресов
В документах нет координат — только адреса вида "мкр. Дархан, ул.
Сабатаева, 24". Нужно прогнать все 38 адресов через геокодер и
получить lat/lng:
- 2GIS Geocoder API — точнее всего для казахстанских адресов
  (микрорайоны, "уч." и т.п.), https://docs.2gis.com/ru/api/search/geocoder/overview
- Или Google Geocoding API как запасной вариант.
Полученные координаты добавить в JSON / таблицу zhk (поля lat, lng).

### 4. Тайлы карты
Сейчас используется публичный `tile.openstreetmap.org` — подходит
для разработки, но у него строгие лимиты для продакшена. Перед
релизом в App Store замените `urlTemplate` в `lib/screens/map_screen.dart`
на:
- MapTiler (есть бесплатный тир, простая замена URL), или
- свой self-hosted тайл-сервер (OpenMapTiles + данные OSM по Казахстану) —
  максимальная независимость.

### 5. Установка и запуск
```bash
flutter pub get
flutter run
```
(для iOS — открыть `ios/Runner.xcworkspace` в Xcode для настройки
подписи перед сборкой на устройство/симулятор)

## Структура проекта
```
lib/
  main.dart                  — точка входа, инициализация Supabase
  models/zhk.dart            — модель ЖК
  services/
    auth_service.dart        — вход/регистрация/выход
    favorites_service.dart   — избранное (Supabase)
    zhk_repository.dart      — источник данных о ЖК (JSON / Supabase)
  screens/
    map_screen.dart          — главный экран: карта + фильтры
    login_screen.dart
    register_screen.dart
    zhk_detail_screen.dart
    favorites_screen.dart
supabase/schema.sql          — SQL-схема таблиц и политик доступа
assets/almaty_zhk_data.json  — данные из PDF (проблемные + гарантия)
```
