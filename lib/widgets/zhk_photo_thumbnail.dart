import 'package:flutter/material.dart';

/// Плейсхолдер-иконка дома, если у ЖК ещё нет фото — используется на
/// карточке объекта, превью на карте и в избранном.
class ZhkPhotoThumbnail extends StatelessWidget {
  final String? photoUrl;
  final double? width;
  final double? height;
  final double iconSize;

  const ZhkPhotoThumbnail({
    super.key,
    required this.photoUrl,
    this.width,
    this.height,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(colorScheme),
            )
          : _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.apartment, size: iconSize, color: colorScheme.onSecondaryContainer),
    );
  }
}
