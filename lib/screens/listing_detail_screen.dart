import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/listing.dart';
import '../services/auth_service.dart';
import '../services/listing_repository.dart';
import '../services/profile_service.dart';
import '../widgets/zhk_photo_thumbnail.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

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

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('listing_delete_confirm_title')),
        content: Text(context.tr('listing_delete_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ListingRepository().softDelete(listing.id);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('generic_error', {'error': '$e'}))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileService>();
    final auth = context.watch<AuthService>();
    final canManage = profile.isAdmin || listing.ownerId == auth.currentUser?.id;

    final details = <String>[
      if (listing.rooms != null) context.tr('listing_rooms_short', {'n': '${listing.rooms}'}),
      if (listing.areaSqm != null) context.tr('listing_area_short', {'n': _formatArea(listing.areaSqm!)}),
    ].join(' · ');
    final location = [listing.district, listing.address].whereType<String>().join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.tr('delete'),
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: ZhkPhotoThumbnail(photoUrl: listing.photoUrl, iconSize: 56),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.price != null)
                  Text(_formatPrice(listing.price),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(listing.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 8),
                if (details.isNotEmpty)
                  Text(details, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 17, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${listing.city}, $location',
                            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ],
                if (listing.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Text(listing.description!, style: const TextStyle(fontSize: 14.5, height: 1.45)),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.contactName?.isNotEmpty == true
                                  ? listing.contactName!
                                  : context.tr('listing_owner_fallback'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            Text(listing.phone,
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: listing.phone.replaceAll(' ', ''))),
                        icon: const Icon(Icons.call_outlined, size: 17),
                        label: Text(context.tr('listing_call_button')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(context.tr('listing_detail_disclaimer'),
                            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatArea(double area) =>
      area == area.roundToDouble() ? area.toInt().toString() : area.toStringAsFixed(1);
}
