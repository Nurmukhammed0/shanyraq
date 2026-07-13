import 'package:flutter/material.dart';

/// Черновик пользовательского соглашения. Перед публикацией в сторы —
/// отдать на проверку юристу.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользовательское соглашение')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: '1. О приложении',
            body:
                'Приложение «Шаңырақ» предоставляет справочную информацию о статусе '
                'жилых комплексов Алматы на основе открытых официальных отчётов. '
                'Информация носит справочный характер и не является юридической '
                'консультацией или гарантией.',
          ),
          _Section(
            title: '2. Точность данных',
            body:
                'Мы стараемся поддерживать данные актуальными, но не гарантируем их '
                'полноту и абсолютную точность на момент просмотра. Перед принятием '
                'решения о покупке недвижимости рекомендуем проверить информацию '
                'самостоятельно в официальных источниках.',
          ),
          _Section(
            title: '3. Подписка',
            body:
                'Часть информации (детали по объекту) доступна по платной подписке. '
                'Условия оплаты и активации подписки могут уточняться индивидуально до '
                'запуска автоматического платежа в приложении.',
          ),
          _Section(
            title: '4. Ответственность',
            body:
                'Приложение не несёт ответственности за решения, принятые на основе '
                'предоставленной информации. Используя приложение, вы соглашаетесь, что '
                'окончательную проверку любых сведений о застройщике и объекте вы '
                'проводите самостоятельно.',
          ),
          _Section(
            title: '5. Изменения соглашения',
            body:
                'Мы можем обновлять условия использования. Продолжая пользоваться '
                'приложением после обновления, вы соглашаетесь с новой редакцией.',
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
