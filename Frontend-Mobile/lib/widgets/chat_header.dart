import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/translations.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import 'language_selector.dart';

class ChatHeader extends StatefulWidget {
  final VoidCallback onNewConversation;
  final VoidCallback onOpenHistory;
  final int historyCount;

  const ChatHeader({
    super.key,
    required this.onNewConversation,
    required this.onOpenHistory,
    required this.historyCount,
  });

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader> {
  final ApiService _apiService = ApiService();
  bool _serverOnline = true;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final ok = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _serverOnline = ok;
      });
    }
  }

  void _showServerSettings(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    final isRtl = context.isRtl;
    bool isChecking = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: VeynColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(LucideIcons.server, color: VeynColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('server_config'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('api_url_label'),
                    style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'http://127.0.0.1:8000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VeynColors.line),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // Boutons de présélection rapide
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      ActionChip(
                        label: const Text('USB / ADB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                        backgroundColor: VeynColors.surfaceSunken,
                        side: const BorderSide(color: VeynColors.line),
                        onPressed: () => setDialogState(() => controller.text = 'http://127.0.0.1:8000'),
                      ),
                      ActionChip(
                        label: const Text('Wi-Fi (192.168.100.6)', style: TextStyle(fontSize: 11)),
                        backgroundColor: VeynColors.surfaceSunken,
                        side: const BorderSide(color: VeynColors.line),
                        onPressed: () => setDialogState(() => controller.text = 'http://192.168.100.6:8000'),
                      ),
                      ActionChip(
                        label: const Text('Émulateur (10.0.2.2)', style: TextStyle(fontSize: 11)),
                        backgroundColor: VeynColors.surfaceSunken,
                        side: const BorderSide(color: VeynColors.line),
                        onPressed: () => setDialogState(() => controller.text = 'http://10.0.2.2:8000'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bouton Tester la connexion
                  OutlinedButton.icon(
                    onPressed: isChecking
                        ? null
                        : () async {
                            setDialogState(() {
                              isChecking = true;
                              testResult = null;
                            });
                            final ok = await _apiService.checkHealth(controller.text);
                            setDialogState(() {
                              isChecking = false;
                              testSuccess = ok;
                              testResult = ok
                                  ? (isRtl ? 'تم الاتصال بالخادم بنجاح' : 'Serveur en ligne (200 OK)')
                                  : (isRtl ? 'تعذر الاتصال بالخادم' : 'Impossible de joindre le serveur');
                            });
                            _checkServer();
                          },
                    icon: isChecking
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.activity, size: 14),
                    label: Text(
                      isRtl ? 'اختبار الاتصال' : 'Tester la connexion',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: VeynColors.line),
                    ),
                  ),

                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: testSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        testResult!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(context.tr('cancel'), style: const TextStyle(color: VeynColors.inkMuted)),
              ),
              ElevatedButton(
                onPressed: () {
                  ApiService.baseUrl = controller.text;
                  _checkServer();
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${context.tr('server_set')} ${ApiService.baseUrl}'),
                      backgroundColor: VeynColors.ink,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VeynColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(context.tr('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;

    return Container(
      decoration: const BoxDecoration(
        color: VeynColors.surface,
        border: Border(bottom: BorderSide(color: VeynColors.line)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Logo Veyn officiel
              InkWell(
                onTap: widget.onNewConversation,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://cdn.magicpatterns.com/uploads/9bXDdrgnnoL9KwUVE4fnE3/logo_veyn.png',
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Text(
                            'veyn .',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: VeynColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Pastille Statut / Config Serveur
              InkWell(
                onTap: () => _showServerSettings(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: VeynColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VeynColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _serverOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.server, size: 13, color: VeynColors.inkMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Sélecteur de langue compact
              const LanguageSelector(),

              const SizedBox(width: 6),

              // Bouton Nouvelle Recherche (icône épurée)
              IconButton(
                onPressed: widget.onNewConversation,
                tooltip: context.tr('new_search'),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: VeynColors.surfaceSunken,
                  padding: const EdgeInsets.all(6),
                  side: const BorderSide(color: VeynColors.line),
                ),
                icon: const Icon(LucideIcons.plus, size: 16, color: VeynColors.inkSoft),
              ),

              const SizedBox(width: 6),

              // Bouton Historique (avec badge numérique si > 0)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onOpenHistory,
                    tooltip: context.tr('history'),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: VeynColors.surfaceSunken,
                      padding: const EdgeInsets.all(6),
                      side: const BorderSide(color: VeynColors.line),
                    ),
                    icon: const Icon(LucideIcons.history, size: 16, color: VeynColors.inkSoft),
                  ),
                  if (widget.historyCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VeynColors.surface, width: 1.2),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${widget.historyCount}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Sous-titre discret
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.tr('subtitle'),
              style: const TextStyle(
                fontSize: 10,
                color: VeynColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
