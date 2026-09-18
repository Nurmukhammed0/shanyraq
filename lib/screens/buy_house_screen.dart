import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/listing.dart';
import '../services/auth_service.dart';
import '../services/listing_repository.dart';
import '../services/profile_service.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/zhk_photo_thumbnail.dart';
import 'listing_detail_screen.dart';
import 'listing_edit_screen.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

/// «Купить дом»: объявления, которые добавляют сами собственники
/// (доступно только с подпиской). Мы не проверяем документы и
/// договорённости по этим объявлениям — см. дисклеймер в интерфейсе.
class BuyHouseScreen extends StatefulWidget {
  const BuyHouseScreen({super.key});

  @override
  State<BuyHouseScreen> createState() => _BuyHouseScreenState();
}

class _BuyHouseScreenState extends State<BuyHouseScreen> {
  final _repo = ListingRepository();
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchAll();
      if (!mounted) return;
      setState(() {
        _listings = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _onAddPressed() async {
    final auth = context.read<AuthService>();
    final profile = context.read<ProfileService>();
    if (!auth.isLoggedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (!profile.isSubscribed) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ListingEditScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileService>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('home_buy_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.tr('favorites_load_error', {'error': _error!})),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(context.tr('buy_house_disclaimer'),
                                  style: TextStyle(
                                      fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_listings.isEmpty)
                        _buildEmpty(context)
                      else
                        ..._listings.map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ListingCard(listing: l),
                            )),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPressed,
        icon: Icon(profile.isSubscribed ? Icons.add : Icons.lock_outline),
        label: Text(context.tr('buy_house_add_button')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmptyStateIllustration(badgeIcon: Icons.home_work_outlined),
          const SizedBox(height: 20),
          Text(context.tr('buy_house_empty_title'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(context.tr('buy_house_empty_body'),
              textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  const _ListingCard({required this.listing});

  String _formatPrice(double? price) {
    if (price == null) return '';
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} ₸';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final details = <String>[
      if (listing.rooms != null) context.tr('listing_rooms_short', {'n': '${listing.rooms}'}),
      if (listing.areaSqm != null)
        context.tr('listing_area_short',
            {'n': listing.areaSqm! == listing.areaSqm!.roundToDouble()
                ? listing.areaSqm!.toInt().toString()
                : listing.areaSqm!.toStringAsFixed(1)}),
    ].join(' · ');
    final location = [listing.district, listing.address].whereType<String>().join(', ');

    return Material(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ZhkPhotoThumbnail(photoUrl: listing.photoUrl, width: 84, height: 84),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (listing.price != null)
                      Text(_formatPrice(listing.price),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(details, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
