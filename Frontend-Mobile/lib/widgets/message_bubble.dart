import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../providers/language_provider.dart';
import '../theme/colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageRole role;
  final String text;
  final DateTime? timestamp;
  final bool isError;

  const MessageBubble({
    super.key,
    required this.role,
    required this.text,
    this.timestamp,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == MessageRole.user;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp!)
        : DateFormat('HH:mm').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar "V" pour l'assistant Veyn
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsetsDirectional.only(end: 14, top: 2),
                  decoration: BoxDecoration(
                    color: VeynColors.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],

              // Conteneur de la bulle
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? VeynColors.ink
                        : (isError ? VeynColors.accentSoft : VeynColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: isError
                                ? VeynColors.accentBorder
                                : VeynColors.line,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isError) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.alertTriangle,
                              size: 13,
                              color: VeynColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('error_notice').split('.').first,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: VeynColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      _buildFormattedText(context, text, isUser),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Horodatage
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 36,
              right: isUser ? 4 : 0,
              top: 3,
            ),
            child: Text(
              timeStr,
              style: const TextStyle(
                fontSize: 10,
                color: VeynColors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rend le texte Markdown de l'assistant avec une vraie hiérarchie visuelle :
  /// # H1, ## H2, ### H3, **gras**, *italique*, - liste, 1. liste numérotée, ---
  Widget _buildFormattedText(
    BuildContext context,
    String rawText,
    bool isUser,
  ) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final isRtl = lang == 'ar';

    if (isUser) {
      return Text(
        rawText,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(
          fontSize: 14,
          height: 1.42,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final lines = rawText.split('\n');
    final List<Widget> blocks = [];
    bool prevWasContent = false;

    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final trimmed = raw.trim();

      // ── Ligne vide : espacement entre blocs ─────────────────────────────
      if (trimmed.isEmpty) {
        if (prevWasContent) blocks.add(const SizedBox(height: 6));
        prevWasContent = false;
        continue;
      }

      // ── Séparateur horizontal ---  ────────────────────────────────────
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: VeynColors.line),
        ));
        prevWasContent = false;
        continue;
      }

      // ── H1 : # Titre  ────────────────────────────────────────────────
      if (RegExp(r'^# (.+)$').hasMatch(trimmed)) {
        final content = trimmed.substring(2).trim();
        if (prevWasContent) blocks.add(const SizedBox(height: 10));
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Align(
            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            child: RichText(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: VeynColors.ink,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
                children: _parseInlineMarkdown(content),
              ),
            ),
          ),
        ));
        prevWasContent = true;
        continue;
      }

      // ── H2 : ## Titre  ──────────────────────────────────────────────
      if (RegExp(r'^## (.+)$').hasMatch(trimmed)) {
        final content = trimmed.substring(3).trim();
        if (prevWasContent) blocks.add(const SizedBox(height: 8));
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Align(
            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            child: RichText(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: VeynColors.ink,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
                children: _parseInlineMarkdown(content),
              ),
            ),
          ),
        ));
        prevWasContent = true;
        continue;
      }

      // ── H3 : ### Titre  ─────────────────────────────────────────────
      if (RegExp(r'^### (.+)$').hasMatch(trimmed)) {
        final content = trimmed.substring(4).trim();
        if (prevWasContent) blocks.add(const SizedBox(height: 6));
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Align(
            alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
            child: RichText(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: VeynColors.inkSoft,
                  height: 1.35,
                  letterSpacing: 0.1,
                ),
                children: _parseInlineMarkdown(content),
              ),
            ),
          ),
        ));
        prevWasContent = true;
        continue;
      }

      // ── Liste à puces : - item ou • item  ───────────────────────────
      final bulletMatch = RegExp(r'^[-•*]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final content = bulletMatch.group(1)!.trim();
        blocks.add(Padding(
          padding: EdgeInsets.only(
            left: isRtl ? 0 : 4,
            right: isRtl ? 4 : 0,
            top: 2,
            bottom: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Text(
                '•',
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 13,
                  color: VeynColors.accent,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      color: VeynColors.ink,
                    ),
                    children: _parseInlineMarkdown(content),
                  ),
                ),
              ),
            ],
          ),
        ));
        prevWasContent = true;
        continue;
      }

      // ── Liste numérotée : 1. item  ──────────────────────────────────
      final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(trimmed);
      if (numberedMatch != null) {
        final num = numberedMatch.group(1)!;
        final content = numberedMatch.group(2)!.trim();
        blocks.add(Padding(
          padding: EdgeInsets.only(
            left: isRtl ? 0 : 4,
            right: isRtl ? 4 : 0,
            top: 2,
            bottom: 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 20,
                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  '$num.',
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: VeynColors.accent,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.48,
                      color: VeynColors.ink,
                    ),
                    children: _parseInlineMarkdown(content),
                  ),
                ),
              ),
            ],
          ),
        ));
        prevWasContent = true;
        continue;
      }

      // ── Paragraphe ordinaire  ────────────────────────────────────────
      blocks.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Align(
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: RichText(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                height: 1.48,
                color: VeynColors.ink,
              ),
              children: _parseInlineMarkdown(trimmed),
            ),
          ),
        ),
      ));
      prevWasContent = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  /// Parse le Markdown inline : **gras**, *italique*, `code`
  List<InlineSpan> _parseInlineMarkdown(String text) {
    final List<InlineSpan> spans = [];
    // Ordre important : code en premier pour ne pas interférer avec les étoiles
    final pattern = RegExp(r'`([^`]+)`|\*\*(.+?)\*\*|\*(.+?)\*|__(.+?)__');
    int cursor = 0;

    for (final match in pattern.allMatches(text)) {
      // Texte avant le match
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      if (match.group(1) != null) {
        // `code` inline
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: VeynColors.surfaceSunken,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: VeynColors.line),
            ),
            child: Text(
              match.group(1)!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: VeynColors.accent,
              ),
            ),
          ),
        ));
      } else if (match.group(2) != null) {
        // **gras**
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.w700, color: VeynColors.ink),
        ));
      } else if (match.group(3) != null) {
        // *italique*
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(fontStyle: FontStyle.italic, color: VeynColors.inkSoft),
        ));
      } else if (match.group(4) != null) {
        // __gras alt__
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontWeight: FontWeight.w700, color: VeynColors.ink),
        ));
      }

      cursor = match.end;
    }

    // Reste du texte
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}

