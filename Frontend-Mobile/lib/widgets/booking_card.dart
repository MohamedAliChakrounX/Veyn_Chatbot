import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../models/trip.dart';
import '../providers/language_provider.dart';
import '../theme/colors.dart';
import 'stops_timeline.dart';

class BookingCard extends StatefulWidget {
  final BookingSummary booking;

  const BookingCard({super.key, required this.booking});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _stopsOpen = false;
  bool _copied = false;

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.booking.reference));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isRtl = context.isRtl;
    final lang = context.watch<LanguageProvider>().languageCode;
    final travelers = b.travelers;

    final localizedStops = b.result.stops.map((s) => TripStop(
      name: localizeCityName(s.name, lang),
      place: s.place,
      time: s.time,
      kind: s.kind,
      waitMinutes: s.waitMinutes,
    )).toList();

    final travelersLabel = travelers == 1
        ? '1 ${context.tr('traveler_singular')}'
        : '$travelers ${context.tr('traveler_plural')}';

    final extraLabel = b.travelersLabel != null ? ' (${b.travelersLabel})' : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: VeynColors.successSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeynColors.successBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ─── En-tête vert ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: VeynColors.success,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('success_header'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${b.total.toStringAsFixed(b.total.truncateToDouble() == b.total ? 0 : 2)} ${b.currency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // ─── Corps du récapitulatif ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Référence dossier
                Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('ref_prefix'),
                        style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: VeynColors.successBorder),
                        ),
                        child: Text(
                          b.reference,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _copyReference,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            _copied ? LucideIcons.check : LucideIcons.copy,
                            size: 14,
                            color: _copied ? VeynColors.success : VeynColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Trajet & Opérateur
                Text(
                  b.routeLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: VeynColors.ink,
                  ),
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.result.operator} · ${b.result.departure} → ${b.result.arrival} (${b.result.durationLabel})',
                  style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                ),

                const SizedBox(height: 10),
                const Divider(color: VeynColors.successBorder, height: 1),
                const SizedBox(height: 10),

                // Voyageurs
                _infoRow(
                  context: context,
                  icon: LucideIcons.users,
                  text: '$travelersLabel$extraLabel',
                  isRtl: isRtl,
                ),
                const SizedBox(height: 6),

                // Point de montée
                _infoRow(
                  context: context,
                  icon: LucideIcons.mapPin,
                  label: context.tr('boarding_label'),
                  text: '${localizeCityName(b.boardingStop.name, lang)}${b.boardingStop.place.isNotEmpty ? ' (${b.boardingStop.place})' : ''}',
                  isRtl: isRtl,
                  expand: true,
                  maxLines: 1,
                ),

                // Paiement
                if (b.paymentMethod != null) ...[
                  const SizedBox(height: 6),
                  _infoRow(
                    context: context,
                    icon: LucideIcons.creditCard,
                    label: context.tr('payment_label'),
                    text: b.paymentMethod!,
                    isRtl: isRtl,
                  ),
                ],

                // Bouton Déplier les arrêts
                if (b.result.stops.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setState(() => _stopsOpen = !_stopsOpen),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Icon(
                          _stopsOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 14,
                          color: VeynColors.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _stopsOpen
                                ? context.tr('hide_itinerary')
                                : context.tr('show_itinerary'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: VeynColors.success,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_stopsOpen) ...[
                    const SizedBox(height: 8),
                    StopsTimeline(stops: localizedStops),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    String? label,
    required String text,
    required bool isRtl,
    bool expand = false,
    int maxLines = 2,
  }) {
    final textWidget = Text(
      '${label ?? ''}$text',
      style: const TextStyle(fontSize: 12, color: VeynColors.inkSoft),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
    );

    return Row(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: VeynColors.inkMuted),
        const SizedBox(width: 6),
        expand ? Expanded(child: textWidget) : Flexible(child: textWidget),
      ],
    );
  }
}
