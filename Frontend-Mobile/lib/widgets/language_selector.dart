import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/colors.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const List<Map<String, String>> languages = [
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français', 'desc': 'Français'},
    {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية', 'desc': 'العربية الفصحى'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English', 'desc': 'English'},
  ];

  void _showLanguageModal(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isRtl = languageProvider.isRtl;
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
          decoration: const BoxDecoration(
            color: VeynColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Langue / اللغة / Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: VeynColors.ink,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: VeynColors.inkMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                final isSelected = languageProvider.languageCode == lang['code'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? VeynColors.accent.withValues(alpha: 0.08) : VeynColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? VeynColors.accent : VeynColors.line,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Text(
                      lang['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? VeynColors.accent : VeynColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      lang['desc']!,
                      style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: VeynColors.accent)
                        : null,
                    onTap: () {
                      languageProvider.setLocale(Locale(lang['code']!));
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languages.firstWhere(
      (l) => l['code'] == languageProvider.languageCode,
      orElse: () => languages[0],
    );

    return InkWell(
      onTap: () => _showLanguageModal(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: VeynColors.surface,
          border: Border.all(color: VeynColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentLang['flag']!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              currentLang['name']!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: VeynColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
