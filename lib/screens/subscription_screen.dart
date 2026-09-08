import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../services/profile_service.dart';
import '../widgets/app_logo.dart';

const _supportPhone = '+7 771 470 72 22';
const _supportEmail = 'shanyraqsend@gmail.com';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static List<(String, String, IconData)> _benefits(BuildContext context) => [
        (context.tr('sub_benefit_status_title'), context.tr('sub_benefit_status_subtitle'),
            Icons.location_on_outlined),
        (context.tr('sub_benefit_docs_title'), context.tr('sub_benefit_docs_subtitle'),
            Icons.description_outlined),
        (context.tr('sub_benefit_violations_title'), context.tr('sub_benefit_violations_subtitle'),
            Icons.gavel_outlined),
        (context.tr('sub_benefit_court_title'), context.tr('sub_benefit_court_subtitle'),
            Icons.balance_outlined),
        (context.tr('sub_benefit_notifications_title'), context.tr('sub_benefit_notifications_subtitle'),
            Icons.notifications_active_outlined),
      ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscription_title'))),
      body: SafeArea(
        child: profile.isSubscribed ? _buildActive(context, profile, colorScheme) : _buildPaywall(context, profile, colorScheme),
      ),
    );
  }

  Widget _buildActive(BuildContext context, ProfileService profile, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('subscription_active_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('subscription_active_body'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 28),
        _PaymentMethodCard(profile: profile),
        const SizedBox(height: 12),
        _AutoRenewCard(profile: profile),
        const SizedBox(height: 28),
        ..._benefits(context).map((b) => _BenefitRow(title: b.$1, subtitle: b.$2, icon: b.$3, unlocked: true)),
      ],
    );
  }

  Widget _buildPaywall(BuildContext context, ProfileService profile, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        const Center(child: AppLogo(size: 64)),
        const SizedBox(height: 20),
        Text(
          context.tr('subscription_paywall_heading'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('subscription_paywall_body'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 28),
        ..._benefits(context).map((b) => _BenefitRow(title: b.$1, subtitle: b.$2, icon: b.$3, unlocked: false)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('subscription_price_label'),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(context.tr('subscription_price_value'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.workspace_premium, color: colorScheme.primary, size: 32),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _subscribe(context),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(context.tr('subscription_subscribe_button')),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
            child: Text(context.tr('subscription_support_link')),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribe(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FakePaymentDialog(),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final ProfileService profile;
  const _PaymentMethodCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isApple = profile.paymentMethod == 'apple';
    final label = isApple
        ? context.tr('subscription_pay_apple')
        : '•••• •••• •••• ${profile.cardLast4 ?? '••••'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isApple ? Icons.apple : Icons.credit_card, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('subscription_payment_method_label'),
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRenewCard extends StatelessWidget {
  final ProfileService profile;
  const _AutoRenewCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('subscription_auto_renew_title'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  profile.autoRenew
                      ? context.tr('subscription_auto_renew_on_body',
                          {'price': context.tr('subscription_price_value')})
                      : context.tr('subscription_auto_renew_off_body'),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: profile.autoRenew,
            onChanged: (v) => profile.setAutoRenew(v),
          ),
        ],
      ),
    );
  }
}

/// Имитация оплаты: пока не подключён настоящий платёжный шлюз, просто
/// показываем выбор способа оплаты и анимацию процесса, затем помечаем
/// пользователя подписанным. Когда появится реальный API — вызывать
/// активацию из подтверждения платежа (вебхук), а не сразу по кнопке.
class _FakePaymentDialog extends StatefulWidget {
  const _FakePaymentDialog();

  @override
  State<_FakePaymentDialog> createState() => _FakePaymentDialogState();
}

enum _PayPhase { choose, cardForm, processing, success, error }

class _FakePaymentDialogState extends State<_FakePaymentDialog> {
  _PayPhase _phase = _PayPhase.choose;
  final _cardController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _chooseCard() => setState(() => _phase = _PayPhase.cardForm);

  Future<void> _chooseApple() async {
    setState(() => _phase = _PayPhase.processing);
    await _finish(method: 'apple');
  }

  Future<void> _payWithCard() async {
    final digits = _cardController.text.replaceAll(' ', '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    setState(() => _phase = _PayPhase.processing);
    await _finish(method: 'card', cardLast4: last4);
  }

  Future<void> _finish({required String method, String? cardLast4}) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    try {
      await context.read<ProfileService>().activateSubscription(method: method, cardLast4: cardLast4);
      if (!mounted) return;
      setState(() => _phase = _PayPhase.success);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _phase = _PayPhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildPhase(context),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context) {
    switch (_phase) {
      case _PayPhase.choose:
        return _buildChoose(context);
      case _PayPhase.cardForm:
        return _buildCardForm(context);
      case _PayPhase.processing:
        return _buildProcessing(context);
      case _PayPhase.success:
        return _buildSuccess(context);
      case _PayPhase.error:
        return _buildError(context);
    }
  }

  Widget _buildChoose(BuildContext context) {
    return Column(
      key: const ValueKey('choose'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr('subscription_choose_payment'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.credit_card, size: 20),
            label: Text(context.tr('subscription_pay_card')),
            onPressed: _chooseCard,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.apple, size: 22),
            label: Text(context.tr('subscription_pay_apple')),
            onPressed: _chooseApple,
          ),
        ),
      ],
    );
  }

  Widget _buildCardForm(BuildContext context) {
    return Column(
      key: const ValueKey('card'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('subscription_pay_card'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _cardController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: context.tr('subscription_card_number_hint'),
            hintText: '0000 0000 0000 0000',
            prefixIcon: const Icon(Icons.credit_card, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _cardController.text.replaceAll(' ', '').length == 16 ? _payWithCard : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(context.tr('subscription_pay_button')),
        ),
      ],
    );
  }

  Widget _buildProcessing(BuildContext context) {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 16),
        Text(context.tr('payment_processing'), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(context.tr('payment_success'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(context.tr('payment_error', {'error': '$_error'}), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }
}

/// Форматирует ввод номера карты группами по 4 цифры: 0000 0000 0000 0000.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;

  const _BenefitRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = unlocked ? const Color(0xFF22C55E) : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, size: 20, color: Color(0xFF22C55E))
          else
            Icon(Icons.lock_outline, size: 18, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
