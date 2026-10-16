import 'package:flutter/widgets.dart';

/// Порог ширины, с которого показываем десктоп-раскладку (сайдбар +
/// широкий контент) вместо мобильной (нижняя навигация). Покрывает
/// ноутбуки и iPad в портретной ориентации (820px) и шире.
const double kDesktopBreakpoint = 820;

bool isDesktopWidth(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;
