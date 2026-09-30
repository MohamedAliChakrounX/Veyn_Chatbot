import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../models/trip.dart';
import '../providers/chat_provider.dart';
import '../providers/history_provider.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../data/locations.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_dialog.dart';
import '../widgets/chat_header.dart';
import '../widgets/composer.dart';
import '../widgets/conflict_card.dart';
import '../widgets/frozen_precisions_view.dart';
import '../widgets/history_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/result_card.dart';
import '../widgets/thread_states.dart';
import '../widgets/trip_dashboard.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.read<LanguageProvider>().languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().updateLanguage(lang);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Regroupe les trajets par combinaison de points d'arrêts (comme dans le frontend React)
  List<List<TripResult>> _groupTrips(List<TripResult> results) {
    final map = <String, List<TripResult>>{};
    for (final t in results) {
      String key = '${t.mode.name}::';
      if (t.stops.isNotEmpty) {
        key += t.stops.map((s) => s.name.trim().toLowerCase()).join(' > ');
      } else {
        key += '${t.operator}::${t.departure}::${t.arrival}';
      }
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final tripProvider = context.watch<TripProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final lang = languageProvider.languageCode;

    final messages = chatProvider.messages;
    final status = chatProvider.status;
    final isRtl = lang == 'ar';

    // Défilement automatique lors d'un nouveau message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: HistoryDrawer(
        onNewConversation: () => chatProvider.startNewConversation(tripProvider, lang),
      ),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              // En-tête mobile
              ChatHeader(
                onNewConversation: () => chatProvider.startNewConversation(tripProvider, lang),
                onOpenHistory: () => _scaffoldKey.currentState?.openEndDrawer(),
                historyCount: historyProvider.conversations.length,
              ),

              // Tableau de bord visuel interactif du trajet
              TripDashboard(
                onSearch: () {
                  final orig = tripProvider.trip.origin != null
                      ? localizeCityName(tripProvider.trip.origin!.name, lang)
                      : '';
                  final dest = tripProvider.trip.destination != null
                      ? localizeCityName(tripProvider.trip.destination!.name, lang)
                      : '';
                  final searchPrompt = lang == 'ar'
                      ? 'ابحث عن رحلات من $orig إلى $dest'
                      : lang == 'en'
                          ? 'Search trips from $orig to $dest'
                          : 'Recherche de trajets de $orig à $dest';
                  chatProvider.sendMessage(
                    searchPrompt,
                    tripProvider,
                    historyProvider,
                    language: lang,
                  );
                },
              ),

              // Fil de conversation
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length +
                      (status == ChatStatus.searching ? 1 : 0) +
                      (status == ChatStatus.thinking ? 1 : 0),
                itemBuilder: (context, index) {
                  // Éléments de fin de liste
                  if (index >= messages.length) {
                    if (status == ChatStatus.thinking) {
                      return const TypingIndicator();
                    }
                    if (status == ChatStatus.searching) {
                      return const ResultSkeletons();
                    }
                    return const SizedBox.shrink();
                  }

                  final msg = messages[index];

                  String bubbleText = msg.text;
                  if (msg.id == 'msg-welcome') {
                    bubbleText = context.tr('welcome_message');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bulle de message — masquée si le message assistant contient des cartes
                      // (les cartes suffisent comme réponse, le texte répèterait les mêmes infos)
                      if (msg.booking == null &&
                          !(msg.role == MessageRole.assistant &&
                            msg.results != null &&
                            msg.results!.isNotEmpty))
                        MessageBubble(
                          role: msg.role,
                          text: bubbleText,
                          timestamp: msg.timestamp,
                          isError: msg.isError,
                        ),


                      // Résolution de conflit
                      if (msg.conflict != null)
                        ConflictCard(
                          conflict: msg.conflict!,
                          onResolve: (useProposed) => chatProvider.resolveConflict(
                            msg.id,
                            msg.conflict!,
                            useProposed,
                            tripProvider,
                            historyProvider,
                          ),
                        ),


                      // Aucun résultat
                      if (msg.noResults)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: NoResultsActions(
                            onPick: (val) => chatProvider.sendMessage(
                              val,
                              tripProvider,
                              historyProvider,
                              language: lang,
                            ),
                          ),
                        ),

                      // Notification d'erreur
                      if (msg.isError)
                        ErrorNotice(
                          onRetry: () => chatProvider.retry(tripProvider, historyProvider),
                        ),

                      // Carte de réservation confirmée
                      if (msg.booking != null)
                        BookingCard(booking: msg.booking!),

                      // Cartes de trajets — précisions affichées juste avant
                      if (msg.results != null && msg.results!.isNotEmpty) ...[
                        Builder(builder: (ctx) {
                          // Résolution des précisions à afficher avant les cartes :
                          // Priorité 1 : précisions stockées dans le message assistant lui-même
                          //              (calculées par chat_provider depuis NLU + dashboard)
                          // Priorité 2 : précisions du message utilisateur précédent (dashboard seul)
                          List<TripPrecisionItem> precisions = [];

                          if (msg.precisions != null && msg.precisions!.isNotEmpty) {
                            precisions = msg.precisions!;
                          } else if (index > 0 &&
                              messages[index - 1].role == MessageRole.user &&
                              messages[index - 1].precisions != null &&
                              messages[index - 1].precisions!.isNotEmpty) {
                            precisions = messages[index - 1].precisions!;
                          }

                          return precisions.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: FrozenPrecisionsView(
                                    precisions: precisions,
                                    isRtl: isRtl,
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                        const SizedBox(height: 2),
                        ..._groupTrips(msg.results!).map((tripGroup) {
                          final isFirst = tripGroup == _groupTrips(msg.results!).first;
                          return ResultCard(
                            trips: tripGroup,
                            featured: isFirst,
                            onBook: (selectedTrip) {
                              BookingDialog.show(
                                context,
                                result: selectedTrip,
                                onConfirm: (summary) => chatProvider.confirmBooking(
                                  summary,
                                  tripProvider,
                                  historyProvider,
                                  language: lang,
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 6),
                      ],
                    ],
                  );
                },
              ),
            ),

            // Barre de saisie inférieure (Composer)
            Composer(
              busy: status != ChatStatus.idle,
              onSend: (text) => chatProvider.sendMessage(
                text,
                tripProvider,
                historyProvider,
                language: lang,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

