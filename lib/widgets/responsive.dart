import 'package:flutter/widgets.dart';

/// Порог ширины, с которого показываем десктоп-раскладку (сайдбар +
/// широкий контент) вместо мобильной (нижняя навигация). Покрывает
/// ноутбуки и iPad в портретной ориентации (820px) и шире.
const double kDesktopBreakpoint = 820;

bool isDesktopWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;

/// На десктопе ограничивает ширину содержимого экрана и центрирует его —
/// иначе мобильные экраны (формы, карточка объекта и т.п.) просто
/// растягиваются во всю ширину окна и выглядят неряшливо. На мобильном
/// (меньше kDesktopBreakpoint) ничего не меняет — отдаёт child как есть.
class DesktopConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const DesktopConstrained({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWidth(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Количество колонок для сетки карточек на широком экране — по ширине
/// доступного места, не одно жёсткое число. На мобильном вызывающий код
/// обычно просто не использует сетку, а показывает список в один столбец.
int desktopGridColumns(double width) {
  if (width >= 1500) return 4;
  if (width >= 1100) return 3;
  return 2;
}
