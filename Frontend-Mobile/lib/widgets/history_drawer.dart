import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/conversation.dart';
import '../models/trip.dart';
import '../providers/chat_provider.dart';
import '../providers/history_provider.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../theme/colors.dart';

class HistoryDrawer extends StatefulWidget {
  final VoidCallback onNewConversation;

  const HistoryDrawer({super.key, required this.onNewConversation});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  String _search = '';

  String _groupLabel(String iso, BuildContext context) {
    try {
      final langCode = context.read<LanguageProvider>().languageCode;
      final date = DateTime.parse(iso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = today.difference(target).inDays;

      if (diff == 0) return context.tr('today_label');
      if (diff == 1) return context.tr('yesterday');
      final locale = langCode == 'ar' ? 'ar' : langCode == 'en' ? 'en_US' : 'fr_FR';
      return DateFormat('d MMMM yyyy', locale).format(date);
    } catch (_) {
      return context.tr('older');
    }
  }

  TransportMode? _detectTransportMode(Conversation conv) {
    if (conv.trip.modes.isNotEmpty) return conv.trip.modes.first;
    for (final m in conv.messages) {
      if (m.booking != null) return m.booking!.result.mode;
      if (m.results != null && m.results!.isNotEmpty) return m.results!.first.mode;
    }
    final text = '${conv.title} ${conv.routeLabel ?? ''}'.toLowerCase();
    if (text.contains('louage') || text.contains('taxi') || text.contains('shared')) return TransportMode.sharedTaxi;
    if (text.contains('bus') || text.contains('حافلة')) return TransportMode.bus;
    if (text.contains('train') || text.contains('قطار')) return TransportMode.train;
    if (text.contains('avion') || text.contains('vol') || text.contains('flight') || text.contains('طائرة')) return TransportMode.plane;
    if (text.contains('ferry') || text.contains('bateau') || text.contains('عبارة')) return TransportMode.ferry;
    return null;
  }

  IconData _modeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return LucideIcons.bus;
      case TransportMode.sharedTaxi:
        return LucideIcons.car;
      case TransportMode.train:
        return LucideIcons.train;
      case TransportMode.plane:
        return LucideIcons.plane;
      case TransportMode.ferry:
        return LucideIcons.ship;
      default:
        return LucideIcons.compass;
    }
  }

  String _modeLabel(BuildContext context, TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return context.tr('bus');
      case TransportMode.sharedTaxi:
        return context.tr('shared_taxi');
      case TransportMode.train:
        return context.tr('train');
      case TransportMode.plane:
        return context.tr('plane');
      case TransportMode.ferry:
        return context.tr('ferry');
      default:
        return context.tr('transport');
    }
  }

  String? _detectPrice(Conversation conv) {
    for (final m in conv.messages) {
      if (m.booking != null) {
        final p = m.booking!.result.price;
        final cur = m.booking!.result.currency;
        return '${p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2)} $cur';
      }
      if (m.results != null && m.results!.isNotEmpty) {
        final p = m.results!.first.price;
        final cur = m.results!.first.currency;
        return '${p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2)} $cur';
      }
    }
    if (conv.trip.budget != null) {
      return '<= ${conv.trip.budget!.toStringAsFixed(0)} DT';
    }
    return null;
  }

  void _confirmClearAll(BuildContext context) {
    final historyProvider = context.read<HistoryProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VeynColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('clear_history'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          context.tr('clear_history_confirm'),
          style: const TextStyle(fontSize: 13, color: VeynColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel'), style: const TextStyle(color: VeynColors.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              historyProvider.clearAll();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VeynColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('clear_history')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final tripProvider = context.watch<TripProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final isRtl = langProvider.isRtl;

    final normQuery = normalizeText(_search);
    final filtered = historyProvider.conversations.where((conv) {
      if (normQuery.isEmpty) return true;
      final fullText = '${conv.title} ${conv.routeLabel ?? ''}';
      return normalizeText(fullText).contains(normQuery);
    }).toList();

    // Regroupement par jour
    final grouped = <String, List<Conversation>>{};
    for (final c in filtered) {
      final label = _groupLabel(c.updatedAt, context);
      grouped.putIfAbsent(label, () => []).add(c);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = min(screenWidth * 0.86, 350.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: VeynColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête du Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(LucideIcons.history, color: VeynColors.ink, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('history_title'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: VeynColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (historyProvider.conversations.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: VeynColors.inkMuted),
                      tooltip: context.tr('clear_history'),
                      onPressed: () => _confirmClearAll(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),

            // Bouton Nouvelle recherche dans le drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(
                  context.tr('new_search'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VeynColors.ink,
                  side: const BorderSide(color: VeynColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onNewConversation();
                },
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.tr('history_search'),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: VeynColors.inkMuted),
                  filled: true,
                  fillColor: VeynColors.surfaceSunken,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: VeynColors.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),

            const Divider(height: 1, color: VeynColors.line),

            // Liste des conversations groupées
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          historyProvider.conversations.isEmpty
                              ? context.tr('history_empty')
                              : context.tr('no_results_change_date'),
                          style: const TextStyle(fontSize: 13, color: VeynColors.inkMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 6, right: 6, top: 12, bottom: 6),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: VeynColors.inkMuted,
                                ),
                              ),
                            ),
                            ...entry.value.map((conv) {
                              final isCurrent = conv.id == chatProvider.conversationId;
                              final transportMode = _detectTransportMode(conv);
                              final detectedPrice = _detectPrice(conv);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isCurrent ? VeynColors.surfaceRaised : VeynColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent ? VeynColors.accent : VeynColors.line,
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      chatProvider.openConversation(conv, tripProvider);
                                      Navigator.of(context).pop();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // ── LIGNE 1 : Titre + Badge transport en haut à droite + bouton suppression ──
                                          Row(
                                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Titre de la recherche (protégé contre l'overflow)
                                              Expanded(
                                                child: Text(
                                                  conv.title,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                                    color: VeynColors.ink,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Badge Moyen de transport (mis en valeur, coin supérieur droit)
                                              if (transportMode != null) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: VeynColors.accentSoft,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: VeynColors.accentBorder),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _modeIcon(transportMode),
                                                        size: 12,
                                                        color: VeynColors.accent,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _modeLabel(context, transportMode),
                                                        style: const TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: VeynColors.accent,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],

                                              // Bouton suppression discret
                                              InkWell(
                                                onTap: () => historyProvider.remove(conv.id),
                                                borderRadius: BorderRadius.circular(6),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(3),
                                                  child: Icon(
                                                    LucideIcons.trash2,
                                                    size: 14,
                                                    color: VeynColors.inkFaint,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // ── LIGNE 2 : Route (si disponible) + Prix (si détecté) ──
                                          if (conv.routeLabel != null || detectedPrice != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                              children: [
                                                if (conv.routeLabel != null)
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          LucideIcons.mapPin,
                                                          size: 11,
                                                          color: VeynColors.inkMuted,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            conv.routeLabel!,
                                                            style: const TextStyle(
                                                              fontSize: 11.5,
                                                              color: VeynColors.inkMuted,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (detectedPrice != null) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    detectedPrice,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: VeynColors.inkSoft,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],

                                          // ── LIGNE 3 : Badge Réservé ──
                                          if (conv.bookingCount > 0) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: VeynColors.successSoft,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: VeynColors.successBorder),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        LucideIcons.checkCircle2,
                                                        size: 10,
                                                        color: VeynColors.success,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        context.tr('booked_label'),
                                                        style: const TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: VeynColors.success,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
