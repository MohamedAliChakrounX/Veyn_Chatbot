import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/chat_message.dart';
import '../theme/colors.dart';

/// Affiche les précisions figées (immuables) associées à une question posée,
/// directement avant les cartes de résultats.
/// Toutes les puces sont en jaune ambre uniforme avec icône + texte complet.
class FrozenPrecisionsView extends StatelessWidget {
  final List<TripPrecisionItem> precisions;
  final bool isRtl;

  const FrozenPrecisionsView({
    super.key,
    required this.precisions,
    this.isRtl = false,
  });

  // Constante couleur — tout en ambre (jaune)
  static const Color _bg = VeynColors.amberSoft;
  static const Color _fg = VeynColors.amberText;

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'origin':
        return LucideIcons.mapPin;
      case 'destination':
        return LucideIcons.navigation;
      case 'date':
        return LucideIcons.calendar;
      case 'time':
        return LucideIcons.clock;
      case 'travelers':
        return LucideIcons.users;
      case 'modes':
        return LucideIcons.bus;
      case 'budget':
        return LucideIcons.wallet;
      default:
        return LucideIcons.sparkles;
    }
  }

  /// Renvoie l'icône du mode de transport à partir d'un fragment de texte (FR, EN, AR)
  IconData _iconForModeName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bus') || lower.contains('حافلة')) return LucideIcons.bus;
    if (lower.contains('train') || lower.contains('قطار')) return LucideIcons.train;
    if (lower.contains('taxi') || lower.contains('louage') || lower.contains('car') || lower.contains('voiture') || lower.contains('لواج')) {
      return LucideIcons.car;
    }
    if (lower.contains('avion') || lower.contains('plane') || lower.contains('vol') || lower.contains('طيران')) return LucideIcons.plane;
    if (lower.contains('ferry') || lower.contains('bateau') || lower.contains('ship') || lower.contains('عبّارة')) return LucideIcons.ship;
    return LucideIcons.bus;
  }

  /// Puce transport : icône + nom du mode (ex: 🚌 Bus)
  Widget _buildModeChip(String label) {
    // Si le label contient N modes (ex: "2 modes"), afficher icône générique
    final hasCountOnly = RegExp(r'^\d+\s').hasMatch(label);
    final parts = hasCountOnly
        ? <String>[]
        : label.split(RegExp(r'[·,/+]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) {
      return _chip([
        Icon(LucideIcons.bus, size: 12, color: _fg),
        const SizedBox(width: 4),
        Text(label, style: _textStyle),
      ]);
    }

    final children = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('+', style: TextStyle(fontSize: 10, color: _fg, fontWeight: FontWeight.bold)),
        ));
      }
      children.add(Icon(_iconForModeName(parts[i]), size: 12, color: _fg));
      children.add(const SizedBox(width: 4));
      children.add(Text(parts[i], style: _textStyle));
    }
    return _chip(children);
  }

  /// Puce voyageurs : icônes spécifiques distinctes par type (adulte, enfant, personne handicapée/PMR)
  Widget _buildTravelersChip(String label) {
    final adultMatch = RegExp(r'(\d+)\s*(?:ad(?:ulte?s?)?|adult[se]?|بالغ(?:ين)?)\b', caseSensitive: false).firstMatch(label);
    final childMatch = RegExp(r'(\d+)\s*(?:enf(?:ant[se]?)?|child(?:ren)?|أطفال|طفل)\b', caseSensitive: false).firstMatch(label);
    final assistMatch = RegExp(r'(\d+)\s*(?:pmr|assist(?:ed)?|handicap|احتياجات|مرافق)\b', caseSensitive: false).firstMatch(label);

    final children = <Widget>[];

    void addType(IconData icon, int count) {
      if (children.isNotEmpty) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('·', style: TextStyle(fontSize: 10, color: _fg, fontWeight: FontWeight.bold)),
        ));
      }
      children.add(Text('$count', style: _textStyle));
      children.add(const SizedBox(width: 3));
      children.add(Icon(icon, size: 12, color: _fg));
    }

    if (adultMatch != null) {
      addType(LucideIcons.user, int.tryParse(adultMatch.group(1) ?? '1') ?? 1);
    }
    if (childMatch != null) {
      addType(LucideIcons.baby, int.tryParse(childMatch.group(1) ?? '1') ?? 1);
    }
    if (assistMatch != null) {
      addType(LucideIcons.accessibility, int.tryParse(assistMatch.group(1) ?? '1') ?? 1);
    }

    if (children.isEmpty) {
      children.add(Icon(LucideIcons.users, size: 12, color: _fg));
      children.add(const SizedBox(width: 4));
      children.add(Text(label, style: _textStyle));
    }

    return _chip(children);
  }

  static TextStyle get _textStyle => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _fg,
    height: 1.2,
  );

  Widget _chip(List<Widget> children) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 5, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (precisions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: precisions.map((precision) {
            if (precision.field == 'modes') {
              return _buildModeChip(precision.label);
            }
            if (precision.field == 'travelers') {
              return _buildTravelersChip(precision.label);
            }
            // Puce standard : icône + texte complet
            return _chip([
              Icon(_getFieldIcon(precision.field), size: 11, color: _fg),
              const SizedBox(width: 4),
              Text(precision.label, style: _textStyle),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
