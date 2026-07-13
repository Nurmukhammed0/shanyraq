import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zhk_model.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

void showZhkDetailSheet(BuildContext context, Zhk zhk) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ZhkDetailSheet(zhk: zhk),
  );
}

class ZhkDetailSheet extends StatelessWidget {
  final Zhk zhk;
  const ZhkDetailSheet({super.key, required this.zhk});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isFavorite = appState.favoriteIds.contains(zhk.id);
    final isProblematic = zhk.status == ZhkStatus.problematic;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zhk.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      if (!AuthService().isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Войдите в аккаунт, чтобы сохранять в избранное')),
                        );
                        return;
                      }
                      await appState.toggleFavorite(zhk.id);
                    },
                  ),
                ],
              ),
              Chip(
                label: Text(isProblematic ? 'Проблемный / красная зона' : 'Завершён (гарантия дольщикам)'),
                backgroundColor: isProblematic ? Colors.red.shade100 : Colors.green.shade100,
              ),
              const SizedBox(height: 12),
              _row('Район', zhk.district),
              _row('Адрес', zhk.address),
              _row('Застройщик', zhk.developer),
              if (isProblematic) ...[
                _row('Документация', zhk.documentation),
                _row('Тех. состояние', zhk.techStatus),
                _row('Нарушения', zhk.violations),
                _row('Принятые меры', zhk.measures),
                _row('Суд', zhk.court),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}
