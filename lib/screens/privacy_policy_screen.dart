import 'package:flutter/material.dart';

/// Черновик политики конфиденциальности. Перед публикацией в App Store /
/// Google Play и реальным запуском подписки — отдать на проверку юристу.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: '1. Какие данные мы собираем',
            body:
                'При регистрации мы сохраняем ваш email и пароль (в зашифрованном виде, '
                'через Supabase Auth). При использовании приложения мы сохраняем список '
                'ЖК, добавленных вами в избранное, и статус подписки. Мы не собираем '
                'геолокацию без вашего явного разрешения — она используется только '
                'локально для отображения вашего положения на карте и никуда не отправляется.',
          ),
          _Section(
            title: '2. Как мы используем данные',
            body:
                'Email используется для входа в аккаунт и связи с вами по вопросам '
                'подписки. Список избранного хранится, чтобы вы могли вернуться к нему '
                'позже. Мы не продаём и не передаём ваши данные третьим лицам.',
          ),
          _Section(
            title: '3. Хранение данных',
            body:
                'Данные хранятся на серверах Supabase. Вы можете удалить аккаунт и все '
                'связанные данные в любой момент через Профиль → Редактировать профиль → '
                'Удалить аккаунт.',
          ),
          _Section(
            title: '4. Ваши права',
            body:
                'Вы можете запросить копию своих данных, исправить их или удалить '
                'аккаунт полностью в любое время. Для вопросов пишите на '
                'nurbeekovn@gmail.com.',
          ),
          _Section(
            title: '5. Изменения политики',
            body:
                'Мы можем обновлять эту политику. О существенных изменениях сообщим '
                'внутри приложения.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
